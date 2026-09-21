# Sahyān Frontend Testing Architecture & Standards

This directory contains the automated test suite for the Sahyān Flutter client.
All tests mirror the feature-first modular architecture used in `lib/`.

---

## 1. Directory Structure

```
frontend/test/
├── core/                           # System-wide design, hardware, and infrastructure tests
│   ├── design_system_test.dart     # Typography, colors, and AppRadii tokens
│   ├── floating_nav_test.dart      # Bottom navigation shell interaction
│   ├── location_gps_test.dart      # Mathematical distance, bearing, and GPS policies
│   ├── responsive_audit_test.dart  # Multi-viewport audits (320dp to 600dp + font scaling)
│   ├── telemetry_test.dart         # Live GPS telemetry, map polylines, and bearing smoothing
│   └── theme_bento_ui_test.dart    # Bento card styling and surface elevation
│
├── features/                       # Feature-specific unit and widget tests
│   ├── admin/
│   │   └── admin_ui_test.dart      # Web admin panel, user moderation, and dispute tools
│   ├── auth/
│   │   ├── auth_unit_test.dart     # Auth state notifier, token storage, and session logic
│   │   ├── auth_ui_test.dart       # Login, Register, Forgot Password, and OTP forms
│   │   └── startup_test.dart       # Cold start, splash gate, and routing decisions
│   ├── bookings/
│   │   ├── booking_flow_test.dart  # Seat reservation, contribution, and confirmation sheet
│   │   └── driver_requests_test.dart # Driver approval, rejection, and seat counters
│   ├── messaging/
│   │   └── chat_messaging_test.dart # 1-on-1 chat bubbles, message send, and safety dialogs
│   ├── payments/
│   │   └── payment_payout_test.dart # Checkout gateway, UPI orders, and driver earnings
│   ├── profile/
│   │   ├── profile_unit_test.dart  # User model, KYC verification, and preference serialization
│   │   └── profile_ui_test.dart    # Profile screen, emergency contacts, and edit sheet
│   ├── rides/
│   │   ├── offer_ride_test.dart    # Multi-step ride publishing wizard
│   │   ├── route_geometry_test.dart # Polyline decoding, detour calculation, and stopovers
│   │   ├── route_match_test.dart   # Corridor overlap and detour score rendering
│   │   └── search_rides_test.dart  # Ride query tags, search results, and filters
│   ├── trip/
│   │   └── trip_lifecycle_test.dart # State machine (Scheduled -> Boarding -> In-Progress -> Completed)
│   └── vehicles/
│       ├── generate_vehicle_assets_test.dart # Vehicle map marker icon generator
│       ├── vehicle_unit_test.dart  # Vehicle types (Sedan, SUV, EV, Hatchback) and taxonomy
│       └── vehicle_ui_test.dart    # Vehicle list CRUD and Add/Edit forms
│
├── integration/                    # Multi-feature end-to-end integration tests
│   ├── fullstack_integration_test.dart # Riverpod provider hierarchy and app state flows
│   └── screens_coverage_test.dart  # Visual smoke test across all product screens
│
└── widget_test.dart                # Basic root initialization smoke test
```

---

## 2. Testing Guidelines for Future Development

When adding new features or screens to Sahyān, follow these rules:

### A. Location & Naming Conventions
1. **Always place tests in the appropriate feature subfolder**:
   - `test/features/<feature>/<name>_test.dart` for unit tests.
   - `test/features/<feature>/<name>_ui_test.dart` for widget/UI tests.
   - `test/core/<name>_test.dart` for shared design system or hardware tests.
2. **Never use temporary phase or sprint prefixes**:
   - Do NOT use: `phase1_`, `phase2_`, `all_missing_`, `temp_`, `new_`.
   - Use descriptive, permanent domain names: `payment_payout_test.dart`, `route_match_test.dart`.
3. **Follow snake_case for filenames**:
   - Example: `chat_messaging_test.dart` (not `chatMessagingTest.dart`).

### B. Strict Zero-Emoji Policy
- **No emojis** anywhere in test descriptions, group names, log outputs, assertion strings, or error messages.

### C. Responsive Layout Audits
- Any new screen must be verified across standard viewport widths (`320dp`, `360dp`, `390dp`, `412dp`, `600dp`) and under `1.5x` accessibility text scaling to prevent RenderFlex overflow bars.

### D. Running Tests
- Run all tests:
  ```bash
  flutter test
  ```
- Run tests for a specific feature:
  ```bash
  flutter test test/features/auth
  flutter test test/features/rides
  ```
- Run a single test file:
  ```bash
  flutter test test/features/bookings/booking_flow_test.dart
  ```
