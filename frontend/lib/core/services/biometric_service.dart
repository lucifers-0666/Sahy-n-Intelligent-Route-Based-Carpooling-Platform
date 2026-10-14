import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  static const String _keyBiometricOptIn = 'sahyan_biometric_opt_in';
  static const String _keyAppLockMode = 'sahyan_app_lock_mode';
  static const String _keyDeviceId = 'sahyan_device_id';

  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  /// Check if device supports hardware biometrics (fingerprint / face ID)
  Future<bool> canAuthenticate() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Trigger native hardware biometrics prompt (fingerprint or face ID)
  Future<bool> authenticate({
    String localizedReason =
        'Scan fingerprint or face to authenticate instantly',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> setBiometricOptIn(bool enabled) async {
    await _storage.write(
      key: _keyBiometricOptIn,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> hasBiometricOptIn() async {
    final val = await _storage.read(key: _keyBiometricOptIn);
    return val == 'true';
  }

  Future<void> setAppLockMode(String mode) async {
    await _storage.write(key: _keyAppLockMode, value: mode);
  }

  Future<String> getAppLockMode() async {
    return (await _storage.read(key: _keyAppLockMode)) ?? 'off';
  }

  Future<String> getOrCreateDeviceId() async {
    var devId = await _storage.read(key: _keyDeviceId);
    if (devId == null || devId.isEmpty) {
      devId = 'sahyan_dev_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: _keyDeviceId, value: devId);
    }
    return devId;
  }

  Future<void> clearOptIn() async {
    await _storage.delete(key: _keyBiometricOptIn);
  }
}
