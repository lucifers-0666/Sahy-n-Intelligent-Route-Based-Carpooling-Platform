// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get welcomeHeadline => 'મુસાફરી વહેંચો,\nમાત્ર રાઇડ નહીં.';

  @override
  String get welcomeSubline =>
      'ભારતભરના રૂટ પર પ્રમાણિત સહમુસાફરો અને ડ્રાઇવરો શોધો.';

  @override
  String get registerIntro => 'ભારતના પ્રમાણિત કારપૂલિંગ સમુદાયમાં જોડાઓ.';

  @override
  String get otpIncompleteError => 'ચકાસવા માટે બધા ૬ અંક દાખલ કરો.';

  @override
  String get fullNameLabel => 'પૂરું નામ';

  @override
  String get fullNameHelper => 'તમારા ઓળખપત્ર મુજબ';

  @override
  String get termsConsentPrefix => 'આગળ વધીને તમે સંમત થાઓ છો ';

  @override
  String get termsAndPrivacy => 'નિયમો અને ગોપનીયતા નીતિ';
}
