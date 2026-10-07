# Sahyān UI/UX Master Redesign Plan

**Document Version:** 1.0.0  
**Date:** 2026-10-07  
**Status:** Awaiting User Approval (Approval Gate 1)  
**Specification Reference:** [UI_UX_MASTER_SAHYAN.md](file:///e:/Sahy%C4%81n_MCA_APP/docs/UI_UX_MASTER_SAHYAN.md)  
**Repository Working Directory:** `e:\Sahyān_MCA_APP`  

---

## Executive Summary

This document establishes the comprehensive audit, structural analysis, and phased implementation blueprint for the master UI/UX redesign of **Sahyān** (Intelligent Route-Based Carpooling Platform), strictly adhering to the 75 sections of `UI_UX_MASTER_SAHYAN.md`.

In accordance with **Section 73 (First Action)** and **Section 74 (First User Approval Gate)**:
1. No destructive cleanup or breaking modifications are executed during the audit.
2. The zero-emoji policy is strictly enforced across all code, assets, UI labels, and commit messages.
3. The zero-cost map policy is strictly preserved (OSRM + OpenStreetMap via `flutter_map`, zero billing dependencies).
4. All existing 367 frontend tests and 203 backend tests will be maintained in a passing state throughout each migration batch.

---

## 1. Current Screen Inventory (60 Screens)

The repository currently contains 60 Dart screen files across 11 feature domains in `frontend/lib/features/`:

| # | Feature Domain | Screen File | Class Name | Router Mount Path |
|---|----------------|-------------|------------|-------------------|
| 1 | Admin | `admin_dashboard_screen.dart` | `AdminDashboardScreen` | `/admin` |
| 2 | Auth | `splash_screen.dart` | `SplashScreen` | `/` |
| 3 | Auth | `onboarding_screen.dart` | `OnboardingScreen` | `/onboarding` |
| 4 | Auth | `auth_decision_screen.dart` | `AuthDecisionScreen` | `/auth-entry` |
| 5 | Auth | `welcome_screen.dart` | `WelcomeScreen` | `/welcome` |
| 6 | Auth | `login_screen.dart` | `LoginScreen` | `/login` |
| 7 | Auth | `auth_screen.dart` | `AuthScreen` | `/auth` |
| 8 | Auth | `register_screen.dart` | `RegisterScreen` | `/register` |
| 9 | Auth | `forgot_password_screen.dart` | `ForgotPasswordScreen` | `/forgot-password` |
| 10 | Auth | `reset_password_screen.dart` | `ResetPasswordScreen` | `/reset-password` |
| 11 | Auth | `otp_screen.dart` | `OtpScreen` | `/otp` |
| 12 | Auth | `auth_success_screen.dart` | `AuthSuccessScreen` | `/auth-success` |
| 13 | Bookings | `bookings_hub_screen.dart` | `BookingsHubScreen` | Shell Tab 4 (`/bookings`, `/my-bookings`, `/bookings-hub`) |
| 14 | Bookings | `my_bookings_screen.dart` | `MyBookingsScreen` | `/passenger/bookings` (Legacy) |
| 15 | Bookings | `booking_confirmation_screen.dart` | `BookingConfirmationScreen` | `/booking-confirmation` |
| 16 | Bookings | `booking_details_screen.dart` | `BookingDetailsScreen` | `/booking-details` |
| 17 | Bookings | `booking_request_screen.dart` | `BookingRequestScreen` | `/booking-request` |
| 18 | Bookings | `booking_review_screen.dart` | `BookingReviewScreen` | Replaced by `ConfirmPayScreen` in router |
| 19 | Bookings | `confirm_pay_screen.dart` | `ConfirmPayScreen` | `/confirm-pay`, `/booking-review` |
| 20 | Bookings | `cancel_booking_screen.dart` | `CancelBookingScreen` | `/cancel-booking` |
| 21 | Bookings | `driver_rides_screen.dart` | `DriverRidesScreen` | `/driver/rides` |
| 22 | Bookings | `driver_request_details_screen.dart` | `DriverRequestDetailsScreen` | `/driver/request-details` |
| 23 | Home | `home_screen.dart` | `HomeScreen` | Shell Tab 1 (`/home`) |
| 24 | Home | `system_states_screen.dart` | `SystemStatesScreen` | `/system-states` (Diagnostic) |
| 25 | Messaging | `messages_screen.dart` | `MessagesScreen` | `/messages` |
| 26 | Messaging | `chat_detail_screen.dart` | `ChatDetailScreen` | `/messages/:conversationId` |
| 27 | Notifications | `notifications_screen.dart` | `NotificationsScreen` | `/notifications` |
| 28 | Notifications | `notification_details_screen.dart` | `NotificationDetailsScreen` | `/notifications/:id` |
| 29 | Payments | `payment_checkout_screen.dart` | `PaymentCheckoutScreen` | `/payment-checkout` |
| 30 | Payments | `payment_methods_screen.dart` | `PaymentMethodsScreen` | `/payment-methods` |
| 31 | Payments | `driver_payout_screen.dart` | `DriverPayoutScreen` | `/driver/payout` |
| 32 | Payments | `payout_account_screen.dart` | `PayoutAccountScreen` | `/driver/payout-account` |
| 33 | Profile | `profile_screen.dart` | `ProfileScreen` | Shell Tab 5 (`/profile`) |
| 34 | Profile | `edit_profile_screen.dart` | `EditProfileScreen` | `/edit-profile` |
| 35 | Profile | `personal_details_screen.dart` | `PersonalDetailsScreen` | `/personal-details` |
| 36 | Profile | `emergency_contacts_screen.dart` | `EmergencyContactsScreen` | `/emergency-contacts` |
| 37 | Profile | `profile_safety_screen.dart` | `ProfileSafetyScreen` | `/profile/safety` |
| 38 | Profile | `reviews_ratings_screen.dart` | `ReviewsRatingsScreen` | `/reviews` |
| 39 | Profile | `saved_places_screen.dart` | `SavedPlacesScreen` | `/saved-places` |
| 40 | Rides | `search_results_screen.dart` | `SearchResultsScreen` | Shell Tab 2 (`/search-results`) |
| 41 | Rides | `ride_search_results_screen.dart` | `RideSearchResultsScreen` | Unmounted duplicate (869 lines) |
| 42 | Rides | `filter_rides_screen.dart` | `FilterRidesScreen` | `/filter-rides` |
| 43 | Rides | `offer_ride_screen.dart` | `OfferRideScreen` | Unmounted duplicate / export shim (1577 lines) |
| 44 | Rides | `publish_ride_screen.dart` | `PublishRideScreen` | Shell Tab 3 (`/offer-ride`, `/publish-ride`) |
| 45 | Rides | `ride_details_screen.dart` | `RideDetailsScreen` | `/ride-details` |
| 46 | Rides | `seat_selection_screen.dart` | `SeatSelectionScreen` | `/seat-selection` |
| 47 | Rides | `ride_published_screen.dart` | `RidePublishedScreen` | `/ride-published` |
| 48 | Rides | `ride_history_screen.dart` | `RideHistoryScreen` | `/ride-history` |
| 49 | Settings | `settings_screen.dart` | `SettingsScreen` | `/settings` |
| 50 | Settings | `help_support_screen.dart` | `HelpSupportScreen` | `/help-support` |
| 51 | Trip | `active_journey_screen.dart` | `ActiveJourneyScreen` | `/active-journey` |
| 52 | Trip | `driver_active_ride_screen.dart` | `DriverActiveRideScreen` | `/driver/active-ride` |
| 53 | Trip | `journey_completed_screen.dart` | `JourneyCompletedScreen` | `/journey-completed` |
| 54 | Trip | `live_ride_tracking_screen.dart` | `LiveRideTrackingScreen` | `/live-tracking` |
| 55 | Trip | `trip_safety_screen.dart` | `TripSafetyScreen` | `/trip-safety` |
| 56 | Trip | `safety_center_screen.dart` | `SafetyCenterScreen` | `/safety-center` |
| 57 | Trip | `gps_diagnostic_screen.dart` | `GpsDiagnosticScreen` | `/gps-diagnostics` (Diagnostic) |
| 58 | Vehicles | `my_vehicles_screen.dart` | `MyVehiclesScreen` | `/vehicles` |
| 59 | Vehicles | `add_vehicle_screen.dart` | `AddVehicleScreen` | `/vehicles/add` |
| 60 | Vehicles | `edit_vehicle_screen.dart` | `EditVehicleScreen` | `/vehicles/edit` |

---

## 2. Current Router Inventory

The application uses GoRouter defined in `frontend/lib/app/router/app_router.dart`:

### A. Root Stack Routes (Direct Modals / Non-Shell Screens)
- `/`: `SplashScreen`
- `/onboarding`: `OnboardingScreen`
- `/auth-entry`: `AuthDecisionScreen`
- `/welcome`: `WelcomeScreen`
- `/login`: `LoginScreen`
- `/auth`: `AuthScreen`
- `/register`: `RegisterScreen`
- `/forgot-password`: `ForgotPasswordScreen`
- `/reset-password`: `ResetPasswordScreen`
- `/otp`: `OtpScreen`
- `/edit-profile`: `EditProfileScreen`
- `/emergency-contacts`: `EmergencyContactsScreen`
- `/vehicles`: `MyVehiclesScreen`
- `/vehicles/add`: `AddVehicleScreen`
- `/vehicles/edit`: `EditVehicleScreen`
- `/ride-details`: `RideDetailsScreen`
- `/seat-selection`: `SeatSelectionScreen`
- `/confirm-pay`: `ConfirmPayScreen`
- `/booking-review`: `ConfirmPayScreen` (Alias)
- `/booking-confirmation`: `BookingConfirmationScreen`
- `/passenger/bookings`: `MyBookingsScreen` (Legacy alias outside Shell)
- `/booking-details`: `BookingDetailsScreen`
- `/driver/rides`: `DriverRidesScreen`
- `/driver/request-details`: `DriverRequestDetailsScreen`
- `/notifications`: `NotificationsScreen`
- `/notifications/:id`: `NotificationDetailsScreen`
- `/messages`: `MessagesScreen`
- `/messages/:conversationId`: `ChatDetailScreen`
- `/active-journey`: `ActiveJourneyScreen`
- `/journey-completed`: `JourneyCompletedScreen` (Duplicate route entry at lines 197 & 298)
- `/trip-safety`: `TripSafetyScreen`
- `/live-tracking`: `LiveRideTrackingScreen`
- `/settings`: `SettingsScreen`
- `/saved-places`: `SavedPlacesScreen`
- `/ride-history`: `RideHistoryScreen`
- `/reviews`: `ReviewsRatingsScreen`
- `/payment-methods`: `PaymentMethodsScreen`
- `/payment-checkout`: `PaymentCheckoutScreen`
- `/driver/payout`: `DriverPayoutScreen`
- `/driver/payout-account`: `PayoutAccountScreen`
- `/auth-success`: `AuthSuccessScreen`
- `/personal-details`: `PersonalDetailsScreen`
- `/filter-rides`: `FilterRidesScreen`
- `/booking-request`: `BookingRequestScreen`
- `/cancel-booking`: `CancelBookingScreen`
- `/ride-published`: `RidePublishedScreen`
- `/driver/active-ride`: `DriverActiveRideScreen`
- `/safety-center`: `SafetyCenterScreen`
- `/help-support`: `HelpSupportScreen`
- `/system-states`: `SystemStatesScreen` (Developer diagnostics)
- `/gps-diagnostics`: `GpsDiagnosticScreen` (Developer diagnostics)
- `/admin`: `AdminDashboardScreen`

### B. Stateful Shell Route (`AppShell`)
- **Branch 0 (Home):** `/home` -> `HomeScreen`
- **Branch 1 (Search / Rides):** `/search-results` -> `SearchResultsScreen`
- **Branch 2 (Offer Ride):** `/offer-ride` & `/publish-ride` -> `PublishRideScreen`
- **Branch 3 (Bookings):** `/bookings`, `/my-bookings`, `/bookings-hub` -> `BookingsHubScreen`
- **Branch 4 (Profile):** `/profile` -> `ProfileScreen`, `/profile/safety` -> `ProfileSafetyScreen`

---

## 3. Current Component Inventory

### Core Widgets (`frontend/lib/core/widgets/`):
1. `sahyan_app_bar.dart`: Standardized top navigation bar with brand styling.
2. `sahyan_avatar.dart`: User profile avatar with initials / image fallback.
3. `sahyan_bottom_navigation.dart`: 5-tab floating/docked bottom navigation bar.
4. `sahyan_button.dart`: Design system button with primary, secondary, outline, text variants.
5. `sahyan_card.dart`: Elevated/outlined card component.
6. `sahyan_chip.dart`: Filter & category pill chip.
7. `sahyan_empty_state.dart`: Standardized zero-data display.
8. `sahyan_error_state.dart`: Error state with retry action.
9. `sahyan_loading_state.dart`: Shimmer / spinner loading indicator.
10. `sahyan_match_score_badge.dart`: Circular / pill Match Score indicator.
11. `sahyan_primary_cta.dart`: Prominent bottom sticky call-to-action bar.
12. `sahyan_section_header.dart`: Section header with title, subtitle, action link.
13. `sahyan_status_badge.dart`: Trip / booking status pill (Confirmed, Active, Pending, Cancelled).
14. `sahyan_text_field.dart`: Design system text input with floating label, prefix/suffix icons.
15. `app_text_field.dart`: Legacy text input with duplicate styling.
16. `primary_button.dart`: Legacy button variant.
17. `secondary_button.dart`: Legacy button variant.
18. `rating_display.dart`: Star rating display widget.
19. `seat_selector.dart`: Interactive seat picker widget.
20. `verification_badge.dart`: Driver/user verification badge (CNIC, phone, vehicle).
21. `vehicles/vehicle_icon.dart`: Vehicle type icon (Sedan, Hatchback, SUV, Bike).
22. `vehicles/vehicle_map_marker_service.dart`: Map marker generator for vehicles.
23. `vehicles/vehicle_painters.dart`: Custom vector painters for vehicle silhouettes.
24. `design_system.dart`: Barrel export file for core widgets.

### Shared Widgets (`frontend/lib/shared/widgets/`):
1. `app_shell.dart`: Scaffold shell containing bottom navigation bar and page transitions.
2. `sahyan_logo.dart`: Production SVG / vector Sahyān logo (Icon, Lockup, Wordmark variants).
3. `sahyan_route_map.dart`: Free OSRM/OpenStreetMap route map widget using `flutter_map`.
4. `sayan_route_map.dart`: Legacy spelling shim exporting `sahyan_route_map.dart`.
5. `ride_card.dart`: Search result / ride listing card.
6. `full_screen_route_map_sheet.dart`: Expandable interactive route inspection sheet.
7. `auth_gate_dialog.dart`: Authentication challenge modal for guest users.
8. `offline_banner.dart`: Connectivity warning banner.
9. `bento/bento_container.dart`: Luxury bento surface container.
10. `bento/bento_widgets.dart`: Bento system export barrel.
11. `bento/corridor_line.dart`: Origin-to-destination vertical dashed corridor indicator.
12. `bento/pill_tag.dart`: Bento tag badge.
13. `bento/segmented_pill_bar.dart`: Segmented tab pill selector.
14. `bento/step_counter.dart`: Numeric step counter badge.

---

## 4. Duplicate Components

| Duplication Group | Canonical Component | Duplicate Component(s) | Impact / Action |
|-------------------|---------------------|------------------------|-----------------|
| Text Fields | `core/widgets/sahyan_text_field.dart` | `core/widgets/app_text_field.dart` | Consolidate callers to `sahyan_text_field.dart`; delete `app_text_field.dart` in Batch 10. |
| Buttons | `core/widgets/sahyan_button.dart` | `core/widgets/primary_button.dart`, `secondary_button.dart` | Consolidate callers to `sahyan_button.dart`; retain shims until Batch 10. |
| Route Map | `shared/widgets/sahyan_route_map.dart` | `shared/widgets/sayan_route_map.dart` | 4-line legacy shim. Retain until all imports updated, remove in Batch 10. |
| Theme Defs | `app/theme/app_theme.dart` & `app_colors.dart` | `core/theme/app_theme.dart` | `app/theme/` is the canonical design system. `core/theme/app_theme.dart` should be phased into `app/theme/`. |

---

## 5. Duplicate Screens

| Redundant Screen | Canonical Screen | Current Status & Details | Action |
|------------------|------------------|--------------------------|--------|
| `features/rides/presentation/screens/offer_ride_screen.dart` (1577 lines) | `features/rides/presentation/screens/publish_ride_screen.dart` | `offer_ride_screen.dart` defines an older multi-step form but exports `publish_ride_screen.dart`. Tested in `offer_ride_test.dart`. | Reconcile features into `publish_ride_screen.dart`, update tests to target `PublishRideScreen`, remove duplicate. |
| `features/rides/presentation/screens/ride_search_results_screen.dart` (869 lines) | `features/rides/presentation/screens/search_results_screen.dart` | Unmounted duplicate in router. Not tested. | Delete in cleanup batch. |
| `features/bookings/presentation/screens/my_bookings_screen.dart` | `features/bookings/presentation/screens/bookings_hub_screen.dart` | Mounted at `/passenger/bookings`. `BookingsHubScreen` is mounted in Shell Tab 4. | Unify into `BookingsHubScreen`, preserve route alias or redirect. |
| `features/bookings/presentation/screens/booking_review_screen.dart` | `features/bookings/presentation/screens/confirm_pay_screen.dart` | Router points `/booking-review` to `ConfirmPayScreen`. | Retain `ConfirmPayScreen` as canonical. |

---

## 6. Obsolete Files

1. `frontend/lib/features/rides/presentation/screens/ride_search_results_screen.dart`: Dead code, unreferenced in router.
2. `frontend/lib/shared/widgets/sayan_route_map.dart`: Misspelled legacy redirect shim.
3. `frontend/lib/core/widgets/primary_button.dart`: Superseded by `sahyan_button.dart`.
4. `frontend/lib/core/widgets/secondary_button.dart`: Superseded by `sahyan_button.dart`.
5. `frontend/lib/core/widgets/app_text_field.dart`: Superseded by `sahyan_text_field.dart`.

*Note: In accordance with Section 73, no file will be deleted until Batch 10 after all references and tests are updated.*

---

## 7. Theme Inconsistencies

1. **Dual Theme Locations:** `core/theme/app_theme.dart` defines `SahyanColors`, while `app/theme/app_colors.dart` re-wraps it. All design tokens will be centralized exclusively in `frontend/lib/app/theme/`.
2. **Hardcoded Color Literals:** Older screens (such as `login_screen.dart`, `register_screen.dart`, `edit_profile_screen.dart`) contain hardcoded `Color(0xFF...)` values instead of theme tokens.
3. **Typography Divergence:** Typography is inconsistently referenced between `AppTypography`, `TextTheme`, and ad-hoc `TextStyle()`. All text must use `Plus Jakarta Sans` via `AppTypography` tokens.
4. **Border Radii & Elevation:** Ad-hoc `BorderRadius.circular(12)` vs `AppRadii.card` (20px) and varying shadow elevations.

---

## 8. Screens Requiring Complete Redesign (Batch 1 - 5 Focus)

These screens form the core customer journey and will be redesigned to faithfully match the reference visual language:

1. **`home_screen.dart` (Batch 1):** Full-bleed hero banner, search pill bar, quick stats, active ride corridor card, recent searches, and recommended rides.
2. **`search_results_screen.dart` (Batch 2):** Route overview header with mini corridor map, filter chips, luxury bento ride cards with Match Score badges.
3. **`filter_rides_screen.dart` (Batch 2):** Detour slider, time window picker, vehicle type selector, price range, driver rating filter.
4. **`ride_details_screen.dart` (Batch 3):** Full corridor route geometry sheet, explainable Match Score breakdown drawer/card, driver verification badges, vehicle details, seat availability visualizer.
5. **`seat_selection_screen.dart` (Batch 4):** Vehicle seat layout diagram, seat tier pricing, luggage allowance indicator.
6. **`confirm_pay_screen.dart` (Batch 4):** Fare breakdown, eco-savings footprint, payment method selection, driver note input.
7. **`booking_confirmation_screen.dart` (Batch 4):** Success animation, boarding pass card, calendar sync CTA, live tracking CTA.
8. **`publish_ride_screen.dart` (Batch 5):** Multi-step intuitive route publisher with interactive waypoint selection, schedule picker, pricing recommendation slider, instant vs approval booking toggle.
9. **`active_journey_screen.dart` & `live_ride_tracking_screen.dart` (Batch 7):** Live OSRM polyline, real-time vehicle marker, upcoming stop banner, emergency SOS drawer, shared tracking link.
10. **`profile_screen.dart` (Batch 8):** Modern user profile header, verification trust badges, carbon saved meter, rides completed, rating breakdown, quick settings links.

---

## 9. Screens Requiring Partial Redesign

These screens retain their core layout and Riverpod state controllers but receive design-system visual upgrades (cards, typography, colors, padding):

1. `splash_screen.dart` & `onboarding_screen.dart` (Clean brand presentation)
2. `login_screen.dart`, `register_screen.dart`, `otp_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`
3. `bookings_hub_screen.dart`, `booking_details_screen.dart`, `driver_request_details_screen.dart`
4. `driver_rides_screen.dart`, `driver_active_ride_screen.dart`
5. `safety_center_screen.dart`, `trip_safety_screen.dart`
6. `my_vehicles_screen.dart`, `add_vehicle_screen.dart`, `edit_vehicle_screen.dart`
7. `emergency_contacts_screen.dart`, `saved_places_screen.dart`, `reviews_ratings_screen.dart`, `personal_details_screen.dart`, `edit_profile_screen.dart`
8. `messages_screen.dart`, `chat_detail_screen.dart`
9. `notifications_screen.dart`, `notification_details_screen.dart`
10. `payment_methods_screen.dart`, `payment_checkout_screen.dart`, `driver_payout_screen.dart`, `payout_account_screen.dart`
11. `settings_screen.dart`, `help_support_screen.dart`

---

## 10. Screens Remaining Mostly Unchanged

These screens are internal, administrative, or diagnostic tools:
1. `admin_dashboard_screen.dart` (Internal admin console)
2. `system_states_screen.dart` (Developer diagnostics)
3. `gps_diagnostic_screen.dart` (GPS telemetry diagnostics)
4. `auth_decision_screen.dart` & `auth_success_screen.dart` (Routing shims)

---

## 11. Target Folder Structure

```
frontend/lib/
├── app/
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       ├── app_colors.dart         # Canonical Color Tokens
│       ├── app_elevation.dart      # Standard Shadows & Elevations
│       ├── app_radii.dart          # Standard Border Radii
│       ├── app_spacing.dart        # 4px/8px Spatial Scale Tokens
│       ├── app_theme.dart          # Material 3 ThemeData
│       └── app_typography.dart     # Plus Jakarta Sans TextTheme
├── core/
│   ├── services/                   # OSRM, Geocoding, Telemetry, Storage
│   └── widgets/                    # Canonical Core UI Library
│       ├── design_system.dart
│       ├── sahyan_app_bar.dart
│       ├── sahyan_avatar.dart
│       ├── sahyan_bottom_navigation.dart
│       ├── sahyan_button.dart
│       ├── sahyan_card.dart
│       ├── sahyan_chip.dart
│       ├── sahyan_empty_state.dart
│       ├── sahyan_error_state.dart
│       ├── sahyan_loading_state.dart
│       ├── sahyan_match_score_badge.dart
│       ├── sahyan_primary_cta.dart
│       ├── sahyan_section_header.dart
│       ├── sahyan_status_badge.dart
│       ├── sahyan_text_field.dart
│       └── vehicles/
├── features/                       # Feature Modules (Clean Architecture)
└── shared/
    ├── models/
    └── widgets/
        ├── app_shell.dart
        ├── sahyan_logo.dart
        ├── sahyan_route_map.dart
        └── bento/
```

---

## 12. Target Component Architecture

All interactive and visual components will strictly follow the unified design tokens:

1. **Card Language:** 20px corner radius (`AppRadii.card`), subtle 0.8px border (`#E2E8E4`), elevation 1 soft shadow, pure white (`#FFFFFF`) surface on light canvas (`#F2F7F4` or `#F6F8F6`).
2. **Button Language:** 14px corner radius, 52px height for primary CTAs, deep pine `#0B5D4B` / `#084C3A` with high-contrast text, clear disabled and loading state spinners.
3. **Input Language:** 14px corner radius, subtle border with `#0B5D4B` focus ring, Plus Jakarta Sans typography, clean trailing/leading icons.
4. **Match Score Badge:** Distinctive circular or pill badge with explainable route score (`94% Match`), color-graded based on score threshold (90%+ Emerald, 75-89% Sage, <75% Amber).
5. **Route Corridor:** Vertical continuous dashed/solid corridor line connecting Origin (green ring), Stoppovers (amber dots), Destination (pin).
6. **Bottom Navigation:** Custom floating or docked luxury pill bar with active dot/glow indicator, labels in Plus Jakarta Sans.

---

## 13. Migration Order (Batches 1 - 11)

Execution will strictly follow the 11 sequential batches specified in Section 49 & 70:

- **Batch 1:** Design System consolidation, `AppShell`, `SahyanBottomNavigation`, `SahyanAppBar`, `HomeScreen`.
- **Batch 2:** Location search, `FilterRidesScreen`, `SearchResultsScreen`.
- **Batch 3:** `RideCard`, `SahyanMatchScoreBadge`, Route Match explanation, `RideDetailsScreen`.
- **Batch 4:** `SeatSelectionScreen`, `ConfirmPayScreen`, `BookingConfirmationScreen`, `BookingDetailsScreen`.
- **Batch 5:** `PublishRideScreen`, `DriverRidesScreen`, `DriverRequestDetailsScreen`.
- **Batch 6:** Boarding validation, `DriverActiveRideScreen`, `JourneyCompletedScreen`.
- **Batch 7:** `ActiveJourneyScreen`, `LiveRideTrackingScreen`, `SafetyCenterScreen`, SOS Bottom Sheet.
- **Batch 8:** `ProfileScreen`, `PersonalDetailsScreen`, `MyVehiclesScreen`, `AddVehicleScreen`, `EmergencyContactsScreen`, `SettingsScreen`.
- **Batch 9:** `MessagesScreen`, `ChatDetailScreen`, `NotificationsScreen`, `PaymentMethodsScreen`, `HelpSupportScreen`.
- **Batch 10:** Admin console check, router cleanup, removal of obsolete duplicate files (`ride_search_results_screen.dart`, redundant shims).
- **Batch 11:** Full responsive verification across target screen sizes, font-scaling tests, zero-emoji verification, final `flutter analyze` and `flutter test`.

---

## 14. Responsive QA Plan

All updated screens will be validated against:
1. **Device Viewport Formats:**
   - Small Android: 360 x 640 dp
   - Standard Modern: 390 x 844 dp (iPhone 13/14 / Pixel 7)
   - Large Android: 412 x 915 dp (Pixel 8 Pro)
2. **Font Scaling:**
   - Standard: 1.0x
   - Accessibility Enlarged: 1.3x and 1.5x (Zero overflow / yellow-black stripes)
3. **Safe Area & Insets:**
   - Dynamic Island / camera notch padding.
   - On-screen keyboard display without overflow in forms.
4. **Map Layout Constraints:**
   - Zero bounded height errors on map containers (`flutter_map`).

---

## 15. Risks & Mitigation

| Risk | Potential Impact | Mitigation Strategy |
|------|------------------|---------------------|
| Regression in existing tests | Breaking 367 passing frontend tests. | Run `flutter test` after every batch. Preserve existing widget keys and public APIs. |
| Inadvertent emoji addition | Violation of zero-emoji rule. | Run automated emoji scanner regex check before each batch completion. |
| Accidental paid map dependency | Incurring Google Maps charges. | Keep `flutter_map` with free OSRM / OpenStreetMap tiles intact. |
| Router breakages on aliases | Broken deep links or test navigations. | Maintain route redirects in `app_router.dart` for deprecated paths until all references are updated. |
| State desynchronization | Breaking Riverpod providers during refactoring. | Keep domain models and provider architectures completely untouched; only upgrade presentation layer. |

---

## 16. Items Requiring User Approval (Approval Gate 1)

In strict compliance with **Section 3** and **Section 74**:

### 1. Global Color Palette Decision
- **Option A (Recommended):** Preserve the approved Sahyān brand palette (`Primary: #0B5D4B`, `Dark: #084C3A`, `Mint: #A7E8D2`, `Canvas: #F2F7F4`, `Text: #12352E`, `Muted: #6B7F78`, `Accent: #C9A96E`) and adapt the reference's visual language (bento hierarchy, card elevations, spacing, layout) around these authentic Sahyān brand colors.
- **Option B:** Modify the global palette to directly match the visual reference's colors.

### 2. Removal of Redundant Duplicate Files
- Permission to delete unmounted duplicate screens (`ride_search_results_screen.dart`, unused shim files) during Batch 10 once all callers and tests are verified.

### 3. Approval to Begin Batch 1
- Approval to start Batch 1: Centralizing the design system tokens in `frontend/lib/app/theme/`, refining `AppShell` and `SahyanBottomNavigation`, and implementing the redesigned `HomeScreen`.

---

## 17. Implementation Progress & Batch Changelog

### Batch 1: Design System, App Shell, Bottom Navigation, App Bar, Home
- **Status:** Completed
- **Changes Delivered:**
  - Standardized color system in `app_colors.dart` and `core/theme/app_theme.dart` with approved Sahyān brand colors (`#0B5D4B`, `#084C3A`, `#A7E8D2`, `#F2F7F4`, `#FFFFFF`, `#12352E`, `#6B7F78`, `#C9A96E`).
  - Fixed duplicate `/journey-completed` route in `app_router.dart`.
  - Verified floating `SahyanBottomNavigation` and `AppShell`.
  - Verified `HomeScreen` and `HeroSearchCard` with corridor transit track capsule, live telematics badge, and zero-emoji compliance.
  - Validation: `flutter analyze` (0 issues), 367/367 tests passed, 203/203 backend tests passed.

### Batch 2: Location Picker, Search, Search Filters, Search Results
- **Status:** Completed
- **Changes Delivered:**
  - Audited `LocationSearchBottomSheet`: debounced Nominatim autocomplete, curated Gujarat corridor hubs, and GPS geolocation.
  - Audited `FilterRidesScreen`: deviation radius, time window, vehicle type, and verified-only filters.
  - Upgraded `SearchResultsScreen`:
    - Luxury corridor header with origin -> destination arrow, date, and seats pill.
    - Added horizontal quick-filter chip selector (`All`, `Direct Only`, `High Match`, `Under ₹350`) for instant tactile filtering.
    - Retained empty/error state handling and floating nav bar padding.
  - Validation: `flutter analyze` (0 issues), all search unit & responsive tests passed (9/9 search tests, 77/77 responsive tests).

### Batch 3: Ride Card, Match Score, Match Explanation, Ride Details
- **Status:** Completed
- **Changes Delivered:**
  - Verified `RideCard`: explainable Match Score pill with Sahyān logo and percentage, grade badge, corridor route timeline, driver avatar with verification badge, rating display, vehicle icon, and contribution pill.
  - Verified `SahyanMatchScoreBadge` and `SahyanMatchScoreBreakdownCard`: detailed breakdown of Route Overlap %, Pickup Deviation, Drop Deviation, Time Difference, and Driver Reliability without unexplained "AI" labels.
  - Verified `RouteMatchBreakdownWidget`: interactive draggable sheet for modal route match analysis.
  - Upgraded `RideDetailsScreen`:
    - Replaced legacy `sayan_route_map.dart` import with canonical `sahyan_route_map.dart`.
    - Integrated live OSRM polyline map with highway corridor telemetry banner (`corridor · distance · duration · detour`).
    - Full-screen route map inspection sheet trigger (`FullScreenRouteMapSheet`).
    - Driver credentials, vehicle specs, pickup policy, ride amenities, and sticky seat contribution booking footer with guest auth gating (`AuthGateDialog`).
  - Validation: `flutter analyze` (0 issues), 9/9 search & ride details tests passed, 77/77 responsive layout tests passed.

---
*Next Step: Batch 4 (Seat Selection, Booking Review, Payment Sandbox, Confirmation, Booking Details).*


