import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Supported locales in Sahyān
enum SahyanLanguage {
  english('en', 'English', 'English'),
  gujarati('gu', 'ગુજરાતી', 'Gujarati'),
  hindi('hi', 'हिन्दी', 'Hindi');

  final String code;
  final String nativeName;
  final String englishName;

  const SahyanLanguage(this.code, this.nativeName, this.englishName);

  Locale get locale => Locale(code);

  static SahyanLanguage fromCode(String code) {
    for (final lang in SahyanLanguage.values) {
      if (lang.code == code) return lang;
    }
    return SahyanLanguage.english;
  }
}

class AppLocaleNotifier extends StateNotifier<Locale> {
  static const String _prefKey = 'sahyan_app_language_code';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppLocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final code = await _storage.read(key: _prefKey);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
      }
    } catch (_) {}
  }

  Future<void> setLanguage(SahyanLanguage language) async {
    state = language.locale;
    try {
      await _storage.write(key: _prefKey, value: language.code);
    } catch (_) {}
  }
}

final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  return AppLocaleNotifier();
});
