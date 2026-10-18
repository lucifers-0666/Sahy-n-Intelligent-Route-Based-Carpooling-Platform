import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sahyan/core/network/api_client.dart';

void main() {
  group('ApiClient Token Expiry, Refresh & Deduplicated Retry Tests', () {
    test('Successful refresh retries request once and returns 200 payload', () async {
      int requestCount = 0;
      int refreshCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        final authHeader = request.headers['Authorization'];

        if (authHeader == 'Bearer initial_expired_token') {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Token expired'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }

        if (authHeader == 'Bearer fresh_refreshed_token') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'user_123', 'name': 'Verified Commuter'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Unauthorized', 401);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
      );
      client.setAuthToken('initial_expired_token');
      client.tokenRefresher = () async {
        refreshCount++;
        return 'fresh_refreshed_token';
      };

      final result = await client.get('/users/profile');

      expect(result, isNotNull);
      expect(result['data']['name'], 'Verified Commuter');
      expect(refreshCount, 1);
      expect(requestCount, 2);
    });

    test('Failed refresh clears token, invokes onUnauthorized, and throws ApiException', () async {
      bool unauthorizedInvoked = false;
      int refreshCount = 0;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Invalid token'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
        onUnauthorized: () {
          unauthorizedInvoked = true;
        },
      );
      client.setAuthToken('expired_token');
      client.tokenRefresher = () async {
        refreshCount++;
        return null; // Refresh failed
      };

      expect(
        () => client.get('/users/profile'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(refreshCount, 1);
      expect(unauthorizedInvoked, isTrue);
    });

    test('Concurrent requests trigger exactly ONE refresh operation and all retry successfully', () async {
      int refreshCallCount = 0;
      final Set<String> requestedEndpoints = {};

      final mockClient = MockClient((request) async {
        final authHeader = request.headers['Authorization'];
        requestedEndpoints.add(request.url.path);

        if (authHeader == 'Bearer stale_token') {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Token expired'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }

        if (authHeader == 'Bearer unified_fresh_token') {
          return http.Response(
            jsonEncode({'success': true, 'path': request.url.path}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Forbidden', 403);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
      );
      client.setAuthToken('stale_token');
      client.tokenRefresher = () async {
        refreshCallCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'unified_fresh_token';
      };

      // Dispatch 3 concurrent requests simultaneously
      final results = await Future.wait([
        client.get('/users/profile'),
        client.get('/vehicles'),
        client.get('/rides/my'),
      ]);

      expect(results.length, 3);
      expect(results[0]['success'], isTrue);
      expect(results[1]['success'], isTrue);
      expect(results[2]['success'], isTrue);
      // Critical invariant: exactly one refresh call was dispatched
      expect(refreshCallCount, 1);
    });

    test('Retry limit: retried request returning 401 throws without infinite looping', () async {
      int requestCount = 0;
      int refreshCount = 0;
      bool onUnauthorizedCalled = false;

      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({'success': false, 'message': 'Still unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
        onUnauthorized: () {
          onUnauthorizedCalled = true;
        },
      );
      client.setAuthToken('initial_token');
      client.tokenRefresher = () async {
        refreshCount++;
        return 'new_token_that_also_fails';
      };

      await expectLater(
        () => client.get('/users/profile'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      // Must attempt only 1 refresh and 1 retry (total 2 requests)
      expect(refreshCount, 1);
      expect(requestCount, 2);
      expect(onUnauthorizedCalled, isTrue);
    });

    test('403 Forbidden is NOT treated as token expiry and does not trigger refresh', () async {
      int refreshCount = 0;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Access denied: Admin role required'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
      );
      client.setAuthToken('valid_passenger_token');
      client.tokenRefresher = () async {
        refreshCount++;
        return 'refreshed_token';
      };

      await expectLater(
        () => client.get('/admin/config'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );

      expect(refreshCount, 0);
    });

    test('Excluded auth endpoints (/auth/login) never trigger token refresh on 401', () async {
      int refreshCount = 0;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Invalid email or password'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
      );
      client.setAuthToken('existing_token');
      client.tokenRefresher = () async {
        refreshCount++;
        return 'should_not_be_called';
      };

      await expectLater(
        () => client.post('/auth/login', body: {'identifier': 'a@b.com', 'password': 'Wrong'}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(refreshCount, 0);
    });

    test('Legacy session without tokenRefresher preserves graceful 401 handling', () async {
      bool unauthorizedCalled = false;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'JWT expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
      );
      client.setAuthToken('legacy_jwt_token');

      await expectLater(
        () => client.get('/users/profile'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(unauthorizedCalled, isTrue);
    });
  });
}
