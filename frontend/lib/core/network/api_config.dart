import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized API configuration for Sahyān.
/// Supports USB physical-device development via ADB reverse,
/// emulator fallback, and compile-time environment configuration for production.
class ApiConfig {
  /// Compile-time environment variable override:
  /// flutter run --dart-define=API_BASE_URL=https://api.sahyan.app/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Local development port
  static const int port = 5000;

  /// Primary USB Development URL (compatible with: adb reverse tcp:5000 tcp:5000)
  static const String localAdbReverseUrl = 'http://127.0.0.1:$port/api/v1';

  /// Localhost URL
  static const String localhostUrl = 'http://localhost:$port/api/v1';

  /// Android Emulator Loopback URL
  static const String emulatorUrl = 'http://10.0.2.2:$port/api/v1';

  /// Health check path
  static const String healthEndpoint = '/api/health';

  /// Active base URL
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return localhostUrl;
    }
    return localAdbReverseUrl;
  }

  /// Ordered candidate hosts probed on Android devices during local development
  static List<String> get candidateHosts => [
    localAdbReverseUrl,
    localhostUrl,
    emulatorUrl,
  ];
}
