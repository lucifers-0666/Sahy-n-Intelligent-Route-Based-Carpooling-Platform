# Sahyān --- Complete UI/UX Redesign Master Specification

> **Purpose:** This file is the single permanent source of truth for the
> complete Sahyān UI/UX redesign.
>
> **Coding-agent rule:** Read this file before making ANY UI/UX,
> design-system, screen, navigation-shell, component, responsive-layout,
> or frontend cleanup change.
>
> Do not repeatedly ask for the same redesign instructions. Follow this
> document unless an explicit user instruction overrides it.

------------------------------------------------------------------------

# 1. PROJECT IDENTITY

**Product:** Sahyān\
**Full description:** Intelligent Route-Based Carpooling Platform

Sahyān is a planned-route peer-to-peer carpooling platform.

Drivers publish planned journeys with spare seats.

Passengers find rides that are compatible with their route, pickup,
destination, timing, available seats, driver reliability, and detour.

Sahyān is **not** an on-demand taxi/ride-hailing application.

The UI must communicate:

-   shared journeys
-   intelligent matching
-   route compatibility
-   trust
-   safety
-   transparency
-   movement
-   connection
-   efficiency
-   sustainability

The product's strongest differentiator is the **explainable Route Match
Score**.

Example:

**94% Match**

The UI must explain why the match is good instead of presenting the
score as an unexplained "AI" number.

------------------------------------------------------------------------

# 2. PRIMARY VISUAL REFERENCE

The primary design reference is:

https://cdn.dribbble.com/userupload/14268327/file/original-cbe245ad18e07fa642bb196c280e8adc.png?resize=2048x4848&vertical=center

This reference is the primary visual direction for the redesign.

The coding agent must inspect the reference whenever visual
implementation is being performed and reproduce its **design language**,
not blindly copy protected assets.

The reference controls:

-   overall visual hierarchy
-   layout direction
-   spacing rhythm
-   component composition
-   card language
-   input language
-   button language
-   navigation language
-   visual density
-   border-radius direction
-   icon treatment
-   section hierarchy
-   map/card composition
-   bottom navigation treatment
-   status treatment
-   interaction patterns
-   animation/micro-interaction direction

Do NOT replace the reference with generic Flutter Material UI.

Do NOT create a completely unrelated design.

Do NOT blindly copy proprietary artwork, illustrations, logos,
photographs, or other protected assets.

Recreate the visual language using Sahyān's own branding and assets.

------------------------------------------------------------------------

# 3. CRITICAL COLOR APPROVAL GATE

This is mandatory.

Before changing the global Sahyān color system:

1.  Inspect the current implementation.
2.  Inspect the reference.
3.  Compare the visual systems.
4.  Determine whether the current Sahyān palette can achieve the
    reference's visual language.
5.  Prefer preserving Sahyān's existing brand identity.

## Current approved Sahyān palette

Primary:

`#0B5D4B`

Dark primary:

`#084C3A`

Accent / mint:

`#A7E8D2`

Light surface:

`#F2F7F4`

White:

`#FFFFFF`

Primary text:

`#12352E`

Muted text:

`#6B7F78`

Optional subtle premium accent:

`#C9A96E`

## Typography

Primary:

**Plus Jakarta Sans**

### Absolute rule

The coding agent MUST NOT automatically replace these colors with colors
taken from the reference.

If the reference appears to require a materially different global color
system, STOP and ask the user:

> The reference design would benefit from changing the current Sahyān
> color system. Should I: A) Keep the existing Sahyān colors and adapt
> the reference around them B) Modify the Sahyān global color palette to
> more closely match the reference?

Wait for approval.

Do not modify global color tokens before approval.

Local visual adjustments that do not alter global brand tokens are
allowed.

------------------------------------------------------------------------

# 4. DESIGN PRIORITY

When making UI decisions, use this priority:

1.  Functional correctness
2.  Sahyān brand identity
3.  Primary design reference
4.  Consistent design system
5.  Responsive/accessibility requirements
6.  Existing architecture
7.  Existing visual implementation

The goal is NOT to make a screenshot clone.

The goal is to create a production-quality Sahyān product whose UI
follows the reference's visual language while remaining an original
Sahyān product.

------------------------------------------------------------------------

# 5. EXISTING TECHNOLOGY --- DO NOT REPLACE

Frontend:

-   Flutter
-   Dart
-   Riverpod
-   GoRouter

Backend:

-   Node.js
-   Express.js

Database:

-   MongoDB
-   Mongoose

Authentication:

-   JWT
-   OTP

Location/maps:

-   Geolocator
-   FlutterMap
-   OpenStreetMap
-   OSRM
-   Nominatim

Realtime:

-   Socket.IO

Storage:

-   flutter_secure_storage

HTTP:

-   http

Do not introduce unrelated architecture merely for visual redesign.

Do NOT introduce:

-   React
-   Next.js
-   PostgreSQL
-   Redis
-   Kafka
-   RabbitMQ
-   Kubernetes
-   microservices
-   a second state-management framework
-   a second navigation framework
-   paid map infrastructure

unless explicitly requested by the user.

------------------------------------------------------------------------

# 6. CORE REDESIGN PRINCIPLE

**Redesign presentation; preserve functionality.**

For every screen:

1.  Inspect the existing screen.
2.  Inspect its providers.
3.  Inspect API/repository dependencies.
4.  Inspect models.
5.  Inspect navigation.
6.  Inspect loading/error/empty states.
7.  Inspect existing reusable widgets.
8.  Compare the screen against the reference.
9.  Build the target UI.
10. Reuse the existing business logic.
11. Reuse real API data.
12. Add/reuse shared components.
13. Test navigation.
14. Test responsive layouts.
15. Remove obsolete UI only after dependency verification.

Never replace working functionality with static mock data simply to make
the UI look better.

------------------------------------------------------------------------

# 7. COMPLETE REDESIGN PHASES

Do not redesign the application randomly.

Use this sequence:

## Phase 0 --- Audit

-   repository
-   screens
-   routes
-   widgets
-   providers
-   themes
-   duplicates
-   obsolete code
-   responsive problems
-   reference design

## Phase 1 --- Design foundation

-   colors
-   typography
-   spacing
-   radii
-   elevation
-   dimensions
-   component rules
-   animation rules

## Phase 2 --- App shell

-   splash
-   onboarding
-   auth entry
-   app navigation
-   bottom navigation
-   global app bars
-   global surfaces

## Phase 3 --- Authentication

-   login
-   registration
-   OTP
-   password recovery
-   auth success
-   biometric entry where applicable

## Phase 4 --- Discovery

-   home
-   search
-   location selection
-   filters
-   search results
-   match cards
-   ride details

## Phase 5 --- Booking

-   seat selection
-   booking review
-   payment/sandbox state
-   confirmation
-   booking details
-   cancellation

## Phase 6 --- Driver

-   offer ride
-   publish ride
-   driver dashboard
-   passenger requests
-   request details
-   boarding
-   active ride
-   completion

## Phase 7 --- Trip

-   active journey
-   live tracking
-   safety
-   SOS
-   trip completion
-   review/rating

## Phase 8 --- Account

-   profile
-   edit profile
-   vehicles
-   emergency contacts
-   settings
-   privacy/security
-   notifications
-   payments
-   help

## Phase 9 --- Secondary

-   messages
-   notifications
-   admin

## Phase 10 --- Cleanup

-   duplicate components
-   duplicate screens
-   dead routes
-   obsolete files
-   debug navigation
-   legacy theme
-   inconsistent naming

## Phase 11 --- QA

-   responsive
-   accessibility
-   navigation
-   API states
-   loading/error/empty
-   real device
-   analyzer
-   tests

------------------------------------------------------------------------

# 8. REQUIRED SCREEN INVENTORY

## Startup

-   Splash
-   Onboarding 1
-   Onboarding 2
-   Onboarding 3
-   Auth entry
-   Guest access

## Authentication

-   Login
-   Register
-   OTP
-   Forgot password
-   Reset password
-   Auth success
-   Biometric authentication

## Main discovery

-   Home
-   Location picker
-   Search
-   Search filters
-   Search results
-   Match explanation
-   Ride details

## Booking

-   Seat selection
-   Booking request
-   Booking review
-   Payment
-   Booking confirmation
-   Booking details
-   Cancel booking

## Driver

-   Offer ride
-   Publish ride
-   Driver rides
-   Passenger requests
-   Request details
-   Boarding
-   Active driver ride
-   Journey completion

## Trip

-   Active journey
-   Live tracking
-   Trip safety
-   Safety center
-   SOS
-   Journey completed
-   Rating/review

## Account

-   Profile
-   Edit profile
-   Vehicles
-   Add vehicle
-   Edit vehicle
-   Emergency contacts
-   Settings
-   Privacy/security
-   Notifications settings
-   Payment settings
-   Help/support
-   About

## Secondary

-   Messages
-   Notifications
-   Payments
-   Admin

------------------------------------------------------------------------

# 9. STARTUP EXPERIENCE

Startup must follow:

**Splash → 3 onboarding screens → Auth Entry**

Auth Entry:

-   Sign Up
-   Log In
-   Continue as Guest

Do not use arbitrary fixed delays to determine application navigation.

Navigation must derive from:

-   persisted onboarding state
-   authentication state
-   guest/access mode
-   operational state

Guest mode is read-only where appropriate.

Actions requiring authentication must clearly gate the user.

------------------------------------------------------------------------

# 10. APP SHELL

Create a consistent application shell.

It should define:

-   background
-   navigation
-   app bar behavior
-   safe-area behavior
-   page transitions
-   bottom navigation
-   global surfaces
-   responsive behavior

Bottom navigation must be visually aligned with the primary reference.

Do not duplicate navigation implementations across features.

------------------------------------------------------------------------

# 11. HOME SCREEN

The Home screen may be completely redesigned if necessary.

Preferred hierarchy:

1.  greeting/profile
2.  notification access
3.  primary journey/search action
4.  origin
5.  destination
6.  date/time
7.  search CTA
8.  active journey
9.  recommended rides
10. popular corridors
11. relevant quick actions

The primary action must be immediately understandable.

Do not overcrowd the home screen.

Use the reference's visual hierarchy and card composition.

------------------------------------------------------------------------

# 12. SEARCH EXPERIENCE

Use a coherent journey:

**Home → Location Picker → Search → Filters → Results → Ride Details →
Seat Selection → Booking**

Avoid unnecessary intermediate screens.

Location fields should be visually clear.

Search should support:

-   origin
-   destination
-   date
-   time
-   seats
-   relevant preferences

Use debouncing where appropriate.

------------------------------------------------------------------------

# 13. SEARCH RESULTS

Search result cards are critical.

Every useful ride card should communicate:

-   Match Score
-   driver
-   rating
-   vehicle
-   route
-   pickup
-   destination
-   departure
-   estimated arrival
-   seats
-   contribution
-   detour/compatibility where useful

Avoid visually overwhelming cards.

The most important information should be visible before opening details.

------------------------------------------------------------------------

# 14. ROUTE MATCH SCORE

Route Match Score is a primary Sahyān product element.

Example:

**94% Match**

The UI must explain the score.

Suggested explanation:

-   route overlap
-   pickup deviation
-   destination deviation
-   time compatibility
-   detour
-   driver reliability
-   seat availability

Possible component:

`SahyanMatchScoreBadge`

Possible expanded component:

`MatchExplanationCard`

Never label an arbitrary score as AI without an actual explanation.

------------------------------------------------------------------------

# 15. RIDE DETAILS

Ride details should contain:

-   route map
-   route summary
-   driver information
-   rating
-   vehicle
-   departure
-   arrival
-   pickup
-   destination
-   seats
-   contribution
-   match score
-   why-this-matches section
-   safety
-   amenities where supported
-   primary booking CTA

Map and content should feel like one integrated product experience.

------------------------------------------------------------------------

# 16. OFFER RIDE

Prefer a guided flow over one giant form.

Suggested steps:

1.  Route
2.  Date/time
3.  Vehicle
4.  Seats
5.  Contribution
6.  Preferences
7.  Review
8.  Publish

Use progress indicators if consistent with the reference.

Preserve the existing ride publishing business logic.

------------------------------------------------------------------------

# 17. BOOKING EXPERIENCE

Use a consistent booking lifecycle:

-   Pending
-   Confirmed
-   Active
-   Completed
-   Cancelled

Do not create duplicate screens that represent the same state unless
there is a functional reason.

Booking should communicate:

-   ride
-   driver
-   route
-   seats
-   price/contribution
-   status
-   cancellation rules where supported
-   safety/relevant information

Payment must clearly indicate sandbox/simulated behavior if a real
gateway is not implemented.

Never claim real payment processing when it is not implemented.

------------------------------------------------------------------------

# 18. DRIVER EXPERIENCE

Driver screens should prioritize:

-   upcoming rides
-   requests
-   passenger status
-   boarding
-   active ride
-   route
-   trip status
-   contribution summary
-   safety

Passenger and driver experiences should share the same design system but
may have different information hierarchy.

------------------------------------------------------------------------

# 19. LIVE TRIP / TRACKING

Live trip must prioritize:

-   map
-   current location
-   route
-   ETA
-   remaining distance
-   trip state
-   driver/passenger identity
-   message
-   safety
-   SOS

Do not cover most of the map with controls.

Use bottom sheets/cards where appropriate.

Use actual Socket.IO/location data.

Do not use fake movement in production.

------------------------------------------------------------------------

# 20. SAFETY

Safety UI must feel trustworthy and calm.

Include existing supported functionality such as:

-   safety center
-   emergency contacts
-   SOS
-   trip information
-   live trip sharing where implemented

Do not visually imply functionality that does not exist in the backend.

If an action is currently prototype-only, label/handle it honestly.

------------------------------------------------------------------------

# 21. PROFILE

Simplify the profile experience.

Suggested sections:

-   profile information
-   verification
-   vehicles
-   emergency contacts
-   ratings
-   preferences
-   privacy
-   security
-   notifications
-   payments
-   help
-   about

Use the reference's list/card treatment.

------------------------------------------------------------------------

# 22. SETTINGS

Group settings logically:

### Account

Profile and personal information

### Privacy & Security

Password, biometric, sessions, privacy

### Notifications

Notification preferences

### Safety

Emergency contacts and safety options

### Payments

Payment-related settings

### Preferences

Application preferences

### Help

Support and help

### About

Version and product information

Avoid one giant unstructured list.

------------------------------------------------------------------------

# 23. MESSAGES

Messages should use:

-   clean conversation list
-   unread indicators
-   readable message bubbles
-   timestamp hierarchy
-   empty state
-   loading state
-   error state

Do not over-design messaging.

------------------------------------------------------------------------

# 24. NOTIFICATIONS

Notifications should support:

-   unread/read hierarchy
-   notification category where useful
-   clear timestamp
-   meaningful content
-   empty state
-   loading state
-   error state

Use actual data.

------------------------------------------------------------------------

# 25. DESIGN SYSTEM LOCATION

Use one authoritative location:

``` text
frontend/lib/app/theme/
├── app_theme.dart
├── app_colors.dart
├── app_typography.dart
├── app_spacing.dart
├── app_radii.dart
├── app_elevation.dart
└── app_dimensions.dart
```

Do not maintain competing theme systems.

Audit:

``` text
frontend/lib/app/theme/
frontend/lib/core/theme/
```

Consolidate only after tracing references.

------------------------------------------------------------------------

# 26. DESIGN TOKENS

Use tokens for:

-   colors
-   typography
-   spacing
-   radii
-   elevation
-   dimensions
-   animation durations where useful

Avoid scattering arbitrary visual values throughout the application.

Do not blindly replace every numeric value.

Context-specific dimensions are acceptable when genuinely necessary.

------------------------------------------------------------------------

# 27. COMPONENT LIBRARY

Create or consolidate authoritative reusable components:

### Buttons

-   SahyanButton
-   SahyanOutlinedButton
-   SahyanPrimaryCTA

### Inputs

-   SahyanTextField

### Cards

-   SahyanCard
-   RideCard
-   MatchExplanationCard

### Status

-   SahyanStatusBadge
-   SahyanMatchScoreBadge

### Feedback

-   SahyanLoadingState
-   SahyanErrorState
-   SahyanEmptyState

### Navigation

-   SahyanAppBar
-   SahyanBottomNavigation
-   SectionHeader

### Identity

-   SahyanAvatar
-   VerificationBadge
-   RatingDisplay

### Maps

-   SahyanRouteMap
-   RouteMapPreview
-   FullScreenRouteMapSheet

Only keep multiple components when their responsibilities are genuinely
different.

------------------------------------------------------------------------

# 28. DUPLICATE COMPONENT AUDIT

Investigate:

``` text
core/widgets/app_text_field.dart
core/widgets/sahyan_text_field.dart

core/widgets/primary_button.dart
core/widgets/secondary_button.dart
core/widgets/sahyan_button.dart

app/theme/app_theme.dart
core/theme/app_theme.dart

shared/widgets/sahyan_route_map.dart
shared/widgets/sayan_route_map.dart
```

For each duplicate:

1.  search references
2.  identify canonical implementation
3.  migrate references
4.  run analyzer
5.  verify behavior
6.  delete obsolete implementation

Never delete based only on filename.

------------------------------------------------------------------------

# 29. DUPLICATE SCREEN AUDIT

Investigate:

``` text
offer_ride_screen.dart
publish_ride_screen.dart

ride_search_results_screen.dart
search_results_screen.dart

my_bookings_screen.dart
bookings_hub_screen.dart
```

Determine whether each is:

-   genuinely different
-   a different state
-   a duplicate implementation

If duplicate:

1.  choose canonical implementation
2.  migrate router
3.  migrate imports
4.  migrate dependencies
5.  verify
6.  delete obsolete implementation

------------------------------------------------------------------------

# 30. ROUTER CLEANUP

Use GoRouter.

Create centralized route names if appropriate:

``` text
app/router/route_names.dart
```

Audit:

-   duplicate routes
-   dead routes
-   routes pointing to removed screens
-   duplicate booking routes
-   duplicate ride-search routes
-   duplicate publish/offer routes
-   production/debug routes

There must be no duplicate route declarations.

After every route migration:

-   run analyzer
-   test navigation
-   verify back behavior
-   verify deep links where applicable

------------------------------------------------------------------------

# 31. DEBUG / INTERNAL UI

These should NOT appear in normal production navigation:

``` text
system_states_screen.dart
gps_diagnostic_screen.dart
```

If still useful:

-   isolate as debug/admin tooling
-   protect appropriately
-   remove from normal navigation

Do not delete useful diagnostics without checking whether developers
still need them.

------------------------------------------------------------------------

# 32. RESPONSIVE DESIGN

Mandatory target sizes:

-   320dp
-   360dp
-   390dp
-   412dp
-   600dp+
-   tablet where appropriate

Also test:

-   font scale 1.5x
-   keyboard visible
-   long text
-   long location names
-   long driver names
-   empty results
-   error states
-   loading states

Use:

-   MediaQuery
-   LayoutBuilder
-   Flexible
-   Expanded
-   Wrap
-   ConstrainedBox
-   SingleChildScrollView
-   SafeArea

when appropriate.

Do not solve responsive problems with arbitrary fixed widths.

Zero pixel-overflow warnings are required.

------------------------------------------------------------------------

# 33. ACCESSIBILITY

Support:

-   readable contrast
-   semantic labels
-   adequate touch targets
-   scalable text
-   keyboard-safe layouts
-   screen-reader-friendly controls where practical

Do not make text unreadable merely to match a screenshot.

------------------------------------------------------------------------

# 34. ANIMATION AND MICRO-INTERACTIONS

Use subtle animation where it improves the experience.

Potential areas:

-   splash
-   onboarding transitions
-   card appearance
-   button feedback
-   bottom sheets
-   match score reveal
-   status changes
-   map transitions
-   navigation transitions
-   loading states

Animations must be:

-   subtle
-   fast
-   purposeful
-   responsive
-   non-blocking

Avoid excessive animation.

------------------------------------------------------------------------

# 35. ICONS

Use a consistent icon family.

Do not mix unrelated icon styles.

Do not use emojis as icons.

Do not copy proprietary icons from the reference.

Prefer existing licensed/icon-library assets already used by the project
where appropriate.

------------------------------------------------------------------------

# 36. IMAGES AND ASSETS

Use:

-   original Sahyān assets
-   generated original assets
-   properly licensed assets

Do not copy protected images from the reference.

Do not introduce random stock images merely to fill empty space.

Assets must support the product.

------------------------------------------------------------------------

# 37. MAP DESIGN

Keep the existing free architecture:

-   FlutterMap
-   OpenStreetMap
-   OSRM
-   Nominatim
-   Geolocator

Do not add Google Maps billing.

Do not require a payment card.

Map UI must follow the visual language of the reference while remaining
technically functional.

Production routes must use real route geometry.

Do not use synthetic route geometry as a production fallback.

------------------------------------------------------------------------

# 38. DATA AND STATE

Flutter must not communicate directly with MongoDB.

Architecture remains:

``` text
Flutter
   ↓
REST / Socket.IO
   ↓
Express
   ↓
Mongoose
   ↓
MongoDB
```

Use existing Riverpod architecture.

Avoid unnecessary duplicate requests.

Use loading/error/empty states.

Never hide API failures with fake data.

------------------------------------------------------------------------

# 39. NO FAKE PRODUCTION DATA

Do not insert fake:

-   drivers
-   rides
-   routes
-   ratings
-   booking statuses
-   payments
-   GPS positions
-   notifications

for production UI.

Mocks may exist only for:

-   tests
-   explicit development previews
-   isolated UI development

They must not accidentally enter production flows.

------------------------------------------------------------------------

# 40. NO EMOJIS

ABSOLUTE RULE.

No emojis anywhere in:

-   UI
-   buttons
-   labels
-   text
-   comments
-   logs
-   errors
-   documentation
-   placeholders
-   commit messages

Use proper icons and text instead.

------------------------------------------------------------------------

# 41. SECURITY PRESERVATION

UI redesign must not weaken:

-   JWT
-   secure storage
-   role-based access
-   booking authorization
-   driver ownership
-   Socket.IO authentication
-   admin authorization
-   OTP security

Do not move sensitive business logic into Flutter.

------------------------------------------------------------------------

# 42. PERFORMANCE

Avoid:

-   unnecessary widget rebuilds
-   duplicate API calls
-   unnecessary provider recreation
-   huge unbounded lists
-   expensive map rebuilds
-   unnecessary animations
-   repeated location processing
-   excessive nested scrolling

Use pagination where appropriate.

Use efficient list builders.

Do not make unsupported performance claims.

------------------------------------------------------------------------

# 43. FOLDER STRUCTURE

Preferred final structure:

``` text
frontend/lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_typography.dart
│       ├── app_spacing.dart
│       ├── app_radii.dart
│       ├── app_elevation.dart
│       └── app_dimensions.dart
│
├── core/
│   ├── network/
│   ├── location/
│   ├── storage/
│   ├── services/
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── rides/
│   ├── bookings/
│   ├── trips/
│   ├── vehicles/
│   ├── profile/
│   ├── messages/
│   ├── notifications/
│   ├── payments/
│   ├── settings/
│   └── admin/
│
└── shared/
    ├── widgets/
    │   ├── buttons/
    │   ├── cards/
    │   ├── inputs/
    │   ├── navigation/
    │   ├── feedback/
    │   ├── maps/
    │   └── match/
    ├── models/
    └── extensions/
```

Do not create excessive abstraction.

Keep the project understandable for an MCA student who must explain the
architecture in a viva.

------------------------------------------------------------------------

# 44. FEATURE-FIRST RULE

Feature-specific widgets should stay inside their feature.

Example:

``` text
features/rides/presentation/widgets/
```

Shared widgets should be truly reusable.

Do not move every widget into `shared/`.

------------------------------------------------------------------------

# 45. FILE NAMING

Use clear names.

Preferred:

``` text
ride_details_screen.dart
search_results_screen.dart
match_explanation_card.dart
location_picker_bottom_sheet.dart
```

Avoid:

``` text
screen1.dart
new_screen.dart
test_screen.dart
final_screen.dart
final_screen_new.dart
screen_latest.dart
```

Do not use ambiguous names.

------------------------------------------------------------------------

# 46. REFACTORING RULE

Do not combine redesign and uncontrolled architecture rewriting.

If a legacy architecture problem prevents the UI redesign:

1.  identify the problem
2.  make the smallest safe architectural change
3.  migrate dependencies
4.  test
5.  continue redesign

Avoid unnecessary rewrites.

------------------------------------------------------------------------

# 47. SCREEN IMPLEMENTATION WORKFLOW

For every screen:

### Step 1 --- Inspect

Read the existing screen and dependencies.

### Step 2 --- Reference

Study the corresponding visual pattern in the primary reference.

### Step 3 --- Structure

Write down the target hierarchy before implementation.

### Step 4 --- Components

Identify reusable components.

### Step 5 --- Tokens

Use the central design tokens.

### Step 6 --- Implement

Redesign the presentation layer.

### Step 7 --- Preserve

Keep providers, APIs, models, and business logic.

### Step 8 --- States

Implement:

-   loading
-   success
-   empty
-   error

where applicable.

### Step 9 --- Responsive

Test all target widths.

### Step 10 --- Navigation

Verify all entry/exit paths.

### Step 11 --- Analyze

Run:

``` bash
flutter analyze
```

### Step 12 --- Test

Run relevant tests.

### Step 13 --- Cleanup

Remove obsolete code only after verifying no references remain.

------------------------------------------------------------------------

# 48. WORK IN SMALL BATCHES

Do not modify the entire application blindly in one operation.

Recommended batch size:

**1--3 related screens.**

After each batch:

1.  analyze
2.  test
3.  inspect
4.  fix
5.  continue

Keep the repository buildable.

------------------------------------------------------------------------

# 49. RECOMMENDED REDESIGN ORDER

## Batch 1

Design system App shell Bottom navigation App bar Home

## Batch 2

Location picker Search Search filters Search results

## Batch 3

Ride card Match score Match explanation Ride details

## Batch 4

Seat selection Booking review Payment Confirmation Booking details

## Batch 5

Offer/publish ride Driver dashboard Driver requests

## Batch 6

Boarding Active driver ride Trip completion

## Batch 7

Active journey Live tracking Safety SOS

## Batch 8

Profile Vehicles Emergency contacts Settings

## Batch 9

Messages Notifications Payments Help

## Batch 10

Admin Cleanup Router cleanup Legacy component removal

## Batch 11

Full responsive QA Real-device QA Final analyzer/tests

------------------------------------------------------------------------

# 50. DESIGN CONSISTENCY RULE

A user should feel that every screen belongs to the same application.

Maintain consistency in:

-   spacing
-   cards
-   typography
-   colors
-   buttons
-   icons
-   input fields
-   app bars
-   bottom navigation
-   status badges
-   map containers
-   bottom sheets
-   transitions
-   empty states
-   error states

Do not independently redesign each screen with different styling.

------------------------------------------------------------------------

# 51. DO NOT OVER-COPY THE REFERENCE

The reference is a visual source, not a license to clone another
product.

Reproduce:

-   hierarchy
-   rhythm
-   composition
-   interaction ideas
-   visual language

Create original:

-   Sahyān branding
-   logos
-   icons where needed
-   content
-   route-match UX
-   product-specific cards
-   illustrations
-   assets

------------------------------------------------------------------------

# 52. PRODUCT-SPECIFIC UI

The reference must be adapted to Sahyān.

Sahyān-specific UI should emphasize:

-   route match
-   pickup deviation
-   destination deviation
-   detour
-   time compatibility
-   seats
-   driver reliability
-   contribution
-   route transparency
-   safety
-   planned journeys

Do not make the product look like a generic taxi app.

------------------------------------------------------------------------

# 53. APPROVAL GATES

The coding agent must STOP and ask before:

-   changing global colors
-   changing typography globally
-   changing brand identity
-   introducing a new frontend framework
-   replacing Riverpod
-   replacing GoRouter
-   replacing map architecture
-   changing backend API contracts
-   changing database schema
-   changing authentication architecture
-   adding paid infrastructure
-   deleting a file with unclear dependencies
-   deleting an apparently duplicated screen when functional differences
    are uncertain

------------------------------------------------------------------------

# 54. SAFE AUTOMATION RULE

The agent may automatically:

-   refactor duplicate styling
-   migrate imports
-   consolidate verified duplicate widgets
-   create reusable components
-   improve responsive layout
-   improve spacing
-   improve typography usage
-   improve card/button/input consistency
-   remove verified unused UI code

provided that:

-   functionality remains intact
-   tests/analyzer remain healthy
-   global color approval is respected

------------------------------------------------------------------------

# 55. DELETION RULE

Never blindly delete files.

Before deletion:

``` text
Search references
      ↓
Inspect router
      ↓
Inspect providers
      ↓
Inspect imports
      ↓
Inspect tests
      ↓
Migrate
      ↓
Analyze
      ↓
Test
      ↓
Delete
```

------------------------------------------------------------------------

# 56. RESPONSIVE QA CHECKLIST

For every important production screen:

-   [ ] 320dp
-   [ ] 360dp
-   [ ] 390dp
-   [ ] 412dp
-   [ ] 600dp+
-   [ ] large text
-   [ ] keyboard visible
-   [ ] long content
-   [ ] loading state
-   [ ] empty state
-   [ ] error state
-   [ ] no overflow
-   [ ] no clipped text
-   [ ] no clipped buttons
-   [ ] no horizontal scrolling unless intentionally designed

------------------------------------------------------------------------

# 57. SCREEN QUALITY GATE

A screen is complete only when:

-   [ ] follows the primary reference's visual direction
-   [ ] preserves Sahyān identity
-   [ ] uses approved colors
-   [ ] uses design tokens
-   [ ] uses reusable components
-   [ ] preserves real functionality
-   [ ] uses real API/provider data
-   [ ] has loading state
-   [ ] has error state
-   [ ] has empty state where applicable
-   [ ] works on 320dp
-   [ ] works on 360dp
-   [ ] works on 390--412dp
-   [ ] handles larger font scale
-   [ ] handles keyboard
-   [ ] no pixel overflow
-   [ ] navigation works
-   [ ] no duplicate implementation
-   [ ] no fake production data
-   [ ] no emojis
-   [ ] analyzer passes
-   [ ] relevant tests pass

------------------------------------------------------------------------

# 58. PROJECT QUALITY GATE

The redesign is complete only when:

### Visual

-   [ ] all production screens follow one visual language
-   [ ] reference direction is consistently applied
-   [ ] Sahyān branding is consistent
-   [ ] typography is consistent
-   [ ] spacing is consistent
-   [ ] cards are consistent
-   [ ] buttons are consistent
-   [ ] navigation is consistent

### Architecture

-   [ ] one theme system
-   [ ] one authoritative button system
-   [ ] one authoritative input system
-   [ ] one authoritative card system
-   [ ] one authoritative navigation system
-   [ ] duplicate screens removed where appropriate
-   [ ] dead routes removed
-   [ ] obsolete widgets removed
-   [ ] debug screens isolated

### Functionality

-   [ ] authentication works
-   [ ] onboarding works
-   [ ] guest mode works
-   [ ] ride search works
-   [ ] route matching works
-   [ ] booking works
-   [ ] driver flow works
-   [ ] live trip works where implemented
-   [ ] safety flow works where implemented
-   [ ] profile works
-   [ ] settings work

### Technical

-   [ ] Flutter analyze passes
-   [ ] relevant tests pass
-   [ ] no runtime navigation errors
-   [ ] no overflow
-   [ ] no fake production data
-   [ ] no unnecessary dependencies
-   [ ] no unnecessary architecture rewrite

------------------------------------------------------------------------

# 59. IMPORTANT EXISTING PROJECT ISSUES

During redesign, also keep an eye on known technical issues.

## Route search variable shadowing

In:

``` text
backend/src/controllers/rideController.js
```

There is a known issue where an inner `const routeResult` shadows the
outer `routeResult`.

The intended pattern is:

``` javascript
let routeResult;

try {
  routeResult = await osrmRouteProvider.calculateRoute(...);

  if (routeResult?.success && routeResult.encodedPolyline) {
    passengerPoints = decodePolyline(routeResult.encodedPolyline);
  }
} catch (...) {
  // handle route failure
}
```

Do not reintroduce the shadowing bug.

## Synthetic production route fallback

Do not use fake/synthetic road geometry as the production search route.

If OSRM cannot produce a valid route:

-   show a proper unavailable/error state
-   or use an explicitly supported non-production mock environment

Do not present synthetic geometry as real navigation.

------------------------------------------------------------------------

# 60. BRANDING

Always use:

**Sahyān**

Preserve the macron.

Never use:

-   Sahyan
-   Sayan
-   another project name

Brand visual language:

-   intelligent
-   trustworthy
-   calm
-   modern
-   mobility-oriented
-   human
-   premium but accessible

Avoid generic taxi branding.

------------------------------------------------------------------------

# 61. DESIGN LANGUAGE

The application should feel:

-   modern
-   clean
-   spacious
-   trustworthy
-   premium
-   calm
-   technology-enabled
-   mobility-focused
-   human-centered

Avoid:

-   excessive gradients
-   excessive shadows
-   excessive glassmorphism
-   excessive rounded containers
-   visual clutter
-   too many colors
-   tiny typography
-   decorative UI without purpose

Any such treatment must be justified by the reference and product
context.

------------------------------------------------------------------------

# 62. CONTENT RULES

Use realistic product language.

Prefer:

"Find a ride"

"Offer a ride"

"94% Match"

"Pickup deviation"

"Route overlap"

"Low detour"

"3 seats available"

Avoid:

"AI MAGIC"

"Smart AI Ride"

"Super AI Match"

unless genuinely supported and appropriate.

Do not use meaningless marketing language inside functional UI.

------------------------------------------------------------------------

# 63. EMPTY / ERROR / LOADING STATES

Every data-driven screen should consider:

### Loading

Use a design-system loading state.

### Empty

Explain what happened and what the user can do.

Example:

"No matching rides yet"

"Try another time or expand your search."

### Error

Explain the problem without technical jargon.

Example:

"Unable to load rides"

"Please try again."

Do not expose raw stack traces.

------------------------------------------------------------------------

# 64. FORM UX

Forms must:

-   group related fields
-   show labels
-   provide validation
-   preserve entered data when possible
-   handle keyboard safely
-   avoid excessive scrolling
-   clearly indicate required fields
-   use consistent input components

Do not create one giant unstructured form.

------------------------------------------------------------------------

# 65. BUTTON HIERARCHY

Use clear hierarchy:

Primary: main action

Secondary: supporting action

Tertiary: low-emphasis action

Destructive: delete/cancel/emergency where appropriate

Do not make every button visually primary.

------------------------------------------------------------------------

# 66. CARDS

Cards should have a clear information hierarchy.

Avoid placing every piece of information inside a card.

Use:

-   title
-   supporting information
-   metadata
-   status
-   action

as appropriate.

Cards should not become nested-card chaos.

------------------------------------------------------------------------

# 67. BOTTOM SHEETS

Use bottom sheets when they improve mobile interaction, especially for:

-   location selection
-   filters
-   route details
-   map details
-   contextual actions

Bottom sheets must:

-   respect SafeArea
-   handle keyboard
-   scroll when needed
-   avoid overflow
-   have clear dismissal behavior

------------------------------------------------------------------------

# 68. MAP CARDS

Map previews should:

-   show meaningful route information
-   remain visually integrated
-   have clear expand behavior
-   not dominate unrelated screens
-   not rebuild unnecessarily

Full-screen maps should be used when navigation/tracking is the primary
task.

------------------------------------------------------------------------

# 69. CODE QUALITY

Do not leave:

-   commented-out old UI
-   duplicate widgets
-   dead imports
-   unused providers
-   obsolete routes
-   temporary naming
-   `final_final` files
-   debug prints
-   fake production values

Use clear code.

Keep widgets reasonably focused.

Do not over-engineer.

------------------------------------------------------------------------

# 70. DOCUMENTATION

This file is the permanent master specification.

If a major design decision is made later:

1.  update this file
2.  record the decision
3.  do not rely only on chat history

If the color palette is changed after approval, update the approved
palette here.

------------------------------------------------------------------------

# 71. CHANGE LOG

Maintain a concise redesign history in:

``` text
docs/UI_REDESIGN_CHANGELOG.md
```

Record:

-   date
-   screen/batch
-   files changed
-   components created
-   components consolidated
-   files removed
-   design decisions
-   approved color changes
-   known issues
-   tests performed

Do not put the full design specification into the changelog.

------------------------------------------------------------------------

# 72. CODING-AGENT EXECUTION RULE

When the user says:

"continue redesign"

"implement the UI"

"redesign next screen"

"continue"

or similar:

1.  read this file
2.  inspect current repository state
3.  identify the next unfinished batch
4.  inspect dependencies
5.  implement only the required scope
6.  run analyzer/tests
7.  verify responsive behavior
8.  update changelog
9.  report exactly what changed
10. identify the next recommended batch

Do not ask the user to repeat the complete redesign specification.

------------------------------------------------------------------------

# 73. FIRST ACTION AFTER THIS FILE IS ADDED

The first coding-agent action must be an audit.

Do NOT immediately redesign all screens.

Create:

``` text
docs/UI_REDESIGN_PLAN.md
```

The plan must contain:

1.  current screen inventory
2.  current router inventory
3.  current component inventory
4.  duplicate components
5.  duplicate screens
6.  obsolete files
7.  theme inconsistencies
8.  screens requiring complete redesign
9.  screens requiring partial redesign
10. screens that can remain mostly unchanged
11. target folder structure
12. target component architecture
13. migration order
14. responsive QA plan
15. risks
16. items requiring user approval

Do not perform destructive cleanup during the audit.

------------------------------------------------------------------------

# 74. FIRST USER APPROVAL GATE

Before implementation begins, show the user:

-   proposed global design-system changes
-   proposed color changes, if any
-   screen redesign order
-   duplicate/obsolete files proposed for removal
-   major architectural changes, if any

Only global color changes and other approval-gated changes require
explicit approval.

Normal implementation details can proceed according to this
specification.

------------------------------------------------------------------------

# 75. FINAL PRINCIPLE

Build Sahyān as a real product.

Do not treat the redesign as a screenshot recreation exercise.

The finished application must be:

-   visually coherent
-   faithful to the reference's design language
-   recognizably Sahyān
-   responsive
-   accessible
-   maintainable
-   technically functional
-   explainable in an MCA viva
-   based on reusable components
-   free of unnecessary duplicate code
-   free of fake production behavior
-   free of emojis
-   free of unnecessary frameworks
-   free of unnecessary architectural complexity

**Reference gives the visual direction.**

**Sahyān gives the product identity.**

**The existing application gives the functional foundation.**

**The design system connects all three.**
