# System Architecture — Sahyān

## Intelligent Route-Based Carpooling Platform

---

## 1. High-Level Architecture

Sahyān is designed as a clean, monolithic, 3-tier system built specifically for peer-to-peer route-based vehicle seat sharing. The architecture is deliberately structured for maintainability, reliability, and clear academic viva explainability without unnecessary microservice overhead.

```
+-------------------------------------------------------------------+
|                           CLIENT LAYER                            |
|  +-------------------------------------------------------------+  |
|  |           Flutter Mobile Application (Android / iOS)        |  |
|  |           - Riverpod (Reactive State Management)            |  |
|  |           - GoRouter (Declarative Navigation & Shell)       |  |
|  |           - Plus Jakarta Sans Typography & Stitch Tokens    |  |
|  +------------------------------+------------------------------+  |
+---------------------------------|---------------------------------+
                                  |
                                  | HTTPS / REST API (JSON)
                                  v
+-------------------------------------------------------------------+
|                     APPLICATION TIER (Backend)                    |
|  +-------------------------------------------------------------+  |
|  |                  Node.js + Express.js Server                |  |
|  |  +---------------+  +---------------+  +-----------------+  |  |
|  |  | API Routes    |  | Controllers   |  | Middleware      |  |  |
|  |  | (/auth,       |  | (Business     |  | (JWT Auth,      |  |  |
|  |  |  /users,      |  |  Logic,       |  |  Validation,    |  |  |
|  |  |  /rides,      |  |  Matching,    |  |  Rate Limiting, |  |  |
|  |  |  /bookings,   |  |  Lifecycle)   |  |  Error Handling)|  |  |
|  |  |  /vehicles)   |  |               |  |                 |  |  |
|  |  +---------------+  +---------------+  +-----------------+  |  |
|  +------------------------------+------------------------------+  |
+---------------------------------|---------------------------------+
                                  |
                                  | Mongoose ODM (BSON)
                                  v
+-------------------------------------------------------------------+
|                         DATA TIER (MongoDB)                       |
|  +-------------------------------------------------------------+  |
|  |                    MongoDB Database Engine                  |  |
|  |  +------------+  +------------+  +------------+  +-------+  |  |
|  |  | Users      |  | Rides      |  | Bookings   |  |Vehicles| |  |
|  |  | Collection |  | Collection |  | Collection |  |Collect.| |  |
|  |  | (Auth/OTP) |  | (2dsphere) |  | (Seats/Req)|  |(Specs) |  |  |
|  |  +------------+  +------------+  +------------+  +-------+  |  |
|  +-------------------------------------------------------------+  |
+-------------------------------------------------------------------+
                                  |
                                  | Route calculation & Geocoding
                                  v
+-------------------------------------------------------------------+
|                        EXTERNAL SERVICES                          |
|  +-------------------------------------------------------------+  |
|  |                 Google Maps Platform APIs                   |  |
|  |                 - Routes API & Directions                   |  |
|  |                 - Geocoding & Places                        |  |
|  +-------------------------------------------------------------+  |
+-------------------------------------------------------------------+
```

---

## 2. Architectural Tiers

### 2.1 Presentation Tier (Frontend — Flutter)
- **Framework**: Flutter 3 (Dart 3.x)
- **State Management**: Flutter Riverpod (`StateNotifierProvider`, `Provider`)
- **Routing**: GoRouter with `StatefulShellRoute.indexedStack` for bottom navigation tabs and nested sub-routes
- **Design System**: Sahyān Brand Guidelines (Forest Green `#285A4A`, Deep Forest `#193D33`, Soft Forest `#DDE9E3`, Warm Background `#F6F7F4`), Plus Jakarta Sans typography scale, and responsive layout constraints (320dp to 600dp+).
- **Session Security**: `flutter_secure_storage` storing authentic JWT tokens with automated expiration validation and session restoration.

### 2.2 Application Tier (Backend — Node.js & Express.js)
- **Runtime**: Node.js (CommonJS modules)
- **Framework**: Express.js
- **Authentication**: Stateless JSON Web Tokens (JWT) signed using cryptographically enforced environment secrets (`JWT_SECRET`), bcryptjs password hashing, and server-generated 6-digit cryptographic OTPs (`crypto.randomInt`).
- **Route Matching Engine**: In-memory and geospatial evaluation calculating route overlap, deviation from polyline, time compatibility, and seat availability.

### 2.3 Data Tier (Database — MongoDB)
- **Database**: MongoDB with Mongoose ODM
- **Geospatial Capabilities**: GeoJSON `Point` primitives with `2dsphere` spatial indexing on route origins and destinations (`$near`, `$geoWithin`).
- **Data Integrity**: Schema-level validations, unique compound indexing, and explicit status lifecycle enums.

---

## 3. Component Architecture & Directory Structure

### 3.1 Frontend Directory Structure

```
frontend/lib/
├── app/
│   ├── providers/               # AppStartupProvider, UserModeProvider
│   ├── router/                  # GoRouter configuration (app_router.dart)
│   └── theme/                   # Tokens: app_colors, app_radii, app_spacing,
│                                # app_typography, app_elevation, app_theme
├── core/
│   ├── network/                 # ApiClient (HTTP/REST interface)
│   ├── storage/                 # SecureStorageService (Keychain/Keystore)
│   └── widgets/                 # Canonical Sahyān Design System:
│                                # SahyanButton, SahyanTextField, SahyanCard,
│                                # SahyanChip, SahyanStatusBadge, SahyanEmptyState,
│                                # SahyanErrorState, SahyanLoadingState,
│                                # SahyanSectionHeader, SahyanPrimaryCTA,
│                                # SahyanAppBar, SahyanAvatar, SahyanBottomNavigation,
│                                # RatingDisplay, VerificationBadge,
│                                # design_system.dart (Central Barrel)
├── shared/
│   ├── models/                  # Cross-feature models: location_model.dart,
│   │                            # user_model.dart; re-exports for ride & booking
│   └── widgets/                 # AppShell, AuthGateDialog, RideCard
└── features/
    ├── auth/                    # AuthRepository, AuthNotifier, Auth Screens
    ├── home/                    # HomeScreen
    ├── rides/
    │   ├── data/                # RideRepository
    │   ├── domain/              # CANONICAL ride_model.dart, ride_search_result.dart
    │   └── presentation/        # SearchResultsScreen, RideDetailsScreen, OfferRideScreen
    ├── bookings/
    │   ├── data/                # BookingsRepository
    │   ├── domain/              # CANONICAL booking_model.dart
    │   └── presentation/        # MyBookingsScreen, ConfirmPayScreen, DriverRidesScreen
    ├── vehicles/
    │   ├── data/                # VehicleRepository
    │   ├── domain/              # CANONICAL vehicle_model.dart
    │   └── presentation/        # MyVehiclesScreen, AddVehicleScreen, EditVehicleScreen
    └── profile/                 # ProfileScreen, EditProfileScreen, EmergencyContactsScreen
```

### 3.2 Backend Directory Structure

```
backend/src/
├── app.js                       # Express application configuration and middleware
├── server.js                    # HTTP listener entry point
├── config/
│   ├── db.js                    # Mongoose database connection
│   └── jwt.js                   # Strict environment variable JWT secret accessor
├── controllers/
│   ├── authController.js        # Registration, password login, OTP verification, reset
│   ├── bookingController.js     # Booking creation, driver acceptance/rejection, passenger cancel
│   ├── rideController.js        # Ride publication, intelligent search, trip lifecycle
│   ├── userController.js        # Profile retrieval, updates, preferences, emergency contacts
│   └── vehicleController.js     # Vehicle CRUD and driver capability association
├── middleware/
│   ├── authMiddleware.js        # Bearer token verification and req.user attachment
│   └── errorMiddleware.js       # Centralized error handler and response formatting
├── models/
│   ├── Booking.js               # Passenger booking schema, seats, lifecycle status
│   ├── Ride.js                  # Ride route coordinates, schedule, seats, vehicle, 2dsphere
│   ├── User.js                  # User credentials, rating, verification, preferences
│   └── Vehicle.js               # Vehicle specifications, registration, seat capacity
├── routes/
│   ├── authRoutes.js            # /api/v1/auth
│   ├── bookingRoutes.js         # /api/v1/bookings
│   ├── rideRoutes.js            # /api/v1/rides
│   ├── userRoutes.js            # /api/v1/users
│   └── vehicleRoutes.js         # /api/v1/vehicles
├── services/
│   ├── googleMapsService.js     # External Google Maps Directions & Polyline abstraction
│   ├── otpService.js            # Cryptographic random OTP generation and rate limiting
│   ├── passwordService.js       # Secure password hashing and token management
│   └── routeMatchService.js     # Polyline geometric evaluation and route score calculation
└── utils/                       # Shared utility helpers
```

---

## 4. Key Architectural Decisions

### 4.1 Canonical Domain Models
- Each business domain owns its domain models in `features/<feature>/domain/`:
  - `features/rides/domain/ride_model.dart`
  - `features/bookings/domain/booking_model.dart`
  - `features/vehicles/domain/vehicle_model.dart`
- Models required across multiple un-isolated domains (such as `LocationModel` and `UserModel`) reside in `shared/models/`.
- Backward compatibility is preserved using clean re-export files (`shared/models/ride_model.dart`, `shared/models/booking_model.dart`).

### 4.2 Guest vs Authenticated State Separation
- **Guest Access**: Unauthenticated users can search rides, explore routes, and view informational content in read-only mode (`AccessMode.guest`).
- **Protected Actions**: Actions that require user identity (booking seats, offering rides, managing vehicles, modifying profile) trigger the `AuthGateDialog` with an intended route intent.
- **State Transition**: Upon successful login or OTP verification, `authProvider` emits `AuthStatus.authenticated` with the real `UserModel`. `userModeProvider` reactively listens to `authProvider`, clears guest access, sets `AccessMode.authenticated`, and navigates directly to the intended route without leaving the user in guest state.

### 4.3 Security & Zero-Trust Authentication
- **No Fallback JWT Secrets**: The server fails fast during startup if `JWT_SECRET` is omitted from the environment.
- **Cryptographic OTPs**: OTP codes are 6-digit integers generated server-side via `crypto.randomInt`. Fixed bypass codes (e.g. `123456`) are strictly forbidden.
- **Brute-Force Protection**: 60-second cooldown between OTP requests, maximum 5 requests per 10-minute window, and maximum 5 failed verification attempts before automatic expiration.
- **Verified Phone Requirement**: Accounts must complete phone OTP verification before password login is accepted.

---

## 5. Technology Stack Summary

| Layer | Component | Technology | Rationale |
|---|---|---|---|
| Client | UI Framework | Flutter (Dart) | Single cross-platform codebase, native 60fps performance |
| Client | State Management | Flutter Riverpod | Compile-safe dependency injection and reactive state |
| Client | Navigation | GoRouter | Declarative routing, deep links, and StatefulShellRoute support |
| Server | Runtime | Node.js | Event-driven, non-blocking asynchronous I/O |
| Server | Framework | Express.js | Minimalist, stable, widely understood REST architecture |
| Database | Persistence | MongoDB (Mongoose) | Native GeoJSON 2dsphere indexing for route proximity queries |
| Security | Tokens & Hashing | JWT + bcryptjs | Stateless authorization and cryptographically secure password storage |
| External | Geocoding & Routes | Google Maps Platform | Accurate Indian road network polylines and geocoding |

---

**Document Version**: 3.0 (Stabilized Architecture)  
**Last Updated**: September 2026
