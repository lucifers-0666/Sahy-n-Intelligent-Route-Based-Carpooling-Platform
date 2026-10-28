import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// Hero headline on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Share the journey,\nnot just the ride.'**
  String get welcomeHeadline;

  /// Subline on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Find verified riders and drivers for routes across India.'**
  String get welcomeSubline;

  /// Intro copy on registration screen.
  ///
  /// In en, this message translates to:
  /// **'Join India\'s verified carpooling community.'**
  String get registerIntro;

  /// No description provided for @chipVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get chipVerified;

  /// No description provided for @chipFairCost.
  ///
  /// In en, this message translates to:
  /// **'Fair cost'**
  String get chipFairCost;

  /// No description provided for @chipDirectRoutes.
  ///
  /// In en, this message translates to:
  /// **'Direct routes'**
  String get chipDirectRoutes;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get continueWithPhone;

  /// No description provided for @useEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Use email or password instead'**
  String get useEmailOrPassword;

  /// No description provided for @continueWithEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Use email or password instead'**
  String get continueWithEmailOrPassword;

  /// No description provided for @exploreAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Explore as guest · Browse rides'**
  String get exploreAsGuest;

  /// No description provided for @whatsYourNumber.
  ///
  /// In en, this message translates to:
  /// **'What\'s your number?'**
  String get whatsYourNumber;

  /// No description provided for @enterNumberPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to sign in or get started.'**
  String get enterNumberPrompt;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit Indian mobile number (starts with 6-9)'**
  String get invalidPhoneError;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get verification code'**
  String get getOtp;

  /// No description provided for @signInWithPasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password instead'**
  String get signInWithPasswordInstead;

  /// Legal consent copy; must be reviewed by legal counsel.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get termsConsentPrefix;

  /// Legal link label; must be reviewed by legal counsel.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsAndPrivacy;

  /// No description provided for @registerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get registerPrompt;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get verifyYourPhone;

  /// No description provided for @sentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to '**
  String get sentCodeTo;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in '**
  String get resendIn;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @phoneVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully'**
  String get phoneVerifiedSuccess;

  /// Validation error when fewer than 6 OTP digits are entered.
  ///
  /// In en, this message translates to:
  /// **'Enter all 6 digits to verify.'**
  String get otpIncompleteError;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Role'**
  String get step2Title;

  /// Label for the full name text input.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// Helper text beneath the full name text input.
  ///
  /// In en, this message translates to:
  /// **'As on your ID'**
  String get fullNameHelper;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you travel with Sahyān?'**
  String get roleSelectionTitle;

  /// No description provided for @rolePassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get rolePassenger;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get roleBoth;

  /// No description provided for @driverVerificationNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Drivers will need driver licence and vehicle verification before offering rides.'**
  String get driverVerificationNote;

  /// No description provided for @emailWhyWeAsk.
  ///
  /// In en, this message translates to:
  /// **'Why we ask: for monthly trip statements and tax receipts.'**
  String get emailWhyWeAsk;

  /// No description provided for @passwordWhyWeAsk.
  ///
  /// In en, this message translates to:
  /// **'Why we ask: sign in without waiting for SMS on other devices.'**
  String get passwordWhyWeAsk;

  /// No description provided for @logoutPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of Sahyān?'**
  String get logoutPromptTitle;

  /// No description provided for @logoutPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to verify your phone number to sign back in on this device.'**
  String get logoutPromptMessage;

  /// No description provided for @keepLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep Logged In'**
  String get keepLoggedIn;

  /// No description provided for @logOutAction.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSectionHeader;

  /// No description provided for @carpoolMember.
  ///
  /// In en, this message translates to:
  /// **'Carpool Member'**
  String get carpoolMember;

  /// No description provided for @memberAccount.
  ///
  /// In en, this message translates to:
  /// **'Member Account'**
  String get memberAccount;

  /// No description provided for @editProfileAndPrefs.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile & Travel Preferences'**
  String get editProfileAndPrefs;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'City, bio, and co-traveler preferences'**
  String get editProfileSubtitle;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get savedPlaces;

  /// No description provided for @savedPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Home, Work and custom addresses'**
  String get savedPlacesSubtitle;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @emergencyContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted contacts notified during SOS alerts'**
  String get emergencyContactsSubtitle;

  /// No description provided for @driverStatusAndVehicles.
  ///
  /// In en, this message translates to:
  /// **'Driver Status & Vehicles'**
  String get driverStatusAndVehicles;

  /// No description provided for @driverStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approved driver • Manage fleet and routes'**
  String get driverStatusSubtitle;

  /// No description provided for @driverOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Verification & Onboarding'**
  String get driverOnboardingTitle;

  /// No description provided for @driverOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit driving licence to offer shared rides'**
  String get driverOnboardingSubtitle;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE & REGION'**
  String get languageAndRegion;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English • ગુજરાતી • हिन्दी'**
  String get languageSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant booking updates and ride statuses'**
  String get pushNotificationsSubtitle;

  /// No description provided for @tripStatusAlerts.
  ///
  /// In en, this message translates to:
  /// **'Trip Status Alerts'**
  String get tripStatusAlerts;

  /// No description provided for @tripStatusAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Boarding reminders and departure countdowns'**
  String get tripStatusAlertsSubtitle;

  /// No description provided for @carpoolCommunityUpdates.
  ///
  /// In en, this message translates to:
  /// **'Carpool Community Updates'**
  String get carpoolCommunityUpdates;

  /// No description provided for @carpoolCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New highway corridors and eco impact digests'**
  String get carpoolCommunitySubtitle;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY & SECURITY'**
  String get privacyAndSecurity;

  /// No description provided for @routeLocationSharing.
  ///
  /// In en, this message translates to:
  /// **'Route Location Sharing'**
  String get routeLocationSharing;

  /// No description provided for @routeLocationSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share active corridor location with confirmed driver'**
  String get routeLocationSharingSubtitle;

  /// No description provided for @appLockFingerprint.
  ///
  /// In en, this message translates to:
  /// **'App Lock / Fingerprint Unlock'**
  String get appLockFingerprint;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometric auth to open Sahyān'**
  String get appLockSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @privacyPermissions.
  ///
  /// In en, this message translates to:
  /// **'Privacy & System Permissions'**
  String get privacyPermissions;

  /// No description provided for @privacyPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Corridor location, sensor, and DPDP rights'**
  String get privacyPermissionsSubtitle;

  /// No description provided for @aboutAndLegal.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & LEGAL'**
  String get aboutAndLegal;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @applicationVersion.
  ///
  /// In en, this message translates to:
  /// **'Application Version'**
  String get applicationVersion;

  /// No description provided for @safetyCenterProtocols.
  ///
  /// In en, this message translates to:
  /// **'Safety Center & Protocols'**
  String get safetyCenterProtocols;

  /// No description provided for @safetyCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trust score, verification, and roadside emergency'**
  String get safetyCenterSubtitle;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @helpAndSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ, dispute resolution, and member desk'**
  String get helpAndSupportSubtitle;

  /// No description provided for @systemStatesDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'System States & Diagnostics'**
  String get systemStatesDiagnostics;

  /// No description provided for @systemStatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test offline mode, refunds, and edge scenarios'**
  String get systemStatesSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccountDpdp.
  ///
  /// In en, this message translates to:
  /// **'Delete Account & Erase Personal Data (DPDP Act)'**
  String get deleteAccountDpdp;

  /// No description provided for @takeRide.
  ///
  /// In en, this message translates to:
  /// **'Take a Ride'**
  String get takeRide;

  /// No description provided for @offerRide.
  ///
  /// In en, this message translates to:
  /// **'Offer a Ride'**
  String get offerRide;

  /// No description provided for @whereHeading.
  ///
  /// In en, this message translates to:
  /// **'Where are you heading?'**
  String get whereHeading;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @frequentCorridors.
  ///
  /// In en, this message translates to:
  /// **'Frequent Corridors'**
  String get frequentCorridors;

  /// No description provided for @travelDateTime.
  ///
  /// In en, this message translates to:
  /// **'Travel date & time'**
  String get travelDateTime;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// No description provided for @findMatchingRides.
  ///
  /// In en, this message translates to:
  /// **'Find Matching Rides'**
  String get findMatchingRides;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on Map'**
  String get chooseOnMap;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'PICKUP LOCATION'**
  String get pickupLabel;

  /// No description provided for @destinationLabel.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION'**
  String get destinationLabel;

  /// No description provided for @pickupHint.
  ///
  /// In en, this message translates to:
  /// **'Search city, area or landmark'**
  String get pickupHint;

  /// No description provided for @destinationHint.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get destinationHint;

  /// No description provided for @myJourneys.
  ///
  /// In en, this message translates to:
  /// **'My Journeys'**
  String get myJourneys;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tabPending;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @noActiveBoardingPasses.
  ///
  /// In en, this message translates to:
  /// **'No Active Boarding Passes'**
  String get noActiveBoardingPasses;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No Pending Requests'**
  String get noPendingRequests;

  /// No description provided for @noTripHistory.
  ///
  /// In en, this message translates to:
  /// **'No Ride History Yet'**
  String get noTripHistory;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @viewRideDetails.
  ///
  /// In en, this message translates to:
  /// **'View Ride Details'**
  String get viewRideDetails;

  /// No description provided for @digitalBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'Digital Boarding Pass'**
  String get digitalBoardingPass;

  /// No description provided for @boardingPass.
  ///
  /// In en, this message translates to:
  /// **'Boarding Pass'**
  String get boardingPass;

  /// No description provided for @scanToBoard.
  ///
  /// In en, this message translates to:
  /// **'Scan to Board'**
  String get scanToBoard;

  /// No description provided for @seatConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Seat Confirmed'**
  String get seatConfirmed;

  /// No description provided for @fare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fare;

  /// No description provided for @seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seats;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @dropoff.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get dropoff;

  /// No description provided for @rateTripAndDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate Trip & Driver'**
  String get rateTripAndDriver;

  /// No description provided for @ecoImpact.
  ///
  /// In en, this message translates to:
  /// **'Eco Impact'**
  String get ecoImpact;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @cancelRequestConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request?'**
  String get cancelRequestConfirmTitle;

  /// No description provided for @cancelRequestConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking request? The driver will be notified.'**
  String get cancelRequestConfirmMessage;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @bookingRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking request cancelled'**
  String get bookingRequestCancelled;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get navRides;

  /// No description provided for @navOfferRide.
  ///
  /// In en, this message translates to:
  /// **'Offer Ride'**
  String get navOfferRide;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @offerRideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Route Details'**
  String get offerRideStep1Title;

  /// No description provided for @offerRideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Timing & Pricing'**
  String get offerRideStep2Title;

  /// No description provided for @offerRideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Preferences'**
  String get offerRideStep3Title;

  /// No description provided for @publishRide.
  ///
  /// In en, this message translates to:
  /// **'Publish Ride'**
  String get publishRide;

  /// No description provided for @availableSeats.
  ///
  /// In en, this message translates to:
  /// **'Available Seats'**
  String get availableSeats;

  /// No description provided for @pricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per Seat'**
  String get pricePerSeat;

  /// No description provided for @stopovers.
  ///
  /// In en, this message translates to:
  /// **'Stopovers'**
  String get stopovers;

  /// No description provided for @addStopover.
  ///
  /// In en, this message translates to:
  /// **'Add Stopover'**
  String get addStopover;

  /// No description provided for @departureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure Time'**
  String get departureTime;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get selectVehicle;

  /// No description provided for @rideDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetailsTitle;

  /// No description provided for @rideOverview.
  ///
  /// In en, this message translates to:
  /// **'Ride Overview'**
  String get rideOverview;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @requestSeat.
  ///
  /// In en, this message translates to:
  /// **'Request Seat'**
  String get requestSeat;

  /// No description provided for @requestUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Request Under Review (Pending Driver Approval)'**
  String get requestUnderReview;

  /// No description provided for @seatConfirmedActive.
  ///
  /// In en, this message translates to:
  /// **'Seat Confirmed · Active Booking'**
  String get seatConfirmedActive;

  /// No description provided for @noRideSelected.
  ///
  /// In en, this message translates to:
  /// **'No ride selected'**
  String get noRideSelected;

  /// No description provided for @unableToLoadRide.
  ///
  /// In en, this message translates to:
  /// **'Unable to load ride details'**
  String get unableToLoadRide;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// No description provided for @coTravelers.
  ///
  /// In en, this message translates to:
  /// **'Co-travelers'**
  String get coTravelers;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @languageChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChangedSuccess;

  /// No description provided for @seatsRequested.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 seat requested} other{{count} seats requested}}'**
  String seatsRequested(int count);

  /// No description provided for @seatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 seat available} other{{count} seats available}}'**
  String seatsAvailable(int count);

  /// No description provided for @seatsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 seat} other{{count} seats}}'**
  String seatsCount(int count);

  /// No description provided for @passengersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 passenger} other{{count} passengers}}'**
  String passengersCount(int count);

  /// No description provided for @co2Saved.
  ///
  /// In en, this message translates to:
  /// **'You saved {kg} kg CO₂ this month'**
  String co2Saved(String kg);

  /// No description provided for @autoExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Auto-expires in {min} mins if unaccepted'**
  String autoExpiresIn(int min);

  /// No description provided for @stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepIndicator(int current, int total);

  /// No description provided for @findRideAlongRoute.
  ///
  /// In en, this message translates to:
  /// **'Find a ride along your route.'**
  String get findRideAlongRoute;

  /// No description provided for @p2pCorridor.
  ///
  /// In en, this message translates to:
  /// **'P2P Corridor'**
  String get p2pCorridor;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @popularHighwayCorridors.
  ///
  /// In en, this message translates to:
  /// **'Popular Highway Corridors'**
  String get popularHighwayCorridors;

  /// No description provided for @verifiedCarpoolCommunity.
  ///
  /// In en, this message translates to:
  /// **'Verified Carpool Community'**
  String get verifiedCarpoolCommunity;

  /// No description provided for @communityVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Government ID verification, vehicle registration validation, and 4-digit boarding security on every planned journey.'**
  String get communityVerifiedSubtitle;

  /// No description provided for @standardCorridorFlow.
  ///
  /// In en, this message translates to:
  /// **'Standard Corridor Flow'**
  String get standardCorridorFlow;

  /// No description provided for @directIntercityTransit.
  ///
  /// In en, this message translates to:
  /// **'Direct intercity highway routing · Co-travel verified'**
  String get directIntercityTransit;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @vehicleAndRoute.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Route'**
  String get vehicleAndRoute;

  /// No description provided for @scheduleAndSeats.
  ///
  /// In en, this message translates to:
  /// **'Schedule & Seats'**
  String get scheduleAndSeats;

  /// No description provided for @reviewAndPublish.
  ///
  /// In en, this message translates to:
  /// **'Review & Publish'**
  String get reviewAndPublish;

  /// No description provided for @amenitiesAndPreferences.
  ///
  /// In en, this message translates to:
  /// **'Amenities & Preferences'**
  String get amenitiesAndPreferences;

  /// No description provided for @journeyNotes.
  ///
  /// In en, this message translates to:
  /// **'Journey Notes'**
  String get journeyNotes;

  /// No description provided for @journeySummary.
  ///
  /// In en, this message translates to:
  /// **'Journey Summary'**
  String get journeySummary;

  /// No description provided for @freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free Cancellation'**
  String get freeCancellation;

  /// No description provided for @secureBoardingPin.
  ///
  /// In en, this message translates to:
  /// **'Secure Boarding PIN'**
  String get secureBoardingPin;

  /// No description provided for @sosProtection.
  ///
  /// In en, this message translates to:
  /// **'Live Journey & SOS Protection'**
  String get sosProtection;

  /// No description provided for @trustSafetyPolicies.
  ///
  /// In en, this message translates to:
  /// **'Trust, Safety & Policies'**
  String get trustSafetyPolicies;

  /// No description provided for @tripInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in Progress'**
  String get tripInProgress;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get tripCompleted;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled'**
  String get rideCancelled;

  /// No description provided for @rideFull.
  ///
  /// In en, this message translates to:
  /// **'Ride Full'**
  String get rideFull;

  /// No description provided for @becomeHost.
  ///
  /// In en, this message translates to:
  /// **'Become a Host'**
  String get becomeHost;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @safetyCenter.
  ///
  /// In en, this message translates to:
  /// **'Safety Center'**
  String get safetyCenter;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServerError;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Requested resource was not found.'**
  String get errorNotFound;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @tripPaymentEscrow.
  ///
  /// In en, this message translates to:
  /// **'Trip Payment & Escrow'**
  String get tripPaymentEscrow;

  /// No description provided for @sandboxSimulationCheckout.
  ///
  /// In en, this message translates to:
  /// **'Sandbox Simulation Checkout'**
  String get sandboxSimulationCheckout;

  /// No description provided for @simulatedEscrowSandbox.
  ///
  /// In en, this message translates to:
  /// **'Simulated Escrow Sandbox'**
  String get simulatedEscrowSandbox;

  /// No description provided for @testMode.
  ///
  /// In en, this message translates to:
  /// **'TEST MODE'**
  String get testMode;

  /// No description provided for @sandboxNotice.
  ///
  /// In en, this message translates to:
  /// **'This transaction runs in sandbox prototype mode. No actual currency or bank account will be debited.'**
  String get sandboxNotice;

  /// No description provided for @paymentAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Payment Authorized'**
  String get paymentAuthorized;

  /// No description provided for @paymentEscrowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Funds placed securely in simulated escrow. Funds will only be released to the driver upon successful trip completion.'**
  String get paymentEscrowSuccess;

  /// No description provided for @viewBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'View Boarding Pass'**
  String get viewBoardingPass;

  /// No description provided for @fareBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Fare Breakdown'**
  String get fareBreakdown;

  /// No description provided for @baseContribution.
  ///
  /// In en, this message translates to:
  /// **'Base Contribution'**
  String get baseContribution;

  /// No description provided for @platformSafetyFee.
  ///
  /// In en, this message translates to:
  /// **'Platform & Safety Fee'**
  String get platformSafetyFee;

  /// No description provided for @tollSplitContribution.
  ///
  /// In en, this message translates to:
  /// **'Toll Split Contribution'**
  String get tollSplitContribution;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @payWithUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI Instant (GPay / PhonePe / Paytm)'**
  String get payWithUpi;

  /// No description provided for @payWithCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get payWithCard;

  /// No description provided for @payWithNetbanking.
  ///
  /// In en, this message translates to:
  /// **'Net Banking'**
  String get payWithNetbanking;

  /// No description provided for @payWithSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox Simulated Escrow'**
  String get payWithSandbox;

  /// No description provided for @authorizeAndHoldEscrow.
  ///
  /// In en, this message translates to:
  /// **'Authorize & Hold Escrow'**
  String get authorizeAndHoldEscrow;

  /// No description provided for @reportDispute.
  ///
  /// In en, this message translates to:
  /// **'Report Dispute'**
  String get reportDispute;

  /// No description provided for @disputeCaseSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Dispute case submitted for administrative review'**
  String get disputeCaseSubmitted;

  /// No description provided for @reportNoShow.
  ///
  /// In en, this message translates to:
  /// **'Report No-Show'**
  String get reportNoShow;

  /// No description provided for @noShowRecorded.
  ///
  /// In en, this message translates to:
  /// **'No-show recorded and submitted for verification'**
  String get noShowRecorded;

  /// No description provided for @refundRequested.
  ///
  /// In en, this message translates to:
  /// **'Refund Requested'**
  String get refundRequested;

  /// No description provided for @transactionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistoryTitle;

  /// No description provided for @escrowLedgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contribution & Escrow Ledger'**
  String get escrowLedgerSubtitle;

  /// No description provided for @totalContributionsLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL FUEL CONTRIBUTIONS'**
  String get totalContributionsLabel;

  /// No description provided for @heldInEscrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Held in Escrow'**
  String get heldInEscrowLabel;

  /// No description provided for @escrowExplanationShort.
  ///
  /// In en, this message translates to:
  /// **'Safeguarded until passenger drop-off PIN verification'**
  String get escrowExplanationShort;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterInEscrow.
  ///
  /// In en, this message translates to:
  /// **'In Escrow'**
  String get filterInEscrow;

  /// No description provided for @filterSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get filterSettled;

  /// No description provided for @filterRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get filterRefunded;

  /// No description provided for @filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get filterFailed;

  /// No description provided for @filterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filterOpen;

  /// No description provided for @filterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// No description provided for @filterResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get filterResolved;

  /// No description provided for @errorLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Transactions'**
  String get errorLoadingTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No Transactions Found'**
  String get noTransactionsFound;

  /// No description provided for @noTransactionsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have no payment contributions or ledger entries matching this status.'**
  String get noTransactionsFoundSubtitle;

  /// No description provided for @corridorContributionLabel.
  ///
  /// In en, this message translates to:
  /// **'Corridor Contribution'**
  String get corridorContributionLabel;

  /// No description provided for @sandboxSimulatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Sandbox Simulated'**
  String get sandboxSimulatedBadge;

  /// No description provided for @liveClearingBadge.
  ///
  /// In en, this message translates to:
  /// **'Live Clearing'**
  String get liveClearingBadge;

  /// No description provided for @refLabel.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get refLabel;

  /// No description provided for @viewReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get viewReceiptAction;

  /// No description provided for @statusInEscrow.
  ///
  /// In en, this message translates to:
  /// **'In Escrow'**
  String get statusInEscrow;

  /// No description provided for @statusSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get statusSettled;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get statusDisputed;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @supportTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get supportTicketsTitle;

  /// No description provided for @supportTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Priority Member Help Desk'**
  String get supportTicketsSubtitle;

  /// No description provided for @newTicketButton.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get newTicketButton;

  /// No description provided for @errorLoadingTickets.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Tickets'**
  String get errorLoadingTickets;

  /// No description provided for @noTicketsFound.
  ///
  /// In en, this message translates to:
  /// **'No Support Tickets'**
  String get noTicketsFound;

  /// No description provided for @noTicketsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have not submitted any help desk requests yet.'**
  String get noTicketsFoundSubtitle;

  /// No description provided for @createTicketPromptAction.
  ///
  /// In en, this message translates to:
  /// **'Submit a Request'**
  String get createTicketPromptAction;

  /// No description provided for @messagesCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'messages'**
  String get messagesCountSuffix;

  /// No description provided for @createTicketSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Support Request'**
  String get createTicketSheetTitle;

  /// No description provided for @createTicketSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our community desk responds within 2-4 hours.'**
  String get createTicketSheetSubtitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryRideIssue.
  ///
  /// In en, this message translates to:
  /// **'Ride Issue'**
  String get categoryRideIssue;

  /// No description provided for @categoryPaymentInquiry.
  ///
  /// In en, this message translates to:
  /// **'Payment Inquiry'**
  String get categoryPaymentInquiry;

  /// No description provided for @categoryDriverBehavior.
  ///
  /// In en, this message translates to:
  /// **'Driver Behavior'**
  String get categoryDriverBehavior;

  /// No description provided for @categoryTechBug.
  ///
  /// In en, this message translates to:
  /// **'Technical Bug'**
  String get categoryTechBug;

  /// No description provided for @categoryAccountAccess.
  ///
  /// In en, this message translates to:
  /// **'Account Access'**
  String get categoryAccountAccess;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other / Inquiry'**
  String get categoryOther;

  /// No description provided for @subjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjectLabel;

  /// No description provided for @subjectHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of the issue...'**
  String get subjectHint;

  /// No description provided for @subjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get subjectRequired;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the circumstances, corridor location, or question in detail...'**
  String get descriptionHint;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a detailed description'**
  String get descriptionRequired;

  /// No description provided for @submitTicketButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Support Request'**
  String get submitTicketButton;

  /// No description provided for @ticketCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Support ticket opened'**
  String get ticketCreatedSuccess;

  /// No description provided for @ticketCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create support ticket. Please retry.'**
  String get ticketCreateFailed;

  /// No description provided for @ticketDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket Conversation'**
  String get ticketDetailTitle;

  /// No description provided for @corridorLabel.
  ///
  /// In en, this message translates to:
  /// **'Corridor'**
  String get corridorLabel;

  /// No description provided for @markResolvedAction.
  ///
  /// In en, this message translates to:
  /// **'Mark Resolved'**
  String get markResolvedAction;

  /// No description provided for @supportTeamSender.
  ///
  /// In en, this message translates to:
  /// **'Sahyān Support Specialist'**
  String get supportTeamSender;

  /// No description provided for @replyMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message to support...'**
  String get replyMessageHint;

  /// No description provided for @ticketClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This support ticket is closed. For new inquiries, please create a new ticket.'**
  String get ticketClosedNotice;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
