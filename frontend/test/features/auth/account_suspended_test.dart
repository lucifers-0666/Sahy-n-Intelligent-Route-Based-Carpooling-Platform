import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/presentation/screens/account_suspended_screen.dart';
import 'package:sahyan/shared/models/user_model.dart';

class MockSecureStorageService implements SecureStorageService {
  String? _token;
  UserModel? _user;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<void> saveUser(UserModel user) async => _user = user;

  @override
  Future<UserModel?> getUser() async => _user;

  @override
  Future<void> deleteUser() async => _user = null;

  @override
  Future<void> clearSession() async {
    _token = null;
    _user = null;
  }

  bool _completedOnboarding = false;

  @override
  Future<void> setCompletedOnboarding(bool completed) async =>
      _completedOnboarding = completed;

  @override
  Future<bool> hasCompletedOnboarding() async => _completedOnboarding;
}

void main() {
  group('AccountSuspendedScreen Widget Tests', () {
    testWidgets('Renders Minimal Brutalism layout with reason and timestamp', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountSuspendedScreen(
              reason: 'Repeated non-compliance with passenger safety guidelines during route transit.',
              suspendedAt: '2026-10-10T12:00:00.000Z',
            ),
          ),
        ),
      );

      // Verify header and headline
      expect(find.text('ACCESS RESTRICTED'), findsOneWidget);
      expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);

      // Verify reason display
      expect(
        find.text(
          'Repeated non-compliance with passenger safety guidelines during route transit.',
        ),
        findsOneWidget,
      );

      // Verify timestamp
      expect(find.text('RECORDED TIMESTAMP'), findsOneWidget);

      // Verify action buttons
      expect(find.text('SIGN OUT & RETURN TO LOGIN'), findsOneWidget);
      expect(find.text('VIEW HELP & SUPPORT'), findsOneWidget);
      expect(find.text('ENFORCEMENT NOTICE'), findsOneWidget);
    });

    testWidgets('Zero emoji prohibition check on AccountSuspendedScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountSuspendedScreen(
              reason: 'Policy violation',
            ),
          ),
        ),
      );

      // Emoji regex
      final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        final data = text.data ?? '';
        expect(
          emojiRegex.hasMatch(data),
          isFalse,
          reason: 'Text "$data" should not contain emojis',
        );
      }
    });
  });

  group('Suspension API & AuthNotifier State Transitions', () {
    test('ApiClient invokes onAccountSuspended callback when 403 ACCOUNT_SUSPENDED occurs', () async {
      String? capturedReason;
      String? capturedTimestamp;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'errorCode': 'ACCOUNT_SUSPENDED',
            'message': 'Account has been suspended by administration.',
            'suspensionReason': 'Driver license expired.',
            'suspendedAt': '2026-10-10T10:00:00Z',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
        onAccountSuspended: (reason, timestamp) {
          capturedReason = reason;
          capturedTimestamp = timestamp;
        },
      );

      await expectLater(
        () => apiClient.get('/auth/me'),
        throwsA(isA<ApiException>()),
      );

      expect(capturedReason, 'Driver license expired.');
      expect(capturedTimestamp, '2026-10-10T10:00:00Z');
    });

    test('AuthNotifier transitions to AuthStatus.suspended upon handleSuspension', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'errorCode': 'ACCOUNT_SUSPENDED',
            'message': 'Account is suspended.',
            'suspensionReason': 'Safety complaint investigation.',
            'suspendedAt': '2026-10-10T11:00:00Z',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        client: mockClient,
      );
      final storage = MockSecureStorageService();
      final repo = AuthRepositoryImpl(apiClient: apiClient, storageService: storage);

      final notifier = AuthNotifier(
        repository: repo,
        storageService: storage,
        apiClient: apiClient,
      );

      await notifier.handleSuspension(
        'Safety complaint investigation.',
        '2026-10-10T11:00:00Z',
      );

      expect(notifier.state.status, AuthStatus.suspended);
      expect(notifier.state.isSuspended, isTrue);
      expect(notifier.state.suspensionReason, 'Safety complaint investigation.');
      expect(notifier.state.suspendedAt, '2026-10-10T11:00:00Z');
    });
  });
}
