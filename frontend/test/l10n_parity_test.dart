import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('L10n ARB Parity Tests', () {
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> guJson;
    late Map<String, dynamic> hiJson;

    setUpAll(() {
      final enFile = File('lib/l10n/app_en.arb');
      final guFile = File('lib/l10n/app_gu.arb');
      final hiFile = File('lib/l10n/app_hi.arb');

      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(guFile.existsSync(), isTrue, reason: 'app_gu.arb must exist');
      expect(hiFile.existsSync(), isTrue, reason: 'app_hi.arb must exist');

      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      guJson = jsonDecode(guFile.readAsStringSync()) as Map<String, dynamic>;
      hiJson = jsonDecode(hiFile.readAsStringSync()) as Map<String, dynamic>;
    });

    List<String> extractKeys(Map<String, dynamic> json) {
      return json.keys
          .where((k) => !k.startsWith('@'))
          .toList()
        ..sort();
    }

    Set<String> extractPlaceholders(String text) {
      final regExp = RegExp(r'\{([a-zA-Z0-9_]+)');
      return regExp.allMatches(text).map((m) => m.group(1)!).toSet();
    }

    test('All non-metadata keys in app_en.arb are present in app_gu.arb', () {
      final enKeys = extractKeys(enJson);
      final guKeys = extractKeys(guJson);

      final missingInGu = enKeys.where((k) => !guKeys.contains(k)).toList();
      expect(
        missingInGu,
        isEmpty,
        reason: 'Keys present in English but missing in Gujarati: $missingInGu',
      );
    });

    test('All non-metadata keys in app_en.arb are present in app_hi.arb', () {
      final enKeys = extractKeys(enJson);
      final hiKeys = extractKeys(hiJson);

      final missingInHi = enKeys.where((k) => !hiKeys.contains(k)).toList();
      expect(
        missingInHi,
        reason: 'Keys present in English but missing in Hindi: $missingInHi',
        isEmpty,
      );
    });

    test('No superfluous keys in app_gu.arb that do not exist in app_en.arb', () {
      final enKeys = extractKeys(enJson);
      final guKeys = extractKeys(guJson);

      final extraInGu = guKeys.where((k) => !enKeys.contains(k)).toList();
      expect(
        extraInGu,
        isEmpty,
        reason: 'Keys in Gujarati but not in English source of truth: $extraInGu',
      );
    });

    test('No superfluous keys in app_hi.arb that do not exist in app_en.arb', () {
      final enKeys = extractKeys(enJson);
      final hiKeys = extractKeys(hiJson);

      final extraInHi = hiKeys.where((k) => !enKeys.contains(k)).toList();
      expect(
        extraInHi,
        isEmpty,
        reason: 'Keys in Hindi but not in English source of truth: $extraInHi',
      );
    });

    test('Placeholders match exactly between English and Gujarati', () {
      final enKeys = extractKeys(enJson);
      for (final key in enKeys) {
        final enVal = enJson[key] as String;
        final guVal = guJson[key] as String;

        final enPlaceholders = extractPlaceholders(enVal);
        final guPlaceholders = extractPlaceholders(guVal);

        expect(
          guPlaceholders,
          equals(enPlaceholders),
          reason: 'Placeholder mismatch for key "$key": EN=$enPlaceholders vs GU=$guPlaceholders',
        );
      }
    });

    test('Placeholders match exactly between English and Hindi', () {
      final enKeys = extractKeys(enJson);
      for (final key in enKeys) {
        final enVal = enJson[key] as String;
        final hiVal = hiJson[key] as String;

        final enPlaceholders = extractPlaceholders(enVal);
        final hiPlaceholders = extractPlaceholders(hiVal);

        expect(
          hiPlaceholders,
          equals(enPlaceholders),
          reason: 'Placeholder mismatch for key "$key": EN=$enPlaceholders vs HI=$hiPlaceholders',
        );
      }
    });

    test('No non-Western digits in Gujarati or Hindi strings', () {
      final nonWesternDigits = RegExp(r'[૦-૯०-९]');
      for (final entry in guJson.entries) {
        if (entry.key.startsWith('@')) continue;
        final val = entry.value.toString();
        expect(
          nonWesternDigits.hasMatch(val),
          isFalse,
          reason: 'Gujarati string for "${entry.key}" contains non-Western digits: "$val"',
        );
      }
      for (final entry in hiJson.entries) {
        if (entry.key.startsWith('@')) continue;
        final val = entry.value.toString();
        expect(
          nonWesternDigits.hasMatch(val),
          isFalse,
          reason: 'Hindi string for "${entry.key}" contains non-Western digits: "$val"',
        );
      }
    });
  });
}
