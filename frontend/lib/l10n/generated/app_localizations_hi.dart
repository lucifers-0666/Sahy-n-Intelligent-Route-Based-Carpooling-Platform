// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get welcomeHeadline => 'सफ़र साझा करें,\nसिर्फ़ सवारी नहीं.';

  @override
  String get welcomeSubline =>
      'भारत भर के रास्तों पर भरोसेमंद सहयात्री और ड्राइवर खोजें.';

  @override
  String get registerIntro => 'भारत के सत्यापित कारपूल समुदाय से जुड़ें.';

  @override
  String get otpIncompleteError => 'सत्यापित करने के लिए सभी ६ अंक दर्ज करें।';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get fullNameHelper => 'आपकी आईडी के अनुसार';

  @override
  String get termsConsentPrefix => 'आगे बढ़ने पर आप सहमत होते हैं ';

  @override
  String get termsAndPrivacy => 'नियम और गोपनीयता';
}
