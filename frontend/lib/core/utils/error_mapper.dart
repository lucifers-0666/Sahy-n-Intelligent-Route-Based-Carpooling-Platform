import 'package:flutter/foundation.dart';

/// Centralized ErrorMapper for Sahyān.
///
/// Translates low-level network, database, platform, and Firebase exceptions
/// into concise, human-friendly feedback copy for UI toasts.
/// All technical details and stack traces are logged exclusively to [debugPrint].
class ErrorMapper {
  /// Maps any raw error or exception into a clear, short user message.
  static String map(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again.';

    final raw = error.toString();
    debugPrint('[Sahyān Technical Error]: $raw');

    // 1. Connectivity & Network
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection refused') ||
        raw.contains('Network is unreachable') ||
        raw.contains('network_error') ||
        raw.contains('ApiException: 7')) {
      return 'No internet connection. Please check your network.';
    }

    // 2. Timeout
    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }

    // 3. Google Sign-In & Firebase Configuration
    if (raw.contains('ApiException: 10') ||
        raw.contains('ApiException: 12500') ||
        raw.contains('DEVELOPER_ERROR') ||
        raw.contains('not configured')) {
      return 'Google Sign-In is unavailable. Please use Phone OTP or Password.';
    }

    // 4. SMS & OTP Rate Limits
    if (raw.contains('429') || raw.contains('Too many OTP requests')) {
      return 'Too many attempts. Please wait a minute before retrying.';
    }

    if (raw.contains('Invalid OTP') || raw.contains('invalid code')) {
      return 'Incorrect verification code. Please check and re-enter.';
    }

    if (raw.contains('expired')) {
      return 'Verification code has expired. Please request a new one.';
    }

    // 5. Account and Credentials
    if (raw.contains('Invalid credentials') ||
        raw.contains('401') ||
        raw.contains('wrong-password') ||
        raw.contains('user-not-found')) {
      return 'Incorrect mobile number or password.';
    }

    if (raw.contains('ACCOUNT_SUSPENDED')) {
      return 'Your account is suspended. Please contact support.';
    }

    if (raw.contains('already exists')) {
      return 'An account with this number or email already exists.';
    }

    // 6. Phone validation
    if (raw.contains('valid 10-digit')) {
      return 'Please enter a valid 10-digit Indian mobile number.';
    }

    // Clean prefix like 'Exception: ' or 'ApiException: '
    String cleaned = raw;
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length);
    }
    if (cleaned.startsWith('ApiException: ')) {
      cleaned = cleaned.substring('ApiException: '.length);
    }

    // Ensure message is concise (max 80 chars)
    if (cleaned.length > 80) {
      cleaned = '${cleaned.substring(0, 77)}...';
    }

    return cleaned.isNotEmpty ? cleaned : 'An error occurred. Please try again.';
  }
}
