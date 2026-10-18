# Sahyān — User & Driver UX, Account Model, and Screen Architecture Audit

**Document Version:** 1.0.0  
**Target Architecture:** Single-Account Role-Based Experience (Passenger, Approved Driver, Co-Role Member)  
**Security & Verification Standard:** Zero-Trust Role & Capability Enforcement, Non-Repudiation, DPDP Act Compliance  

---

## 1. Executive Summary

Sahyān is an intelligent, route-based peer-to-peer carpooling platform designed for verified intercity and regional highway travel across Gujarat and national corridors. 

A central foundational requirement of Sahyān is the **Unified Account Architecture**: every participant possesses exactly one user account and identity. A user may act as a passenger seeking and booking seats, an approved driver offering empty vehicle capacity along scheduled routes, or both interchangeably. 

This audit analyzes the current implementation across frontend and backend, highlights architectural gaps in driver onboarding and profile presentation, defines a decoupled role and approval model, and presents an actionable execution plan.

---

## 2. Inventory of Existing User-Side Routes & Screens

Based on [app_router.dart](file:///e:/Sahyān_MCA_APP/frontend/lib/app/router/app_router.dart), the application currently registers 42 discrete routes across 11 feature modules:

### 2.1 Authentication & Entry Routes
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/` | `SplashScreen` | Initialization, token verification, route routing |
| `/onboarding` | `OnboardingScreen` | 3-step value proposition with vector illustrations |
| `/auth-entry` | `AuthDecisionScreen` | Gateway between Sign In, Registration, and Guest exploration |
| `/welcome` | `WelcomeScreen` | Visual welcome screen |
| `/welcome-back` | `WelcomeBackScreen` | Quick re-authentication with biometrics option |
| `/login` | `LoginScreen` | Phone OTP, Email/Password, or Firebase Google Sign-In |
| `/register` | `RegisterScreen` | Passenger registration (Name, Email, 10-digit Indian Mobile, Password) |
| `/otp` | `OtpScreen` | 6-digit cryptographic phone verification |
| `/forgot-password` | `ForgotPasswordScreen` | Password recovery initiation |
| `/reset-password` | `ResetPasswordScreen` | Password reset with token |
| `/auth-success` | `AuthSuccessScreen` | Post-auth celebration and redirection |
| `/account-suspended` | `AccountSuspendedScreen` | Safety/Admin suspension notification with appeal details |

### 2.2 Core Dashboard & Discovery (Preserved)
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/home` (Tab 0) | `HomeScreen` | Bento-grid route search card, quick corridors, mobility ergonomics |
| `/travel-date-time` | `TravelDateTimeScreen` | Dedicated modal for departure date presets, calendar, and time slots |
| `/passenger-selection` | `PassengerSelectionScreen` | Dedicated modal for 1-6 seat allocation and luggage guidelines |
| `/search-results` (Tab 1) | `SearchResultsScreen` | List of matching carpool routes ranked by match grade |
| `/filter-rides` | `FilterRidesScreen` | Filter by departure time, price, seats, and amenities |
| `/ride-details` | `RideDetailsScreen` | Detailed route overview, driver profile, vehicle info, and pickup map |

### 2.3 Ride Creation & Publishing
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/offer-ride` (Tab 2) | `OfferRideScreen` | 3-step wizard (Vehicle & Route, Schedule & Seats, Review & Publish) |
| `/publish-ride` | `OfferRideScreen` | Alias route for `/offer-ride` |
| `/ride-published` | `RidePublishedScreen` | Trip creation confirmation with corridor sharing options |

### 2.4 Passenger Booking Lifecycle
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/seat-selection` | `SeatSelectionScreen` | Interactive seat layout selection |
| `/confirm-pay` | `ConfirmPayScreen` | Booking breakdown and simulated cost contribution |
| `/booking-confirmation` | `BookingConfirmationScreen` | Confirmed pass with OTP boarding pass |
| `/bookings` (Tab 3) | `BookingsHubScreen` | Consolidated passenger passes and driver trips |
| `/booking-details` | `BookingDetailsScreen` | Detailed pass view, pickup time, driver contact, and cancel action |
| `/booking-request` | `BookingRequestScreen` | Passenger request status and booking summary |
| `/cancel-booking` | `CancelBookingScreen` | Cancellation policy, reason capture, and refund calculation |

### 2.5 Driver Management & Active Trip
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/driver/rides` | `DriverRidesScreen` | List of published rides with passenger manifests |
| `/driver/request-details` | `DriverRequestDetailsScreen` | Accept/Decline pending passenger booking requests |
| `/driver/active-ride` | `DriverActiveRideScreen` | Live telematics, boarding validation, waypoint progression |
| `/driver/payout` | `DriverPayoutScreen` | Driver settlement ledger, earnings overview |
| `/driver/payout-account` | `PayoutAccountScreen` | Bank account and UPI ID management |

### 2.6 Vehicles Fleet Module
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/vehicles` | `MyVehiclesScreen` | List of registered vehicles owned by the user |
| `/vehicles/add` | `AddVehicleScreen` | Form for Registration, Make, Model, Year, Color, Capacity, Type |
| `/vehicles/edit` | `EditVehicleScreen` | Edit vehicle specifications or deactivate |

### 2.7 Account, Profile & Settings
| Route | Screen Widget | Purpose & State |
|---|---|---|
| `/profile` (Tab 4) | `ProfileScreen` | User summary, ratings, emergency contacts, links to fleet |
| `/personal-details` | `PersonalDetailsScreen` | Profile identity data (Name, Phone, Email, City) |
| `/edit-profile` | `EditProfileScreen` | Update Name, City, Bio, Travel Preferences (Smoking, Pets) |
| `/emergency-contacts` | `EmergencyContactsScreen` | CRUD for emergency safety contacts |
| `/saved-places` | `SavedPlacesScreen` | Frequent addresses (Home, Office, Hubs) |
| `/reviews` | `ReviewsRatingsScreen` | Review ledger and peer feedback ratings |
| `/ride-history` | `RideHistoryScreen` | Historical completed and cancelled journeys |
| `/settings` | `SettingsScreen` | App Lock, notifications, privacy, legal, and sign-out |
| `/safety-center` | `SafetyCenterScreen` | Platform safety protocols, SOS guide, background verification info |
| `/help-support` | `HelpSupportScreen` | FAQs, support tickets, dispute resolution |
| `/privacy-permissions` | `PrivacyPermissionsScreen` | Location, storage, biometric, and DPDP data rights |
| `/system-states` | `SystemStatesScreen` | Developer and testing diagnostics harness |
| `/gps-diagnostics` | `GpsDiagnosticScreen` | Live location hardware telemetry diagnostics |

---

## 3. Account, Role, and Permission Model

### 3.1 Existing Backend Data Schema (`User.js`)
In [User.js](file:///e:/Sahyān_MCA_APP/backend/src/models/User.js), the user schema currently incorporates:
```javascript
{
  role: {
    type: String,
    enum: ['user', 'admin', 'super_admin', 'safety_officer', 'support_lead'],
    default: 'user',
  },
  capabilities: {
    canRide: { type: Boolean, default: true },
    canDrive: { type: Boolean, default: false },
  },
  accountStatus: {
    type: String,
    enum: ['active', 'suspended'],
    default: 'active',
  },
  isVerified: {
    type: Boolean,
    default: false, // Indicates phone number OTP verification
  },
  driverProfile: {
    onboardingStatus: {
      type: String,
      enum: ['not_started', 'in_progress', 'submitted', 'approved', 'rejected'],
      default: 'not_started',
    },
    licenseNumber: { type: String, default: '' },
    licenseDocUrl: { type: String, default: '' },
    rcDocUrl: { type: String, default: '' },
    idDocUrl: { type: String, default: '' },
    rejectionReason: { type: String, default: '' },
    verifiedAt: Date,
  }
}
```

### 3.2 Decoupled Concept Matrix
To deliver a coherent, role-aware user experience without schema fragmentation, we formally decouple the six operational dimensions:

| Dimension | Scope | Possible States | System Impact |
|---|---|---|---|
| **1. Account Status** | Global Platform | `active`, `suspended` | `suspended` blocks all login, search, booking, and publishing actions. |
| **2. Phone Verification** | Identity / Auth | `false` (unverified), `true` (verified) | Unverified users must complete OTP before booking or publishing. |
| **3. Passenger Eligibility** | Travel Booking | `canRide == true` | Granted by default upon phone verification. No driver docs or vehicle required. |
| **4. Driver Application Status** | Verification Pipeline | `not_started`, `in_progress`, `submitted`, `approved`, `rejected` | Progress tracker for driving licence, ID proof, and vehicle documents. |
| **5. Driver Capability** | Ride Publishing | `canDrive == true && onboardingStatus == 'approved'` | Enforced on backend during `POST /api/v1/rides`. |
| **6. Vehicle Status** | Asset Management | `active`, `pending_verification`, `rejected`, `inactive` | Vehicle must be `active` and owned by the driver to publish a ride. |
| **7. Active UI Mode** | Presentation Context | `passenger`, `driver` | Dictates dashboard quick actions, tab emphasis, and profile tools. Does not restrict passenger access. |

---

## 4. Current Gaps & Missing Implementations

### 4.1 Driver Onboarding Gap (High Priority)
- **Current Behavior**: No driver onboarding screen exists in the frontend. When a passenger visits `/offer-ride` without a vehicle, they are prompted to add a vehicle at `/vehicles/add`. In `vehicleController.js`, adding a vehicle previously set `user.capabilities.canDrive = true` and `user.driverProfile.onboardingStatus = 'approved'`.
- **Deficiency**: This completely bypassed driving licence verification, government identity checks, review timelines, and administrative approval. A user with no licence could register a vehicle and immediately publish commercial-scale trips.
- **Remedy**: 
  1. Introduce a dedicated `DriverOnboardingScreen` (`/driver-onboarding`) guiding the user through:
     - Step 1: Personal & contact info confirmation
     - Step 2: Driving licence details & document upload/photo
     - Step 3: Vehicle selection or registration linking
     - Step 4: Submission review & status tracker (`submitted`, `approved`, `rejected`)
  2. Implement backend endpoint `POST /api/v1/users/driver-application` and `GET /api/v1/users/driver-status`.
  3. Ensure `POST /api/v1/rides` strictly rejects ride publishing unless `req.user.capabilities.canDrive === true && req.user.driverProfile.onboardingStatus === 'approved'`.

### 4.2 Profile Screen Presentation Gap (Medium Priority)
- **Current Behavior**: [profile_screen.dart](file:///e:/Sahyān_MCA_APP/frontend/lib/features/profile/presentation/screens/profile_screen.dart) renders driver sections ("My Vehicles & Fleet", "My Offered Rides & Requests", "Driver Earnings & Payout") unconditionally to all users, even those who only registered to book passenger seats.
- **Deficiency**: Clutters passenger experience and presents "Register a vehicle to offer rides" as the sole requirement. If an application is rejected or pending, it displays generic static text.
- **Remedy**:
  1. If `user.driverOnboardingStatus == 'not_started'`: Show a prominent, tasteful banner: "Earn by sharing empty seats — Become a Sahyān Driver" with a direct CTA to `/driver-onboarding`. Hide driver payout and fleet tiles from the main card.
  2. If `user.driverOnboardingStatus == 'submitted'`: Display a clean amber badge and status card: "Driver Verification in Review (Estimated: 24-48 hrs)".
  3. If `user.driverOnboardingStatus == 'rejected'`: Display an action-required notice with `rejectionReason` and an "Update Documents" button.
  4. If `user.driverOnboardingStatus == 'approved'`: Display an emerald verified driver badge, quick mode switch toggle, and full vehicle/driver fleet management tools.

### 4.3 Offer Ride Gating Gap (High Priority)
- **Current Behavior**: If an unapproved user taps "Offer Ride" in bottom navigation, the screen currently shows a vehicle picker.
- **Remedy**:
  - Intercept in `OfferRideScreen` (or during bottom navigation tap in `AppShell`): If the user is authenticated but not an approved driver (`!user.isDriverEligible`), present a dedicated, informative gate screen:
    - If `not_started`: "Become a Verified Sahyān Driver" with breakdown of benefits (cost sharing, trusted community) and "Start Verification" button.
    - If `submitted`: "Application Under Review" with checklist showing completed steps.
    - If `rejected`: "Action Required on Driver Application" displaying the specific rejection reason.

### 4.4 Settings & Supporting Pages Audit
- [settings_screen.dart](file:///e:/Sahyān_MCA_APP/frontend/lib/features/settings/presentation/screens/settings_screen.dart): Contains functional App Lock, notification toggles, saved places, safety center, and helpdesk links.
- **Gaps**:
  - Missing Language Preferences selector (English / Hindi / Gujarati).
  - Terms of Service & Privacy Policy currently rely solely on `SahyanLegalSheet` modal. A dedicated view or persistent legal reader is beneficial.
  - Account deletion / Right to Erasure: Backend has `POST /api/v1/users/anonymize-data`, but the frontend settings screen needs a self-service "Delete Account & Anonymize Data" confirmation flow.

---

## 5. Phased Implementation Roadmap

### Phase 1: Audit & Foundation (This Step)
- Create `docs/USER_DRIVER_UX_AUDIT.md`.
- Detail current state, endpoints, models, and gaps.

### Phase 2: Backend Driver Onboarding & Gating Enforcement
- Add `POST /api/v1/users/driver-application`: Accepts `licenseNumber`, `licenseDocUrl`, `idDocUrl`, sets `driverProfile.onboardingStatus = 'submitted'`.
- Add `GET /api/v1/users/driver-status`: Returns live driver application status, rejection reason, verified timestamp.
- Update `createRide` in `backend/src/controllers/rideController.js`: Enforce that `req.user.capabilities?.canDrive === true && req.user.driverProfile?.onboardingStatus === 'approved'`. Reject with `403 Forbidden` if not approved.
- Update `backend/src/controllers/vehicleController.js`: Do NOT auto-approve driver status merely because a vehicle is created. Vehicle creation registers the vehicle; driver approval requires document review.

### Phase 3: Frontend Driver Onboarding Flow
- Create `DriverOnboardingScreen` (`/driver-onboarding`) in `features/profile/presentation/screens/driver_onboarding_screen.dart`:
  - Visual timeline: Identity Verification -> Driving Licence -> Vehicle Linking -> Admin Review.
  - Form validation for 15-character Indian DL number format (`SS-RRYYYYNNNNNNN` or standard alphanumeric).
  - Document placeholder / image picker simulation.
  - Status tracking banner for pending and rejected states.

### Phase 4: Offer Ride Eligibility Interceptor
- In `offer_ride_screen.dart`:
  - Check `user.isDriverEligible`. If not eligible, display the tailored Driver Status card (Get Started, Under Review, or Rejected Action Required).
  - If approved, present the seamless 3-step wizard with active vehicle selection.

### Phase 5: Role-Aware Profile Redesign
- Redesign `profile_screen.dart`:
  - Passenger-first cleanliness: Passenger rides, travel preferences, emergency contacts, saved places.
  - Driver status banner according to live state (`not_started`, `submitted`, `rejected`, `approved`).
  - For approved drivers: Display fleet management, driver rides manifest, earnings overview, and mode toggle.

### Phase 6: Settings Polish & Account Management
- Add Language Preferences bottom sheet (English, Hindi, Gujarati).
- Add self-service Account Deletion / Anonymization dialog integrating `POST /api/v1/users/anonymize-data`.
- Verify terms, privacy policy, and notification preferences.

### Phase 7: Verification & Testing
- Write automated tests:
  - Backend: Driver application submission, admin verification, and strict ride-publishing authorization tests.
  - Frontend: Driver onboarding widget test, profile state test, offer-ride gating test.
- Execute `dart analyze`, `flutter test`, `npm test`, and compile an Android debug build.

---

## 6. API Endpoint Reference

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Public | Passenger registration (Name, Email, Phone, Password) |
| `POST` | `/api/v1/auth/verify-otp` | Public | Phone verification; sets `isVerified = true` |
| `GET` | `/api/v1/users/profile` | Bearer Token | Fetch authenticated profile with capabilities and driverProfile |
| `PUT` | `/api/v1/users/profile` | Bearer Token | Update Name, City, Bio, Profile Image |
| `POST` | `/api/v1/users/driver-application` | Bearer Token | Submit licence and ID documents for verification |
| `GET` | `/api/v1/users/driver-status` | Bearer Token | Check current driver onboarding and verification status |
| `POST` | `/api/v1/vehicles` | Bearer Token | Register vehicle to user fleet |
| `GET` | `/api/v1/vehicles` | Bearer Token | List all user-owned vehicles |
| `POST` | `/api/v1/rides` | Bearer Token | Publish carpool ride (Requires `canDrive && onboardingStatus == 'approved'`) |
| `POST` | `/api/v1/users/anonymize-data` | Bearer Token | DPDP/GDPR account deletion and PII erasure |
| `PATCH`| `/api/v1/admin/users/:id/verify` | Admin Token | Approve or reject driver application |
