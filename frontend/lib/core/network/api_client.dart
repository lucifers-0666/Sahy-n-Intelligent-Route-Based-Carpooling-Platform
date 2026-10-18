import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sahyan/core/network/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final String? suspensionReason;
  final String? suspendedAt;

  ApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.suspensionReason,
    this.suspendedAt,
  });

  @override
  String toString() => message;
}

class ApiClient {
  String baseUrl;
  final http.Client _client;
  String? _authToken;
  void Function()? onUnauthorized;
  void Function(String reason, String? suspendedAt)? onAccountSuspended;
  Future<String?> Function()? tokenRefresher;
  Future<String?>? _activeRefreshOperation;
  static String? _resolvedBaseUrl;

  ApiClient({
    String? baseUrl,
    http.Client? client,
    this.onUnauthorized,
    this.onAccountSuspended,
    this.tokenRefresher,
  }) : baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
       _client = client ?? http.Client();

  /// Probes candidate hosts concurrently on Android to establish the fastest working connection
  Future<String> _resolveEffectiveBaseUrl() async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      _resolvedBaseUrl = envUrl;
      return envUrl;
    }

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _resolvedBaseUrl = ApiConfig.defaultBaseUrl;
      return _resolvedBaseUrl!;
    }

    try {
      final futures = ApiConfig.candidateHosts.map((candidate) async {
        try {
          final pingUri = Uri.parse(
            candidate.replaceAll('/api/v1', ApiConfig.healthEndpoint),
          );
          final res = await _client
              .get(pingUri)
              .timeout(const Duration(milliseconds: 1200));
          if (res.statusCode >= 200 && res.statusCode < 400) {
            return candidate;
          }
        } catch (_) {}
        return null;
      });

      final results = await Future.wait(futures);
      for (final res in results) {
        if (res != null) {
          _resolvedBaseUrl = res;
          baseUrl = res;
          ApiConfig.setCustomBaseUrl(res);
          return res;
        }
      }
    } catch (_) {}

    _resolvedBaseUrl = ApiConfig.candidateHosts.first;
    return _resolvedBaseUrl!;
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  bool _isAuthEntryEndpoint(String endpoint) {
    final clean = endpoint.toLowerCase().split('?').first;
    return clean == '/auth/login' ||
        clean == '/auth/register' ||
        clean == '/auth/send-otp' ||
        clean == '/auth/verify-otp' ||
        clean == '/auth/forgot-password' ||
        clean == '/auth/reset-password' ||
        clean == '/auth/logout';
  }

  Future<dynamic> get(String endpoint) => _executeRequest('GET', endpoint);

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) =>
      _executeRequest('POST', endpoint, body: body);

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) =>
      _executeRequest('PUT', endpoint, body: body);

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) =>
      _executeRequest('PATCH', endpoint, body: body);

  Future<dynamic> delete(String endpoint) =>
      _executeRequest('DELETE', endpoint);

  Future<dynamic> _executeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    try {
      final activeBase = await _resolveEffectiveBaseUrl();
      final uri = Uri.parse('$activeBase$endpoint');
      final encodedBody = body != null ? jsonEncode(body) : null;

      final http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 7));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: _headers, body: encodedBody)
              .timeout(const Duration(seconds: 7));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: _headers, body: encodedBody)
              .timeout(const Duration(seconds: 7));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: _headers, body: encodedBody)
              .timeout(const Duration(seconds: 7));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: _headers)
              .timeout(const Duration(seconds: 7));
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      // Check if 401 is eligible for token refresh
      if (response.statusCode == 401 &&
          !isRetry &&
          tokenRefresher != null &&
          _authToken != null &&
          _authToken!.isNotEmpty &&
          !_isAuthEntryEndpoint(endpoint)) {
        // Prevent concurrent requests from triggering repeated refresh operations
        _activeRefreshOperation ??= () async {
          try {
            final newToken = await tokenRefresher!();
            if (newToken != null && newToken.isNotEmpty) {
              setAuthToken(newToken);
              return newToken;
            }
            return null;
          } catch (_) {
            return null;
          } finally {
            _activeRefreshOperation = null;
          }
        }();

        final refreshedToken = await _activeRefreshOperation;
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          // Attempt at most one retry with the refreshed token
          return await _executeRequest(
            method,
            endpoint,
            body: body,
            isRetry: true,
          );
        } else {
          // Refresh failed: clear invalid session, notify unauthorized, and handle error
          setAuthToken(null);
          onUnauthorized?.call();
          return _processResponse(response, skipUnauthorizedCallback: true);
        }
      }

      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _processResponse(
    http.Response response, {
    bool skipUnauthorizedCallback = false,
  }) {
    dynamic jsonResponseBody;
    try {
      jsonResponseBody = jsonDecode(response.body);
    } catch (_) {
      jsonResponseBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonResponseBody;
    }

    if (response.statusCode == 401 && !skipUnauthorizedCallback) {
      onUnauthorized?.call();
    }

    final errorCode =
        jsonResponseBody is Map && jsonResponseBody.containsKey('errorCode')
        ? jsonResponseBody['errorCode'] as String?
        : null;
    final suspensionReason =
        jsonResponseBody is Map &&
            jsonResponseBody.containsKey('suspensionReason')
        ? jsonResponseBody['suspensionReason'] as String?
        : null;
    final suspendedAt =
        jsonResponseBody is Map && jsonResponseBody.containsKey('suspendedAt')
        ? jsonResponseBody['suspendedAt']?.toString()
        : null;

    if (response.statusCode == 403 && errorCode == 'ACCOUNT_SUSPENDED') {
      onAccountSuspended?.call(
        suspensionReason ?? 'Account suspended by administrator.',
        suspendedAt,
      );
    }

    final message =
        jsonResponseBody is Map && jsonResponseBody.containsKey('message')
        ? jsonResponseBody['message']
        : 'Request failed with status ${response.statusCode}';

    throw ApiException(
      message,
      statusCode: response.statusCode,
      errorCode: errorCode,
      suspensionReason: suspensionReason,
      suspendedAt: suspendedAt,
    );
  }

  Exception _handleError(dynamic error) {
    _resolvedBaseUrl = null;
    if (error is ApiException) return error;
    if (error is TimeoutException) {
      return ApiException(
        'Connection timed out. Please verify the backend server is running and port 5000 is forwarded.',
      );
    }
    if (error is SocketException) {
      return ApiException(
        'Cannot connect to backend server. Run "adb reverse tcp:5000 tcp:5000" or connect to the same Wi-Fi.',
      );
    }
    return ApiException(error.toString());
  }
}
