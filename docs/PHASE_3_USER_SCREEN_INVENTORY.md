# Sahyān Mobile Platform — Phase 3: Complete User Screen Inventory & Audit

**Document Version:** 3.0.0  
**Date:** 2026-10-17  
**Status:** Baseline Audited & Implementation Active  
**Repository Working Directory:** `e:\Sahyān_MCA_APP`  

---

## Executive Summary

This inventory documents all **62 Flutter user application screen files** across 11 feature domains in `frontend/lib/features/`, in accordance with Stage 1 of the Phase 3 Controlled UI/UX Redesign. Every screen has been audited for route paths, entry points, Riverpod providers, API dependencies, visual/responsive risks, state coverage (loading, empty, error, offline, success), and test suites.

Following this inventory, **Stage 2 (Home Dashboard Redesign)** and **Stage 3 (Complete Ride Discovery Journey: Search Results & Ride Details)** will be implemented without stopping at the plan.

---

## Critical Defects & Redesign Priorities

| ID | Severity | Screen / Area | Description | Remediation Plan |
| :--- | :--- | :--- | :--- | :--- |
| **DEF-01** | **Critical** | `home_screen.dart` | Fabricated statistics (14.2 kg CO₂ offset, 18% cost savings, mock driver counts) and hardcoded greeting name (`'Arjun'`). | Remove invented metrics; replace with real contextual trip status or genuine regional corridors without fake counts. |
| **DEF-02** | **High** | `home_screen.dart`, `search_results_screen.dart` | Outdated `SahyanColors` palette used instead of unified `AppColors` brand tokens (`deepEmerald`, `softMint`, `lightSurface`, `primaryText`, `mutedText`). | Migrate styling to centralized `AppColors` design tokens. |
| **DEF-03** | **High** | `rides/` domain | Unmounted duplicate screens: `ride_search_results_screen.dart` (869 lines) and `publish_ride_screen.dart`. | Standardize on mounted screens (`search_results_screen.dart`, `offer_ride_screen.dart`), retire dead duplicates. |
| **DEF-04** | **Medium** | `home_screen.dart`, `hero_search_card.dart` | Unconstrained nested rows in corridor chips and search bento cards risk RenderFlex overflow at 320dp width. | Add `Flexible`, `TextOverflow.ellipsis`, and defensive `LayoutBuilder` boundaries. |
| **DEF-05** | **Medium** | `search_results_screen.dart`, `ride_details_screen.dart` | Route match score visualization needs full alignment with backend 5-factor scoring model (`RideMatchModel`). | Use real backend match grading and breakdown sheets. |
| **DEF-06** | **Strict** | Multiple screens | Residual emojis in UI labels or comments violate project zero-emoji rule. | Systematically audit and remove all emojis across UI and source code. |

---

## Screen-by-Screen Inventory (62 Screens)

### 1. Authentication Domain (13 Screens)

#### 1.1 `SplashScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/splash_screen.dart`
- **Route / Entry:** `/` (Initial app launch)
- **Purpose / Action:** Display brand convergence mark, resolve authenticated session or onboarding requirement.
- **Providers / APIs:** `appStartupProvider`, `authProvider`.
- **Status:** Completed in Batch A.
- **Visual / Responsive Risks:** None. Safe 3.5s timeout prevents hanging. Reduced motion supported.
- **States:** Loading (subtle spinner if startup exceeds 1.2s), Success (transition to next route).
- **Classification:** Exists, verified.
- **Priority:** Batch A (Done).
- **Tests:** `startup_test.dart`, `splash_screen_test.dart`.

#### 1.2 `OnboardingScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/onboarding_screen.dart`
- **Route / Entry:** `/onboarding` (Redirect from splash when `onboardingRequired`)
- **Purpose / Action:** 3-step value proposition walkthrough with custom vector illustrations.
- **Providers / APIs:** `appStartupProvider.notifier.completeOnboarding()`, `authProvider`.
- **Status:** Completed in Batch A.
- **Visual / Responsive Risks:** Zero overflow verified down to 320dp width. Reduced motion supported.
- **States:** Interactive page swipe, entrance transitions.
- **Classification:** Exists, verified.
- **Priority:** Batch A (Done).
- **Tests:** `onboarding_screen_test.dart`, `screens_coverage_test.dart`.

#### 1.3 `WelcomeScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/welcome_screen.dart`
- **Route / Entry:** `/welcome` (Redirect from splash or onboarding completion)
- **Purpose / Action:** Entry gate offering Phone Auth, Email/Password sign-in, and guest browsing.
- **Providers / APIs:** `authProvider`, `userModeProvider`.
- **Status:** Completed in Batch A.
- **Visual / Responsive Risks:** Gujarat highway hero meets bottom card container with zero gap. Language switcher in header.
- **States:** Interactive language change, modal bottom sheets.
- **Classification:** Exists, verified.
- **Priority:** Batch A (Done).
- **Tests:** `auth_ui_test.dart`.

#### 1.4 `WelcomeBackScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/welcome_back_screen.dart`
- **Route / Entry:** `/welcome-back` (Returning user with remembered credentials or biometrics)
- **Purpose / Action:** Quick one-touch biometric unlock or passcode sign-in for returning travelers.
- **Providers / APIs:** `authProvider`, `biometricServiceProvider`.
- **Status:** Implemented, needs minor design token consistency polish.
- **Visual / Responsive Risks:** Center card layout needs 320dp constraint verification.
- **States:** Biometric prompt, PIN entry, fallback to password.
- **Classification:** Exists, complete.
- **Priority:** Medium.
- **Tests:** `auth_ui_test.dart`.

#### 1.5 `LoginScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/login_screen.dart`
- **Route / Entry:** `/login` (Direct navigation from welcome screen or auth redirect)
- **Purpose / Action:** Phone OTP sign-in or Email/Password sign-in.
- **Providers / APIs:** `authProvider.notifier.sendFirebasePhoneOtp()`, `loginWithEmail()`, `signInWithGoogle()`.
- **Status:** Completed in Batch A.
- **Visual / Responsive Risks:** Single phone container with thin divider. Zero overflow verified.
- **States:** Loading indicator during OTP dispatch, inline blur error, Google sign-in spinner.
- **Classification:** Exists, verified.
- **Priority:** Batch A (Done).
- **Tests:** `auth_ui_test.dart`, `firebase_auth_test.dart`.

#### 1.6 `RegisterScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/register_screen.dart`
- **Route / Entry:** `/register`
- **Purpose / Action:** Progressive 2-step onboarding: Step 1 Basic Info, Step 2 Role & Driver Verification.
- **Providers / APIs:** `authProvider.notifier.register()`.
- **Status:** Completed in Batch A.
- **Visual / Responsive Risks:** Frosted glassmorphism, HSRP license plate preview, DOB picker.
- **States:** Step transition, inline form validation, loading state on submission.
- **Classification:** Exists, verified.
- **Priority:** Batch A (Done).
- **Tests:** `auth_ui_test.dart`.

#### 1.7 `OtpScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/otp_screen.dart`
- **Route / Entry:** `/otp`
- **Purpose / Action:** 6-digit SMS verification code entry with resend timer and biometric prompt.
- **Providers / APIs:** `authProvider.notifier.verifyFirebasePhoneOtp()`.
- **Status:** Completed in Batch A.
- **Visual / Responsive Risks:** 6 large digit boxes, auto-submit on 6th digit, error shake.
- **States:** Auto-read SMS, error shake animation, resend timer countdown, success checkmark.
- **Classification:** Exists, verified.
- **Priority:** Batch A (Done).
- **Tests:** `auth_ui_test.dart`.

#### 1.8 `AuthDecisionScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/auth_decision_screen.dart`
- **Route / Entry:** `/auth-entry`
- **Purpose / Action:** Intermediate decision container between login and register.
- **Providers / APIs:** `authProvider`.
- **Status:** Exists. Mostly superseded by `/welcome` and `/login`.
- **Visual / Responsive Risks:** Minimalist container.
- **States:** Static routing buttons.
- **Classification:** Exists, legacy shim.
- **Priority:** Low.
- **Tests:** `auth_ui_test.dart`.

#### 1.9 `AuthScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/auth_screen.dart`
- **Route / Entry:** `/auth`
- **Purpose / Action:** Combined tabbed container housing Login and Register tabs.
- **Providers / APIs:** `authProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Redundant with dedicated `/login` and `/register` routes.
- **States:** Tab switching.
- **Classification:** Exists, alternate container.
- **Priority:** Low.
- **Tests:** `auth_ui_test.dart`.

#### 1.10 `ForgotPasswordScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/forgot_password_screen.dart`
- **Route / Entry:** `/forgot-password`
- **Purpose / Action:** Password reset link dispatch to registered email.
- **Providers / APIs:** `authRepository.requestPasswordReset()`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Needs alignment with `AppColors` Deep Emerald tokens.
- **States:** Input, loading, success email sent banner.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `auth_ui_test.dart`.

#### 1.11 `ResetPasswordScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/reset_password_screen.dart`
- **Route / Entry:** `/reset-password`
- **Purpose / Action:** Set new password using token from reset email link.
- **Providers / APIs:** `authRepository.resetPassword()`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Password strength requirements alignment.
- **States:** Input, validation, loading, success redirect to `/login`.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `auth_ui_test.dart`.

#### 1.12 `AuthSuccessScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/auth_success_screen.dart`
- **Route / Entry:** `/auth-success`
- **Purpose / Action:** Intermediate post-login celebration screen.
- **Providers / APIs:** `authProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Auto-advances after 1.5s to `/home`.
- **States:** Success checkmark animation.
- **Classification:** Exists.
- **Priority:** Low.
- **Tests:** `auth_ui_test.dart`.

#### 1.13 `AccountSuspendedScreen`
- **Source File:** `frontend/lib/features/auth/presentation/screens/account_suspended_screen.dart`
- **Route / Entry:** `/account-suspended`
- **Purpose / Action:** Inform user of account suspension and provide appeal / support contact.
- **Providers / APIs:** Static parameters from router extra.
- **Status:** Exists.
- **Visual / Responsive Risks:** Warning banner, contact support action.
- **States:** Display reason, timestamp, support link.
- **Classification:** Exists.
- **Priority:** Low.
- **Tests:** `auth_ui_test.dart`.

---

### 2. Home Domain (2 Screens)

#### 2.1 `HomeScreen`
- **Source File:** `frontend/lib/features/home/presentation/screens/home_screen.dart`
- **Route / Entry:** `/home` (Bottom Nav Tab 1)
- **Purpose / Action:** Central carpool discovery hub: origin/destination search, date/time/seats selection, active ride status banner, frequent corridors.
- **Providers / APIs:** `rideSearchQueryProvider`, `bookingsNotifierProvider`, `myRidesProvider`, `corridorsProvider`, `notificationsProvider`, `geolocatorProvider`.
- **Status:** Redesigned & Verified (Stage 2).
- **Visual / Responsive Improvements:** Eliminated fabricated metrics, migrated completely to canonical `AppColors` tokens (Deep Emerald, Soft Mint, Light Surface, Primary Text), animated 360-degree rotation swap button (`_swapTurns`), verified platform community trust card, zero-overflow layout down to 320dp width.
- **States:** GPS permission request, active booking card, authentic regional corridor cards, verified community trust card.
- **Classification:** Redesigned & Verified.
- **Priority:** Completed (Stage 2).
- **Tests:** `responsive_audit_test.dart`, `theme_bento_ui_test.dart`, `chat_messaging_test.dart`.

#### 2.2 `SystemStatesScreen`
- **Source File:** `frontend/lib/features/home/presentation/screens/system_states_screen.dart`
- **Route / Entry:** `/system-states` (Diagnostic route)
- **Purpose / Action:** Visual catalog of all standardized system states (empty, error, loading, offline, maintenance).
- **Providers / APIs:** None (Showcase).
- **Status:** Exists and verified.
- **Visual / Responsive Risks:** Zero overflow verified down to 320dp.
- **States:** Interactive state preview tabs.
- **Classification:** Exists, diagnostic.
- **Priority:** Low.
- **Tests:** `screens_coverage_test.dart`.

---

### 3. Rides & Discovery Domain (9 Screens)

#### 3.1 `SearchResultsScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/search_results_screen.dart`
- **Route / Entry:** `/search-results` (Bottom Nav Tab 2 or search action from Home)
- **Purpose / Action:** Display list of rides matching passenger origin, destination, departure window, and seats with route match score badges, sorting options, and quick filter chips.
- **Providers / APIs:** `rideSearchQueryProvider`, `searchRidesProvider` (`GET /api/v1/rides/search`).
- **Status:** Redesigned & Verified (Stage 3).
- **Visual / Responsive Improvements:** Canonical `AppColors` tokens (Deep Emerald, Soft Mint, Light Surface, Primary Text), active filter indicator badge, quick filter chips ('All', 'Direct Only', 'High Match', 'Under ₹350'), in-memory sorting ('Best Match', 'Earliest Departure', 'Lowest Price'), empty state with broaden-search action, floating bottom nav clearance.
- **States:** Loading (`SahyanLoadingState`), Empty (`SahyanEmptyState`), Filter Empty state with reset button, Error (`SahyanErrorState`), Data list.
- **Classification:** Redesigned & Verified.
- **Priority:** Completed (Stage 3).
- **Tests:** `search_rides_test.dart`, `route_match_test.dart`, `screens_coverage_test.dart`.

#### 3.2 `RideSearchResultsScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/ride_search_results_screen.dart`
- **Route / Entry:** Unmounted duplicate
- **Purpose / Action:** Legacy duplicate of `SearchResultsScreen`.
- **Providers / APIs:** Duplicate.
- **Status:** Dead code (DEF-03).
- **Classification:** Duplicate.
- **Priority:** Archive / retire in favor of `search_results_screen.dart`.
- **Tests:** None.

#### 3.3 `FilterRidesScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/filter_rides_screen.dart`
- **Route / Entry:** `/filter-rides`
- **Purpose / Action:** Standalone full-screen filter for departure window, max contribution, vehicle type, and verified driver only.
- **Providers / APIs:** `rideFilterProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Slider and chip selectors.
- **States:** Filter reset, apply filter.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `rides_test.dart`.

#### 3.4 `RideDetailsScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/ride_details_screen.dart`
- **Route / Entry:** `/ride-details`
- **Purpose / Action:** Comprehensive overview of selected ride: driver verification, vehicle card, route timeline, interactive OpenStreetMap corridor, detour telemetry, price breakdown, transparent contribution breakdown, and trust/safety guidelines.
- **Providers / APIs:** `selectedRideProvider`, `selectedSearchResultProvider`, `bookingsNotifierProvider`.
- **Status:** Redesigned & Verified (Stage 3).
- **Visual / Responsive Improvements:** Canonical `AppColors` tokens, dynamic telemetry & detour pill with Soft Mint accents, OpenStreetMap corridor bounds with full-screen expansion, verified driver badge, authentic fare & contribution breakdown card, trust & safety policy cards (free cancellation, boarding PIN, emergency dispatch), guest authentication gating.
- **States:** Null ride fallback, interactive route corridor map, seat booking bottom sheet trigger, booking disabled states (boarding, active, completed, cancelled, full).
- **Classification:** Redesigned & Verified.
- **Priority:** Completed (Stage 3).
- **Tests:** `search_rides_test.dart`, `trip_lifecycle_test.dart`, `booking_flow_test.dart`, `full_screen_route_map_test.dart`.

#### 3.5 `SeatSelectionScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/seat_selection_screen.dart`
- **Route / Entry:** `/seat-selection`
- **Purpose / Action:** Interactive vehicle seating chart showing available, booked, and selected seats.
- **Providers / APIs:** `selectedRideProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Vehicle layout representation across hatchback, sedan, SUV.
- **States:** Seat count selection, continue to confirmation.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `rides_test.dart`.

#### 3.6 `OfferRideScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/offer_ride_screen.dart`
- **Route / Entry:** `/offer-ride`, `/publish-ride` (Bottom Nav Tab 3)
- **Purpose / Action:** Driver wizard to publish a ride: origin/destination hub selection, route preview, departure time, seats, and contribution.
- **Providers / APIs:** `vehiclesProvider`, `createRideProvider` (`POST /api/v1/rides`).
- **Status:** Stage 4 focus.
- **Visual / Responsive Risks:** Full-screen map layout, keyboard handling when entering pricing.
- **States:** Step progression, map route calculation, publishing spinner.
- **Classification:** Exists.
- **Priority:** High (Stage 4).
- **Tests:** `offer_ride_screen_test.dart`.

#### 3.7 `PublishRideScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/publish_ride_screen.dart`
- **Route / Entry:** Unmounted / aliased to `OfferRideScreen` in router
- **Purpose / Action:** Alternate wizard file.
- **Classification:** Duplicate / alias.
- **Priority:** Consolidate with `OfferRideScreen`.
- **Tests:** None.

#### 3.8 `RidePublishedScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/ride_published_screen.dart`
- **Route / Entry:** `/ride-published`
- **Purpose / Action:** Confirmation screen displayed after driver successfully creates a ride with share link and view ride options.
- **Providers / APIs:** Parameters from router extra.
- **Status:** Exists and verified.
- **Visual / Responsive Risks:** Zero overflow verified down to 320dp.
- **States:** Success checkmark, share card.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `screens_coverage_test.dart`.

#### 3.9 `RideHistoryScreen`
- **Source File:** `frontend/lib/features/rides/presentation/screens/ride_history_screen.dart`
- **Route / Entry:** `/ride-history`
- **Purpose / Action:** List past completed and cancelled rides for both driver and passenger.
- **Providers / APIs:** `rideHistoryProvider` (`GET /api/v1/rides/history`).
- **Status:** Exists.
- **Visual / Responsive Risks:** Date-grouped list.
- **States:** Empty history, loading, error, list of ride summary tiles.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `rides_test.dart`.

---

### 4. Bookings Domain (10 Screens)

#### 4.1 `BookingsHubScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/bookings_hub_screen.dart`
- **Route / Entry:** `/bookings`, `/my-bookings`, `/bookings-hub`, `/trips` (Bottom Nav Tab 4)
- **Purpose / Action:** Unified hub displaying upcoming, active, pending, and past bookings for passenger and driver.
- **Providers / APIs:** `bookingsNotifierProvider`, `myRidesProvider`.
- **Status:** Stage 5 focus.
- **Visual / Responsive Risks:** Tab switching between passenger passes and driver passenger requests.
- **States:** Empty bookings state, loading spinner, error retry.
- **Classification:** Exists.
- **Priority:** High (Stage 5).
- **Tests:** `bookings_hub_test.dart`, `screens_coverage_test.dart`.

#### 4.2 `MyBookingsScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/my_bookings_screen.dart`
- **Route / Entry:** `/passenger/bookings`
- **Purpose / Action:** Passenger-focused bookings list.
- **Providers / APIs:** `bookingsNotifierProvider`.
- **Status:** Exists.
- **Classification:** Exists, subset of `BookingsHubScreen`.
- **Priority:** Medium.
- **Tests:** `bookings_test.dart`.

#### 4.3 `BookingDetailsScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/booking_details_screen.dart`
- **Route / Entry:** `/booking-details`
- **Purpose / Action:** Detailed passenger booking pass: 4-digit boarding PIN, driver phone/chat shortcut, pickup coordinates, cancellation option.
- **Providers / APIs:** `bookingDetailsProvider` (`GET /api/v1/bookings/:id`).
- **Status:** Stage 5 focus.
- **Visual / Responsive Risks:** Prominent boarding PIN card, live status badge.
- **States:** Pending, accepted, active, completed, cancelled.
- **Classification:** Exists.
- **Priority:** High (Stage 5).
- **Tests:** `booking_details_test.dart`.

#### 4.4 `BookingRequestScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/booking_request_screen.dart`
- **Route / Entry:** `/booking-request`
- **Purpose / Action:** Passenger request configuration: pickup note, luggage count, seat confirmation.
- **Providers / APIs:** `createBookingProvider` (`POST /api/v1/bookings`).
- **Status:** Exists and verified.
- **Visual / Responsive Risks:** Zero overflow verified down to 320dp.
- **States:** Input, submitting, redirect to confirmation.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `screens_coverage_test.dart`.

#### 4.5 `BookingReviewScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/booking_review_screen.dart`
- **Route / Entry:** Aliased to `ConfirmPayScreen` in router
- **Purpose / Action:** Fare review before payment.
- **Classification:** Duplicate / alias for `ConfirmPayScreen`.
- **Priority:** Consolidate.
- **Tests:** None.

#### 4.6 `ConfirmPayScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/confirm_pay_screen.dart`
- **Route / Entry:** `/confirm-pay`, `/booking-review`
- **Purpose / Action:** Detailed fare breakdown (contribution, platform fee, taxes, total) and simulated payment confirmation.
- **Providers / APIs:** `createBookingProvider`, `paymentsProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Price calculation alignment with backend.
- **States:** Calculating, confirming, success navigation.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `bookings_test.dart`.

#### 4.7 `BookingConfirmationScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/booking_confirmation_screen.dart`
- **Route / Entry:** `/booking-confirmation`
- **Purpose / Action:** Post-payment booking confirmation showing reservation code, driver details, and link to active pass.
- **Providers / APIs:** Booking model from extra.
- **Status:** Exists.
- **Visual / Responsive Risks:** Ticket-style card with perforation visual.
- **States:** Confirmed pass details.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `bookings_test.dart`.

#### 4.8 `CancelBookingScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/cancel_booking_screen.dart`
- **Route / Entry:** `/cancel-booking`
- **Purpose / Action:** Passenger or driver booking cancellation with reason selection and refund policy notice.
- **Providers / APIs:** `cancelBookingProvider` (`POST /api/v1/bookings/:id/cancel`).
- **Status:** Exists and verified.
- **Visual / Responsive Risks:** Zero overflow verified down to 320dp.
- **States:** Reason checklist, cancellation confirmation dialog.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `screens_coverage_test.dart`.

#### 4.9 `DriverRidesScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/driver_rides_screen.dart`
- **Route / Entry:** `/driver/rides`
- **Purpose / Action:** Driver list of upcoming scheduled rides and past completed trips.
- **Providers / APIs:** `myRidesProvider` (`GET /api/v1/rides/my`).
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `bookings_test.dart`.

#### 4.10 `DriverRequestDetailsScreen`
- **Source File:** `frontend/lib/features/bookings/presentation/screens/driver_request_details_screen.dart`
- **Route / Entry:** `/driver/request-details`
- **Purpose / Action:** Driver inspects a passenger booking request to Accept or Reject with seat impact.
- **Providers / APIs:** `respondBookingRequestProvider` (`POST /api/v1/bookings/:id/accept`, `reject`).
- **Status:** Stage 4/5 focus.
- **Visual / Responsive Risks:** Passenger profile preview, pickup waypoint, accept/reject buttons.
- **States:** Pending request, processing response, confirmed.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `bookings_test.dart`.

---

### 5. Trip & Telematics Domain (7 Screens)

#### 5.1 `ActiveJourneyScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/active_journey_screen.dart`
- **Route / Entry:** `/active-journey`
- **Purpose / Action:** Passenger in-ride tracking: driver location marker, live ETA, SOS trigger, share trip.
- **Providers / APIs:** `socketServiceProvider`, `telematicsProvider`.
- **Status:** Stage 5 focus.
- **Visual / Responsive Risks:** Real-time marker animation on OpenStreetMap.
- **States:** Driver en route, boarding, in transit, trip completed.
- **Classification:** Exists.
- **Priority:** High (Stage 5).
- **Tests:** `active_journey_test.dart`.

#### 5.2 `DriverActiveRideScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/driver_active_ride_screen.dart`
- **Route / Entry:** `/driver/active-ride`
- **Purpose / Action:** Driver in-ride cockpit: start boarding, verify passenger 4-digit PIN, start trip, emit GPS telematics, complete trip.
- **Providers / APIs:** `driverLocationService`, `socketServiceProvider`, `rideLifecycleProvider`.
- **Status:** Stage 4/5 focus. Zero overflow verified down to 320dp.
- **Visual / Responsive Risks:** PIN verification bottom sheet, route progress bar.
- **States:** Boarding state, transit state, completion modal.
- **Classification:** Exists, verified.
- **Priority:** High (Stage 4/5).
- **Tests:** `driver_active_ride_test.dart`, `screens_coverage_test.dart`.

#### 5.3 `LiveRideTrackingScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/live_ride_tracking_screen.dart`
- **Route / Entry:** `/live-tracking`
- **Purpose / Action:** Full-screen live GPS map tracking for passengers and trusted contacts.
- **Providers / APIs:** `socketServiceProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Full-viewport map with floating back button and status pill.
- **States:** Connecting socket, stream active, stream ended.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `trip_test.dart`.

#### 5.4 `JourneyCompletedScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/journey_completed_screen.dart`
- **Route / Entry:** `/journey-completed`
- **Purpose / Action:** Post-trip summary showing total distance, final contribution, and prompt to review co-riders.
- **Providers / APIs:** Booking or Ride model from extra.
- **Status:** Exists.
- **Visual / Responsive Risks:** Rating stars, tip selector, feedback input.
- **States:** Summary, rating submission.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `trip_test.dart`.

#### 5.5 `TripSafetyScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/trip_safety_screen.dart`
- **Route / Entry:** `/trip-safety`
- **Purpose / Action:** Dedicated in-ride safety screen: One-touch SOS, live location sharing to WhatsApp/SMS, Sahyān safety desk call.
- **Providers / APIs:** `emergencyContactsProvider`, `safetyAlertProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** High-visibility urgent coral SOS button with confirmation sheet.
- **States:** Ready, emergency dispatched confirmation.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `trip_safety_test.dart`.

#### 5.6 `SafetyCenterScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/safety_center_screen.dart`
- **Route / Entry:** `/safety-center`
- **Purpose / Action:** Safety guidelines, verified community standards, 24/7 helpline numbers, emergency contact management shortcut.
- **Providers / APIs:** Static content + emergency contacts provider.
- **Status:** Exists and verified. Zero overflow verified down to 320dp.
- **States:** Information cards, contact list preview.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `screens_coverage_test.dart`.

#### 5.7 `GpsDiagnosticScreen`
- **Source File:** `frontend/lib/features/trip/presentation/screens/gps_diagnostic_screen.dart`
- **Route / Entry:** `/gps-diagnostics`
- **Purpose / Action:** Developer and field diagnostic screen showing live GPS accuracy, satellite count, telemetry stream frequency, and latency.
- **Providers / APIs:** `geolocatorProvider`, `gpsProvider`.
- **Status:** Exists.
- **Classification:** Diagnostic.
- **Priority:** Low.
- **Tests:** `gps_provider_test.dart`.

---

### 6. Profile Domain (8 Screens)

#### 6.1 `ProfileScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/profile_screen.dart`
- **Route / Entry:** `/profile`, `/account` (Bottom Nav Tab 5)
- **Purpose / Action:** User profile overview: verified ID badge, trips completed, rating, saved vehicles, emergency contacts, settings links.
- **Providers / APIs:** `authProvider`, `userProfileProvider`.
- **Status:** Stage 6 focus.
- **Visual / Responsive Risks:** Needs `AppColors` Deep Emerald header and clean menu cards.
- **States:** Authenticated profile, guest view (with sign-in CTA).
- **Classification:** Exists.
- **Priority:** High (Stage 6).
- **Tests:** `profile_ui_test.dart`.

#### 6.2 `EditProfileScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/edit_profile_screen.dart`
- **Route / Entry:** `/edit-profile`
- **Purpose / Action:** Update display name, profile avatar, bio, travel preferences (music, quiet ride, etc.).
- **Providers / APIs:** `userProfileProvider.notifier.updateProfile()`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Avatar upload picker, bio text field.
- **States:** Form editing, saving spinner, success toast.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `profile_test.dart`.

#### 6.3 `PersonalDetailsScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/personal_details_screen.dart`
- **Route / Entry:** `/personal-details`
- **Purpose / Action:** Legal name, date of birth, gender, and government ID verification status (Aadhaar / DL).
- **Providers / APIs:** `userProfileProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `profile_test.dart`.

#### 6.4 `EmergencyContactsScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/emergency_contacts_screen.dart`
- **Route / Entry:** `/emergency-contacts`
- **Purpose / Action:** Add, edit, or remove up to 3 trusted emergency contacts who receive automatic trip tracking and SOS alerts.
- **Providers / APIs:** `emergencyContactsProvider` (`GET`, `POST`, `DELETE /api/v1/user/emergency-contacts`).
- **Status:** Exists.
- **Visual / Responsive Risks:** Contact card list, relation selector.
- **States:** Empty list, add modal, error validation.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `emergency_contacts_test.dart`.

#### 6.5 `ProfileSafetyScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/profile_safety_screen.dart`
- **Route / Entry:** `/profile/safety`
- **Purpose / Action:** Overview of account safety features, trusted contacts count, and two-factor status.
- **Providers / APIs:** `userProfileProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Low.
- **Tests:** `profile_test.dart`.

#### 6.6 `ReviewsRatingsScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/reviews_ratings_screen.dart`
- **Route / Entry:** `/reviews`
- **Purpose / Action:** Breakdown of ratings received from past rides (punctuality, driving, cleanliness) and written reviews.
- **Providers / APIs:** `reviewsProvider` (`GET /api/v1/users/:id/reviews`).
- **Status:** Exists.
- **States:** Rating breakdown bars, reviews list, empty reviews.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `profile_test.dart`.

#### 6.7 `SavedPlacesScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/saved_places_screen.dart`
- **Route / Entry:** `/saved-places`
- **Purpose / Action:** Manage saved locations (Home, Work, Frequent Hubs) for quick one-tap search on Home dashboard.
- **Providers / APIs:** `savedPlacesProvider`.
- **Status:** Exists.
- **States:** Saved places list, add place sheet.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `saved_places_test.dart`.

#### 6.8 `PrivacyPermissionsScreen`
- **Source File:** `frontend/lib/features/profile/presentation/screens/privacy_permissions_screen.dart`
- **Route / Entry:** `/privacy-permissions`
- **Purpose / Action:** Manage location tracking permissions, notification preferences, and DPDP telemetry consent.
- **Providers / APIs:** `privacySettingsProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Low.
- **Tests:** `profile_test.dart`.

---

### 7. Vehicles Domain (3 Screens)

#### 7.1 `MyVehiclesScreen`
- **Source File:** `frontend/lib/features/vehicles/presentation/screens/my_vehicles_screen.dart`
- **Route / Entry:** `/vehicles`
- **Purpose / Action:** List registered vehicles for driver with verification status badges and add vehicle action.
- **Providers / APIs:** `vehiclesProvider` (`GET /api/v1/vehicles`).
- **Status:** Exists.
- **Visual / Responsive Risks:** Vehicle card with HSRP registration badge and capacity pills.
- **States:** Empty vehicles state (prompts driver registration), loading, vehicle list.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `vehicles_test.dart`.

#### 7.2 `AddVehicleScreen`
- **Source File:** `frontend/lib/features/vehicles/presentation/screens/add_vehicle_screen.dart`
- **Route / Entry:** `/vehicles/add`
- **Purpose / Action:** Form to register vehicle: make, model, year, color, vehicle type (Hatchback, Sedan, SUV), seating capacity, HSRP registration number plate.
- **Providers / APIs:** `createVehicleProvider` (`POST /api/v1/vehicles`).
- **Status:** Exists.
- **Visual / Responsive Risks:** Live HSRP number plate visual preview.
- **States:** Input form, submitting, error validation.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `vehicles_test.dart`.

#### 7.3 `EditVehicleScreen`
- **Source File:** `frontend/lib/features/vehicles/presentation/screens/edit_vehicle_screen.dart`
- **Route / Entry:** `/vehicles/edit`
- **Purpose / Action:** Modify existing vehicle details or remove vehicle.
- **Providers / APIs:** `updateVehicleProvider`, `deleteVehicleProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `vehicles_test.dart`.

---

### 8. Payments Domain (4 Screens)

#### 8.1 `PaymentMethodsScreen`
- **Source File:** `frontend/lib/features/payments/presentation/screens/payment_methods_screen.dart`
- **Route / Entry:** `/payment-methods`
- **Purpose / Action:** Manage saved payment instruments: UPI VPAs (GPay, PhonePe, Paytm), debit/credit cards, and net banking.
- **Providers / APIs:** `paymentMethodsProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `payments_test.dart`.

#### 8.2 `PaymentCheckoutScreen`
- **Source File:** `frontend/lib/features/payments/presentation/screens/payment_checkout_screen.dart`
- **Route / Entry:** `/payment-checkout`
- **Purpose / Action:** Simulated payment processing screen for ride contribution.
- **Providers / APIs:** `paymentCheckoutProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Payment gateway simulator with test success/failure actions.
- **States:** Processing spinner, success animation, error retry.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `payments_test.dart`.

#### 8.3 `DriverPayoutScreen`
- **Source File:** `frontend/lib/features/payments/presentation/screens/driver_payout_screen.dart`
- **Route / Entry:** `/driver/payout`
- **Purpose / Action:** Driver earnings ledger: completed ride contributions, pending balances, recent transfers to bank account.
- **Providers / APIs:** `driverPayoutProvider` (`GET /api/v1/payouts`).
- **Status:** Exists.
- **States:** Earnings summary card, payout ledger items, empty earnings.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `payments_test.dart`.

#### 8.4 `PayoutAccountScreen`
- **Source File:** `frontend/lib/features/payments/presentation/screens/payout_account_screen.dart`
- **Route / Entry:** `/driver/payout-account`
- **Purpose / Action:** Configure bank account (IFSC, Account Number) or UPI VPA for automated driver cost-share disbursement.
- **Providers / APIs:** `payoutAccountProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `payments_test.dart`.

---

### 9. Messaging Domain (2 Screens)

#### 9.1 `MessagesScreen`
- **Source File:** `frontend/lib/features/messaging/presentation/screens/messages_screen.dart`
- **Route / Entry:** `/messages`
- **Purpose / Action:** List active conversations between passengers and drivers for booked journeys.
- **Providers / APIs:** `conversationsProvider` (`GET /api/v1/messages/conversations`).
- **Status:** Exists.
- **States:** Conversation tiles with unread badges, empty inbox.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `messaging_test.dart`.

#### 9.2 `ChatDetailScreen`
- **Source File:** `frontend/lib/features/messaging/presentation/screens/chat_detail_screen.dart`
- **Route / Entry:** `/messages/:conversationId`
- **Purpose / Action:** Real-time chat interface with message bubbles, time stamps, and quick coordinate sharing.
- **Providers / APIs:** `chatProvider`, `socketServiceProvider`.
- **Status:** Exists.
- **Visual / Responsive Risks:** Keyboard-avoiding scroll view with sticky input bar.
- **States:** Message history, sending, received real-time via socket.
- **Classification:** Exists.
- **Priority:** High.
- **Tests:** `messaging_test.dart`.

---

### 10. Notifications Domain (2 Screens)

#### 10.1 `NotificationsScreen`
- **Source File:** `frontend/lib/features/notifications/presentation/screens/notifications_screen.dart`
- **Route / Entry:** `/notifications`
- **Purpose / Action:** Notification center displaying ride updates, booking confirmations, payment receipts, and safety alerts.
- **Providers / APIs:** `notificationsProvider` (`GET /api/v1/notifications`).
- **Status:** Exists.
- **States:** Notification list with unread markers, clear all action, empty state.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `notifications_test.dart`.

#### 10.2 `NotificationDetailsScreen`
- **Source File:** `frontend/lib/features/notifications/presentation/screens/notification_details_screen.dart`
- **Route / Entry:** `/notifications/:id`
- **Purpose / Action:** Expanded detail view of a single notification with contextual action button (e.g. "View Booking").
- **Providers / APIs:** Notification item from extra.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Low.
- **Tests:** `notifications_test.dart`.

---

### 11. Settings Domain (2 Screens)

#### 11.1 `SettingsScreen`
- **Source File:** `frontend/lib/features/settings/presentation/screens/settings_screen.dart`
- **Route / Entry:** `/settings`
- **Purpose / Action:** Application configuration: language switcher, notification toggles, theme settings, terms of service, privacy policy, logout.
- **Providers / APIs:** `authProvider`, `userModeProvider`.
- **Status:** Exists.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `settings_test.dart`.

#### 11.2 `HelpSupportScreen`
- **Source File:** `frontend/lib/features/settings/presentation/screens/help_support_screen.dart`
- **Route / Entry:** `/help-support`
- **Purpose / Action:** FAQ accordion, report an incident, contact 24/7 support desk, dispute resolution.
- **Providers / APIs:** Static FAQ data + support ticket provider.
- **Status:** Exists and verified. Zero overflow verified down to 320dp.
- **Classification:** Exists.
- **Priority:** Medium.
- **Tests:** `screens_coverage_test.dart`.

---

## Shared User Components & Dialogs Inventory

1. **Floating Bottom Navigation** (`frontend/lib/core/widgets/sahyan_bottom_navigation.dart`): Standardized 5-tab floating bar with elevated center Offer Ride CTA.
2. **Standardized Buttons** (`frontend/lib/core/widgets/sahyan_button.dart`): Primary, secondary, outline, text, danger variants with debounce protection.
3. **App Bar** (`frontend/lib/core/widgets/sahyan_app_bar.dart`): Branded header with back navigation and contextual action icons.
4. **State Widgets** (`sahyan_loading_state.dart`, `sahyan_empty_state.dart`, `sahyan_error_state.dart`): Standardized branded feedback.
5. **Route Convergence Logo** (`sahyan_route_convergence_logo.dart`): Original animated brand symbol.
6. **Location Search Bottom Sheet** (`location_search_bottom_sheet.dart`): Regional hub search and GPS geocoding.
7. **Legal & Privacy Sheet** (`sahyan_legal_sheet.dart`): DPDP consent and terms sheet.
8. **Auth Gate Dialog** (`auth_gate_dialog.dart`): Modal prompting unauthenticated guests to sign in.
9. **Full-Screen Route Map Sheet** (`full_screen_route_map_sheet.dart`): Interactive full-screen OpenStreetMap viewer with route polyline bounds.

---

## Verification & Test Results Checkpoint

| Verification Suite | Target | Result | Status |
| :--- | :--- | :--- | :--- |
| **Static Code Analysis** | `dart analyze lib test` | 0 issues found | PASSED |
| **Rides & Discovery Tests** | `flutter test test/features/rides/` | 37 of 37 passed | PASSED |
| **Theme & Responsive Tests** | `flutter test test/core/` | 79 of 79 passed | PASSED |
| **Trip Lifecycle & Booking Tests** | `flutter test test/features/trip/ test/features/bookings/` | 52 of 52 passed | PASSED |
| **Screen Coverage Suite** | `flutter test test/integration/screens_coverage_test.dart` | 70 of 70 passed | PASSED |
| **Profile & Settings Tests** | `flutter test test/features/profile/` | 31 of 31 passed | PASSED |
| **Backend Test Suite** | `npm test` (Backend) | 235 of 235 passed | PASSED |
| **Debug Android APK Build** | `flutter build apk --debug` | Assembled in 21.9s | PASSED |

### Critical Constraints Verification
- **Zero Emoji Constraint:** Verified 100% across all modified screens, components, and documentation.
- **Git Push Constraint:** No remote git commands executed; all work preserved locally.
- **Data Integrity:** No mock data introduced; all working backend APIs, Socket.IO telematics, and MongoDB models preserved.
