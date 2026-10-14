import 'package:flutter/material.dart';
import 'package:sahyan/l10n/generated/app_localizations.dart';

/// Lightweight typed localization facade for Sahyān (English, Gujarati, Hindi).
class SahyanLocalizations {
  final Locale locale;
  final AppLocalizations? _strings;

  SahyanLocalizations(this.locale, [this._strings]);

  static SahyanLocalizations of(BuildContext context) {
    return Localizations.of<SahyanLocalizations>(
          context,
          SahyanLocalizations,
        ) ??
        SahyanLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<SahyanLocalizations> delegate =
      _SahyanLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  String get languageCode => locale.languageCode;

  // Welcome Screen
  String get welcomeHeadline {
    if (_strings != null) return _strings.welcomeHeadline;
    switch (languageCode) {
      case 'gu':
        return 'મુસાફરી વહેંચો,\nમાત્ર રાઇડ નહીં.';
      case 'hi':
        return 'सफ़र साझा करें,\nसिर्फ़ सवारी नहीं.';
      default:
        return 'Share the journey,\nnot just the ride.';
    }
  }

  String get welcomeSubline {
    if (_strings != null) return _strings.welcomeSubline;
    switch (languageCode) {
      case 'gu':
        return 'ભારતભરના રૂટ પર પ્રમાણિત સહમુસાફરો અને ડ્રાઇવરો શોધો.';
      case 'hi':
        return 'भारत भर के रास्तों पर भरोसेमंद सहयात्री और ड्राइवर खोजें.';
      default:
        return 'Find verified riders and drivers for routes across India.';
    }
  }

  String get registerIntro {
    if (_strings != null) return _strings.registerIntro;
    switch (languageCode) {
      case 'gu':
        return 'ભારતના પ્રમાણિત કારપૂલિંગ સમુદાયમાં જોડાઓ.';
      case 'hi':
        return 'भारत के सत्यापित कारपूल समुदाय से जुड़ें.';
      default:
        return "Join India's verified carpooling community.";
    }
  }

  String get chipVerified {
    switch (languageCode) {
      case 'gu':
        return 'પ્રમાણિત';
      case 'hi':
        return 'सत्यापित';
      default:
        return 'Verified';
    }
  }

  String get chipFairCost {
    switch (languageCode) {
      case 'gu':
        return 'વાજબી ખર્ચ';
      case 'hi':
        return 'उचित खर्च';
      default:
        return 'Fair cost';
    }
  }

  String get chipDirectRoutes {
    switch (languageCode) {
      case 'gu':
        return 'સીધા રૂટ';
      case 'hi':
        return 'सीधे रूट';
      default:
        return 'Direct routes';
    }
  }

  String get continueWithPhone {
    switch (languageCode) {
      case 'gu':
        return 'મોબાઇલ નંબરથી આગળ વધો';
      case 'hi':
        return 'मोबाइल नंबर से आगे बढ़ें';
      default:
        return 'Continue with phone';
    }
  }

  String get useEmailOrPassword {
    switch (languageCode) {
      case 'gu':
        return 'ઈમેઇલ અથવા પાસવર્ડથી સાઇન ઇન કરો';
      case 'hi':
        return 'ईमेल या पासवर्ड से साइन इन करें';
      default:
        return 'Use email or password instead';
    }
  }

  String get exploreAsGuest {
    switch (languageCode) {
      case 'gu':
        return 'મહેમાન તરીકે જુઓ · રાઇડ્સ શોધો';
      case 'hi':
        return 'अतिथि के रूप में देखें · राइड्स खोजें';
      default:
        return 'Explore as guest · Browse rides';
    }
  }

  // Sign In Screen
  String get whatsYourNumber {
    switch (languageCode) {
      case 'gu':
        return 'તમારો મોબાઇલ નંબર શું છે?';
      case 'hi':
        return 'आपका मोबाइल नंबर क्या है?';
      default:
        return "What's your number?";
    }
  }

  String get enterNumberPrompt {
    switch (languageCode) {
      case 'gu':
        return 'સાઇન ઇન કરવા માટે તમારો ૧૦ અંકનો મોબાઇલ નંબર દાખલ કરો.';
      case 'hi':
        return 'साइन इन करने के लिए अपना १० अंकों का मोबाइल नंबर दर्ज करें.';
      default:
        return 'Enter your mobile number to sign in or get started.';
    }
  }

  String get invalidPhoneError {
    switch (languageCode) {
      case 'gu':
        return 'કૃપા કરીને ૬-૯ થી શરૂ થતો સાચો ૧૦ અંકનો મોબાઇલ નંબર દાખલ કરો';
      case 'hi':
        return 'कृपया ६-९ से शुरू होने वाला मान्य १० अंकों का मोबाइल नंबर दर्ज करें';
      default:
        return 'Please enter a valid 10-digit Indian mobile number (starts with 6-9)';
    }
  }

  String get getOtp {
    switch (languageCode) {
      case 'gu':
        return 'ઓટીપી મેળવો';
      case 'hi':
        return 'ओटीपी प्राप्त करें';
      default:
        return 'Get verification code';
    }
  }

  String get signInWithPasswordInstead {
    switch (languageCode) {
      case 'gu':
        return 'પાસવર્ડ વડે સાઇન ઇન કરો';
      case 'hi':
        return 'पासवर्ड से साइन इन करें';
      default:
        return 'Sign in with password instead';
    }
  }

  String get termsConsentPrefix {
    if (_strings != null) return _strings.termsConsentPrefix;
    switch (languageCode) {
      case 'gu':
        return 'આગળ વધીને તમે સંમત થાઓ છો ';
      case 'hi':
        return 'आगे बढ़कर आप सहमत होते हैं ';
      default:
        return 'By continuing, you agree to our ';
    }
  }

  String get termsAndPrivacy {
    if (_strings != null) return _strings.termsAndPrivacy;
    switch (languageCode) {
      case 'gu':
        return 'નિયમો અને ગોપનીયતા નીતિ';
      case 'hi':
        return 'शर्तें एवं गोपनीयता नीति';
      default:
        return 'Terms & Privacy';
    }
  }

  String get registerPrompt {
    switch (languageCode) {
      case 'gu':
        return 'નવું ખાતું બનાવો? રજીસ્ટર કરો';
      case 'hi':
        return 'नया खाता बनाना है? रजिस्टर करें';
      default:
        return "Don't have an account? Register";
    }
  }

  // OTP Screen
  String get verifyYourPhone {
    switch (languageCode) {
      case 'gu':
        return 'તમારો ફોન ચકાસો';
      case 'hi':
        return 'अपना फ़ोन सत्यापित करें';
      default:
        return 'Verify your phone';
    }
  }

  String get sentCodeTo {
    switch (languageCode) {
      case 'gu':
        return 'અમે ૬ અંકનો કોડ મોકલ્યો છે ';
      case 'hi':
        return 'हमने ६ अंकों का कोड भेजा है ';
      default:
        return 'We sent a 6-digit code to ';
    }
  }

  String get edit {
    switch (languageCode) {
      case 'gu':
        return 'બદલો';
      case 'hi':
        return 'बदलें';
      default:
        return 'Edit';
    }
  }

  String get resendIn {
    switch (languageCode) {
      case 'gu':
        return 'ફરી મોકલો ';
      case 'hi':
        return 'पुनः भेजें ';
      default:
        return 'Resend in ';
    }
  }

  String get resendCode {
    switch (languageCode) {
      case 'gu':
        return 'કોડ ફરી મોકલો';
      case 'hi':
        return 'कोड पुनः भेजें';
      default:
        return 'Resend code';
    }
  }

  String get phoneVerifiedSuccess {
    switch (languageCode) {
      case 'gu':
        return 'ફોન નંબર સફળતાપૂર્વક પ્રમાણિત થયો';
      case 'hi':
        return 'फ़ोन नंबर सफलतापूर्वक सत्यापित हुआ';
      default:
        return 'Phone verified successfully';
    }
  }

  String get otpIncompleteError {
    if (_strings != null) return _strings.otpIncompleteError;
    switch (languageCode) {
      case 'gu':
        return 'ચકાસવા માટે બધા ૬ અંક દાખલ કરો.';
      case 'hi':
        return 'सत्यापित करने के लिए सभी ६ अंक दर्ज करें।';
      default:
        return 'Enter all 6 digits to verify.';
    }
  }

  // Register Screen
  String get createYourAccount {
    switch (languageCode) {
      case 'gu':
        return 'તમારું ખાતું બનાવો';
      case 'hi':
        return 'अपना खाता बनाएं';
      default:
        return 'Create your account';
    }
  }

  String get step1Title {
    switch (languageCode) {
      case 'gu':
        return 'મૂળભૂત માહિતી';
      case 'hi':
        return 'मूल जानकारी';
      default:
        return 'Basic Details';
    }
  }

  String get step2Title {
    switch (languageCode) {
      case 'gu':
        return 'પસંદગી અને રોલ';
      case 'hi':
        return 'प्राथमिकताएं और भूमिका';
      default:
        return 'Preferences & Role';
    }
  }

  String get fullNameLabel {
    if (_strings != null) return _strings.fullNameLabel;
    switch (languageCode) {
      case 'gu':
        return 'પૂરું નામ';
      case 'hi':
        return 'पूरा नाम';
      default:
        return 'Full name';
    }
  }

  String get fullNameHelper {
    if (_strings != null) return _strings.fullNameHelper;
    switch (languageCode) {
      case 'gu':
        return 'તમારા ઓળખપત્ર મુજબ';
      case 'hi':
        return 'आपकी आईडी के अनुसार';
      default:
        return 'As on your ID';
    }
  }

  String get roleSelectionTitle {
    switch (languageCode) {
      case 'gu':
        return 'તમે સહયાનનો ઉપયોગ કેવી રીતે કરશો?';
      case 'hi':
        return 'आप सहयान का उपयोग कैसे करेंगे?';
      default:
        return 'How will you travel with Sahyān?';
    }
  }

  String get rolePassenger {
    switch (languageCode) {
      case 'gu':
        return 'પેસેન્જર';
      case 'hi':
        return 'यात्री';
      default:
        return 'Passenger';
    }
  }

  String get roleDriver {
    switch (languageCode) {
      case 'gu':
        return 'ડ્રાઈવર';
      case 'hi':
        return 'चालक';
      default:
        return 'Driver';
    }
  }

  String get roleBoth {
    switch (languageCode) {
      case 'gu':
        return 'બંને';
      case 'hi':
        return 'दोनों';
      default:
        return 'Both';
    }
  }

  String get driverVerificationNote {
    switch (languageCode) {
      case 'gu':
        return 'નોંધ: રાઇડ ઓફર કરતા પહેલા ડ્રાઇવિંગ લાઇસન્સ અને વાહન ચકાસણી ફરજિયાત છે.';
      case 'hi':
        return 'नोट: राइड पेश करने से पहले ड्राइविंग लाइसेंस और वाहन सत्यापन आवश्यक होगा.';
      default:
        return 'Note: Drivers will need driver licence and vehicle verification before offering rides.';
    }
  }

  String get emailWhyWeAsk {
    switch (languageCode) {
      case 'gu':
        return 'શા માટે પૂછીએ છીએ: માસિક મુસાફરી સ્ટેટમેન્ટ અને રસીદો માટે.';
      case 'hi':
        return 'हम क्यों पूछते हैं: मासिक यात्रा विवरण और रसीदों के लिए.';
      default:
        return 'Why we ask: for monthly trip statements and tax receipts.';
    }
  }

  String get passwordWhyWeAsk {
    switch (languageCode) {
      case 'gu':
        return 'શા માટે પૂછીએ છીએ: અન્ય ઉપકરણો પર SMS ની રાહ જોયા વિના સાઇન ઇન કરવા માટે.';
      case 'hi':
        return 'हम क्यों पूछते हैं: अन्य डिवाइस पर SMS की प्रतीक्षा किए बिना साइन इन करने के लिए.';
      default:
        return 'Why we ask: sign in without waiting for SMS on other devices.';
    }
  }

  // Logout Bottom Sheet
  String get logoutPromptTitle {
    switch (languageCode) {
      case 'gu':
        return 'સહયાનમાંથી લૉગ આઉટ કરવું છે?';
      case 'hi':
        return 'सहयान से लॉग आउट करें?';
      default:
        return 'Log out of Sahyān?';
    }
  }

  String get logoutPromptMessage {
    switch (languageCode) {
      case 'gu':
        return 'આ ઉપકરણ પર ફરીથી સાઇન ઇન કરવા માટે તમારે તમારો ફોન નંબર ચકાસવો પડશે.';
      case 'hi':
        return 'इस डिवाइस पर फिर से साइन इन करने के लिए आपको अपना फ़ोन नंबर सत्यापित करना होगा.';
      default:
        return 'You will need to verify your phone number to sign back in on this device.';
    }
  }

  String get keepLoggedIn {
    switch (languageCode) {
      case 'gu':
        return 'લૉગ ઇન રહો';
      case 'hi':
        return 'लॉग इन रहें';
      default:
        return 'Keep Logged In';
    }
  }

  String get logOutAction {
    switch (languageCode) {
      case 'gu':
        return 'લૉગ આઉટ';
      case 'hi':
        return 'लॉग आउट';
      default:
        return 'Log Out';
    }
  }
}

class _SahyanLocalizationsDelegate
    extends LocalizationsDelegate<SahyanLocalizations> {
  const _SahyanLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'gu', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<SahyanLocalizations> load(Locale locale) async {
    final strings = await AppLocalizations.delegate.load(locale);
    return SahyanLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_SahyanLocalizationsDelegate old) => false;
}
