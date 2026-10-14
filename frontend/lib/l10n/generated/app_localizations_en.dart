// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeHeadline => 'Share the journey,\nnot just the ride.';

  @override
  String get welcomeSubline =>
      'Find verified riders and drivers for routes across India.';

  @override
  String get registerIntro => 'Join India\'s verified carpooling community.';

  @override
  String get otpIncompleteError => 'Enter all 6 digits to verify.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHelper => 'As on your ID';

  @override
  String get termsConsentPrefix => 'By continuing, you agree to our ';

  @override
  String get termsAndPrivacy => 'Terms & Privacy';
}
