import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sahyan/core/network/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  String baseUrl;
  final http.Client _client;
  String? _authToken;
  static String? _resolvedBaseUrl;

  ApiClient({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
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

  Future<dynamic> get(String endpoint) async {
    try {
      final activeBase = await _resolveEffectiveBaseUrl();
      final response = await _client
          .get(Uri.parse('$activeBase$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 7));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final activeBase = await _resolveEffectiveBaseUrl();
      final response = await _client
          .post(
            Uri.parse('$activeBase$endpoint'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 7));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final activeBase = await _resolveEffectiveBaseUrl();
      final response = await _client
          .put(
            Uri.parse('$activeBase$endpoint'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 7));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final activeBase = await _resolveEffectiveBaseUrl();
      final response = await _client
          .patch(
            Uri.parse('$activeBase$endpoint'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 7));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final activeBase = await _resolveEffectiveBaseUrl();
      final response = await _client
          .delete(Uri.parse('$activeBase$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 7));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonResponseBody;
    try {
      jsonResponseBody = jsonDecode(response.body);
    } catch (_) {
      jsonResponseBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonResponseBody;
    }

    final message =
        jsonResponseBody is Map && jsonResponseBody.containsKey('message')
        ? jsonResponseBody['message']
        : 'Request failed with status ${response.statusCode}';

    throw ApiException(message, statusCode: response.statusCode);
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
