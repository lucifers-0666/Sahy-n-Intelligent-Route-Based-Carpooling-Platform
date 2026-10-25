import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Supported languages in Sahyān
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
  AppLocaleNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences? _prefs;
  static const _key = 'app_locale';

  static Locale _initial(SharedPreferences? p) {
    final saved = p?.getString(_key);
    if (saved != null && ['en', 'gu', 'hi'].contains(saved)) {
      return Locale(saved);
    }
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(['en', 'gu', 'hi'].contains(device) ? device : 'en');
  }

  Future<void> setLocale(Locale l) async {
    state = l;
    await _prefs?.setString(_key, l.languageCode);
  }

  Future<void> setLanguage(SahyanLanguage language) =>
      setLocale(language.locale);
}

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>(
  (ref) => AppLocaleNotifier(ref.watch(sharedPreferencesProvider)),
);
