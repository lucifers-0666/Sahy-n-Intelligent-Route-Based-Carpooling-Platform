# Sahyān – 2026 Redesign: Master Brief for AI Agents

**Version:** 1.0 (final consolidated). Replaces `DESIGN_BRIEF_2026_AUTH.md`.  
**Place in repo at:** `docs/SAHYAN_REDESIGN_AGENT_BRIEF.md`.  
**Audience:** AI coding / design agents working on this repository.  
**Project:** Sahyān, an intercity route-based carpooling platform for Gujarat, India (MCA project).  
**Stack:** Flutter app (`frontend/`), React admin (`admin-web/`), Node backend (`backend/`).  

---

## 0. How to use this document (agent rules)

1. Read sections 1–3 first. Then work in the phases of section 9, one phase at a time.
2. **VERIFY** every file path and claim in this brief with `grep` / `find` before editing. Paths come from a prior review and may have moved.
3. **Do not copy** any third-party design. References are mood only (section 2).
4. **Never use default Flutter UI** for feedback (SnackBar, default dialogs, CircularProgressIndicator, default page transitions). Use the custom components in section 6.
5. **After every phase:** `flutter analyze` and `flutter test` must pass. Existing tests assert on UI text and widget keys; when copy changes, **UPDATE the tests deliberately in the same commit**. Do not delete tests to make them pass.
6. Make small commits per task with clear messages. Do not rewrite files wholesale unless the task says so.
7. **Ask the human before:** changing backend API contracts, adding paid services, or deleting features.

---

## 1. Problem statement

The current app looks outdated and partly broken. Observed in a screen recording and in the code:

### Design problems
- **Everything has the same visual weight:** pale-mint chips on mint cards on a mint background, small grey captions. No clear primary action.
- **Mixed fonts:** many screens use `fontFamily: 'Plus Jakarta Sans'` as a raw string but the font is NOT declared under `fonts:` in `pubspec.yaml`, so those widgets fall back to Roboto while others use GoogleFonts.
- **Home screen is a jargon dashboard** ("Live Highway Corridors", "Live Telematics", "EV Fastlane", "Smart Surge Drop", "Zero Congestion Detected").
- **Splash is a tiny logo** on a flat colour. Welcome has an orphaned wrapped word in the guest card and uneven chips. Sign-in repeats the tagline.
- **Default Flutter toasts, spinners and dialogs** are used everywhere. A "Dev mode" red banner is visible in builds.
- **Profile has 12+ overlapping rows** (Personal Details vs Edit Profile; Payment Methods vs Payout vs Earnings). "Admin & Moderation Console" is reachable from the mobile profile and opens a dark web-style sidebar.
- **Navigation overlaps:** Rides, Bookings, Offer Ride, My Offered Rides.

### Functional / polish bugs seen
- Sign-in shows the biometric option before any session exists, then a red default toast: *"No saved session found. Please sign in once with password to enable biometrics."*
- Publish ride shows: `type '_Map<String, dynamic>' is not a subtype of type 'num?' in type cast` (find the unsafe cast in model parsing; may be in unpushed local code).
- "BOTTOM OVERFLOWED BY 8 PIXELS" on the route screen.
- Offered Rides filter tabs spin forever (no empty or error state).
- Offer Ride wizard step labels are truncated and the bottom nav stays visible inside the wizard. Default departure time is 1:15 AM.
- Help & Support is a placeholder dialog saying "upcoming releases".

### Structure problems (verify before acting)
- ~60 screens, ~50 routes with aliases; screens of 1,400–1,600 lines (`offer_ride_screen.dart`, `bookings_hub_screen.dart`, `driver_rides_screen.dart`).
- **Duplicates:** provider files in both `presentation/` and `presentation/providers/`; `user_model.dart` in `shared/models` and `features/auth/domain`; two theme folders (`app/theme/` and `core/theme/`); legacy button/text-field widgets; a misspelled map-widget shim; `ride_search_results_screen` duplicates.
- 160+ raw `Color(0x…)` and per-screen `TextStyle` instead of tokens.
- The earlier redesign plan (`docs/UI_REDESIGN_PLAN.md`) only restyled, because of "preserve keys and test assertions" rules. This brief supersedes that constraint (see rule 5).

---

## 2. References (inspiration only – DO NOT COPY)

- **JoyRide UI Kit** (Figma preview, commercial kit by a third party). Borrow ideas only: map-first home, draggable bottom sheet, 4-tab nav, one accent on a clean canvas, ride-card hierarchy, full state coverage (processing, requested, accepted, rejected, cancel reasons, rate, tip, receipt, settings sub-pages, light + dark pairs).  
  https://www.figma.com/design/aGT8oN9vmeq0Mm7RAUWDZE/JoyRide---Ride-Sharing-App-UI-Kit--Preview-?node-id=32427-29884  
  *Do NOT reuse its frames, photos, car images, icons or map styling. Result must be an original hybrid.*
- **Glassmorphism community file:** frosted panels over colourful depth shapes. Do NOT copy its pastel purple palette or its low-contrast text.  
  https://www.figma.com/design/f4uqCnimBIdL5xNBLzdJEk/
- **Quick-commerce delivery-partner artwork:** take the idea of an illustrated hero with personality only. Do NOT use any third-party brand, logo, character or colours.
- **Dribbble "modern-app-ui" tag and Figma Community mobile apps:** mood only.
- **Allowed illustration sources:** original vector work in Figma, or a permissively licensed set (check license before use and record it in `docs/ASSET_LICENSES.md`).

---

## 3. Design principles (2026)

1. **Minimal, intentional hierarchy:** one primary action per screen.
2. **Map-first for search and live trip;** draggable bottom sheets with 3 snap heights.
3. **Selective glass ("liquid glass"):** ONLY on auth sheet, toast, bottom nav, bottom sheets, floating search card. Never on body text blocks. Text on glass must keep WCAG AA.
4. **Functional motion:** animation explains state (loading, success, error, transition), 150–350 ms, spring easing. Splash logo is the only long animation (~1.8 s).
5. **Passwordless first:** Phone OTP primary, biometric after first successful login.
6. **Explainable personalization:** rule-based first; every prediction has a "Why am I seeing this?" and can be dismissed.
7. **Dark mode designed with variables from day one.**
8. **Accessibility:** min text 12 px, touch targets ≥ 48 px, AA contrast, works at 1.3× text scale, honours reduced motion.
9. **Plain language.** Remove jargon (corridor/telematics/surge) from user-facing copy.

---

## 4. Design tokens (v1 – final)

### 4.1 Colour (light)

| Token | Hex | Rules |
| :--- | :--- | :--- |
| **brand** | `#0B5D4B` | Brand, primary button, logo. 7.8:1 on white |
| **brandBright** | `#0F7A5F` | Links, active states, success. 5.3:1 on white |
| **ink** | `#0A1F1A` | Primary text, dark surfaces. 16:1 on canvas |
| **mint** | `#3DDC97` | Highlights on DARK surfaces, match ring, success fills. NEVER as text on white (1.8:1) |
| **marigold** | `#F5A524` | Price badge, key highlight FILLS with ink text (8.4:1). Never as text on white (2.0:1). For amber text on white use `marigoldText` |
| **marigoldText** | `#B45309` | Amber text on white (5.0:1) |
| **canvas** | `#F6F8F7` | Page background |
| **card** | `#FFFFFF` | Surfaces |
| **muted** | `#5B6B66` | Secondary text (5.3:1 on canvas). Replaces `#6B7F78` |
| **error** | `#D9483B` | Fills/icons. For small error TEXT use `#C23B2F` (verify AA) |
| **success** | `#0F7A5F` | Reuse `brandBright` |
| **warning** | `#B45309` | Reuse `marigoldText` |

**Colour rule:** brand ~60% (headers, primary button, logo), neutrals ~30%, mint + marigold ~10% accents. Do not use saffron/orange (religious/political connotation in India); use amber/marigold.

### 4.2 Colour (dark)

| Token | Hex |
| :--- | :--- |
| **bg** | `#0A1F1A` |
| **surface** | `#12302A` |
| **surfaceHigh** | `#1A3D36` |
| **text** | `#F2F7F5` |
| **muted** | `#9DB3AB` |
| **accent** | `#3DDC97` |
| **marigold** | `#F5A524` |

*Verify AA for every text/background pair; fix any that fail.*

### 4.3 Gradients and glass
- **Hero gradient:** `#0B5D4B` → `#0F7A5F`, with a soft mint glow `#3DDC97` at ~25% opacity behind the logo.
- **Glass:** backdrop blur 24, fill white 55% (dark: ink 45%), 1 px inner highlight white 40%. Provide an opaque fallback when blur is unavailable or reduced-transparency is on.

### 4.4 Typography
- **Font:** Plus Jakarta Sans only. BUNDLE it under `flutter: fonts:` in `frontend/pubspec.yaml` (weights 400, 500, 600, 700, 800) and reference it only from the theme.
- **Scale:** Display 34/38 bold, Title 22/28 semi-bold, Body 15/22 regular, Caption 12/16 medium (minimum). Tabular numerals (`FontFeature.tabularFigures()`) for OTP, time, price, match %.

### 4.5 Shape, spacing, elevation, icons
- **Radius:** sheet 28, card 20, input 16, pill full. Spacing 4/8/12/16/24/32. Touch target ≥ 48.
- Soft layered shadows, no hard 1 px borders on cards.
- One rounded icon set with ~1.75 px stroke (Phosphor or Lucide equivalent). No emoji anywhere (project has a zero-emoji policy).

### 4.6 Implementation location
All tokens live ONLY in `frontend/lib/app/theme/` (ThemeExtension for custom tokens, ColorScheme for Material mapping). Delete `core/theme/` after migrating usages.

---

## 5. Screens

### 5.1 Batch 1 – Auth / starting pages (do first)
*Each screen: light + dark, plus loading / error / offline variants where relevant.*

- **Splash:** brand gradient background. "Converging Corridor" symbol animates: two curved strokes draw in from the left, converge at the node, node pulses mint, wordmark "Sahyān" reveals, tagline "Where journeys find company" fades in (~1.8 s) then crossfade to Welcome. Implement with CustomPainter + PathMetric (no asset) or Lottie/Rive. No debug banner.
- **Welcome:** full-bleed ORIGINAL illustrated hero (Gujarat highway at sunrise, car with two riders, route line "Ahmedabad → Rajkot", subtle parallax and grain). Frosted glass bottom sheet: headline "Share the journey, not just the ride.", three trust chips on ONE row (Verified, Fair cost, Direct routes), primary "Continue with phone", text button "Explore as guest" (single line, no wrapping).
- **Sign in:** phone number first (+91 prefix, large field), primary "Get OTP", small link "Use email instead" (email/password secondary), consent line linking Terms and Privacy.
- **OTP verify:** 6 boxes, tabular numerals, SMS auto-read, resend timer ring; states: empty, filled, wrong code (250 ms shake + error toast), success (400 ms check morph).
- **Welcome back (returning user):** time-based greeting with name and avatar, last-route chip, one large biometric button with fingerprint/face animation, link "Use another account". The biometric option appears ONLY after a first successful login with enrolled device (fixes the "No saved session" error).

### 5.2 Batch 2 – Home / Search
Full-bleed MUTED map (custom light/dark tiles, minimal POIs, attribution kept), faint route corridor with animated driver dots, floating glass search card (From/To with swap, Date chip, Seats stepper, 52 px primary "Find rides"), draggable glass sheet: saved places chips, "Suggested for you" (explainable, dismissible), 2 compact ride cards with Match % ring and marigold price, "12 drivers on this route" live indicator (pulsing mint dot). Floating glass bottom nav.

### 5.3 Later batches (outline)
- **Results → Ride details (shared-element expand) → Request seat → Requested/Accepted/Rejected → Chat → Live trip** (route card on top, sheet with driver, chat/call, SOS + Share trip always visible) → Rate + tip → Receipt.
- **Trips tab** with segmented control "As passenger | As driver" (Upcoming / Pending / Past), replacing Rides + Bookings + My Offered Rides.
- **Offer Ride wizard** (3 steps, bottom nav hidden, large map preview, sensible default time).
- **Inbox:** Messages | Notifications.
- **Account:** ≤ 4 groups (Account [merge Personal + Edit], Driver [vehicles, offered rides, earnings, payout], Safety, Settings & Help). Remove the admin console entry from mobile; admin lives in `admin-web/`.
- **Navigation:** Home, Trips, Inbox, Account; "Offer ride" action only for verified drivers.

---

## 6. Custom components (replace ALL defaults)

Create under `frontend/lib/shared/widgets/` (or `app/components/`), exported from one barrel file.

- **SahyanToast:** glass pill sliding from top (250 ms): icon + title + message + optional action + thin auto-dismiss progress line + haptic. Types: success, info, warning, error. Swipe to dismiss. Queue multiple.
- **FeedbackService:** single API: `FeedbackService.toast(type, title, message, {action})`, implemented with OverlayEntry. Replace every ScaffoldMessenger/SnackBar call; add a lint or grep check in CI.
- **SahyanDialog, SahyanSheet:** glass, radius 28, spring open.
- **SahyanLoader:** animated logo loader; Skeleton* shimmer widgets for lists and cards. Remove CircularProgressIndicator from UI code.
- **SahyanButton:** variants primary/secondary/text; press scale 0.97 + light haptic; loading state morphs to progress ring; disabled state.
- **SahyanTextField:** floating label, focus ring, inline validation (icon + message), no default red underline.
- **SahyanChip, StatusBadge, MatchRing, RideCard, RouteTimeline, EmptyState, ErrorState** (all states required).
- **Page transitions:** shared-axis / fade-through via go_router CustomTransitionPage; shared-element (Hero) for card → details.
- **Reduced motion:** if `MediaQuery.of(context).disableAnimations` is true, use crossfade only.

---

## 7. Personalization and "AI" (phase-gated)

### Phase A (now, rule-based, no model)
- Greeting by time of day and name; remember last login method and show it first; last-route chip; suggested route from booking history and time of day.
- Every suggestion has "Why am I seeing this?" and a dismiss action.

### Phase B (later)
- "Ask Sahyān" assistant chip, natural-language search ("ride to Surat tomorrow 8am") → fills the search form. Implement via backend `POST /assistant/parse-intent` that calls an LLM SERVER-SIDE. Never ship API keys in the app. Always show the parsed result for user confirmation before searching.

---

## 8. Backend / API tasks (confirm with human before changing contracts)

- **OTP:** verify existing send/verify endpoints; add rate limit, expiry, attempt lockout.
- **Biometric:** after login, store refresh token in `flutter_secure_storage`; unlock with `local_auth`. Add `POST /auth/biometric/enroll` (device id binding) and revoke on logout.
- **GET /rides/suggestions (rule-based), GET /users/me/upcoming-trip**, corridor activity count (Mongo aggregation, optional Socket.IO push) for "N drivers on this route", saved route alerts ("Notify me" on empty results).
- **Fix JSON model parsing** with typed models; remove unsafe `as num` casts (see bug in section 1).
- **Remove any mobile-only admin entry;** keep admin APIs behind admin auth for `admin-web/`.

---

## 9. Phased implementation plan

### Phase 0 – Foundations (no visual change yet)
- Bundle Plus Jakarta Sans in `pubspec.yaml`; remove raw `fontFamily` strings.
- Create tokens in `app/theme/`, ThemeData light + dark; migrate `core/theme/` usages; delete it.
- Remove duplicate providers/models/widgets/screens listed in section 1 (verify with grep first; update imports; keep tests green).
- Disable debug banner; make sure release builds show no "Dev mode".
- *Done when:* `flutter analyze` clean, tests pass, grep finds no raw hex colours or `fontFamily:` strings outside `app/theme/`.

### Phase 1 – Components
- Build section 6 components with a widgetbook-style demo screen or golden tests. Replace all SnackBar/spinner/dialog usage.
- *Done when:* grep finds zero `SnackBar`, `ScaffoldMessenger.of`, `CircularProgressIndicator` in `features/`.

### Phase 2 – Auth batch (section 5.1)
- Implement Splash, Welcome, Sign in (OTP), OTP verify, Welcome back, with light + dark, animations, haptics, reduced-motion.
- Implement biometric gating logic and backend tasks for OTP/biometric.
- Update auth tests; add widget tests for each state (error, success, offline).

### Phase 3 – Navigation + Account
- New 4-tab shell, Trips merge, Account regrouping, remove mobile admin entry, real Help & Support screen (contact, FAQ).

### Phase 4 – Home / Search / Results / Details
### Phase 5 – Booking, chat, live trip, rating, receipt
### Phase 6 – Offer Ride wizard, driver tools, earnings
### Phase 7 – Polish
- Empty/error/skeleton states everywhere, fix overflow and infinite spinners, accessibility audit, performance pass, route cleanup (≤ ~20 real routes, no aliases).

---

## 10. Definition of done (every screen)

- Uses only tokens and shared components; no inline hex, no raw TextStyle.
- Light and dark verified; AA contrast; text scale 1.3 does not overflow.
- Loading (skeleton), empty, error, offline states exist.
- No default toast/dialog/spinner/transition.
- Reduced-motion path works.
- No RenderFlex overflow in debug console; no unsafe casts.
- Tests updated and passing; `flutter analyze` clean.
- Screenshot (light + dark) added to `docs/screens/<screen>.png`.

---

## 11. Figma generation prompt (for a design agent / Figma Make)

```
Design 5 mobile screens (390×844) + a feedback component set for "Sahyan", an intercity route-based carpooling app for Gujarat, India. Light and Dark for each. Use Auto Layout, components, variables, 8pt grid, named layers.

STYLE: modern 2026 mobile UI. Clean minimal layouts, one illustrated hero with personality, selective frosted glass (only bottom sheet, toast, nav), soft depth, functional micro-interactions. NOT default Material.

REFERENCES (mood only, do not copy frames, art or branding):
JoyRide kit: https://www.figma.com/design/aGT8oN9vmeq0Mm7RAUWDZE/JoyRide---Ride-Sharing-App-UI-Kit--Preview-?node-id=32427-29884
Glassmorphism community file: https://www.figma.com/design/f4uqCnimBIdL5xNBLzdJEk/

Hero: bold brand-colour background with a friendly flat vector illustration, ORIGINAL: a Gujarat highway at sunrise, a car with 2 riders, a route line labelled "Ahmedabad > Rajkot", subtle grain, no copied characters.

TOKENS: brand #0B5D4B, brandBright #0F7A5F, ink #0A1F1A, mint #3DDC97 (accent on dark only), marigold #F5A524 (fills with ink text; amber text #B45309), canvas #F6F8F7, card #FFFFFF, muted #5B6B66, error #D9483B.
Dark: bg #0A1F1A, surface #12302A, surfaceHigh #1A3D36, text #F2F7F5, muted #9DB3AB. Hero gradient #0B5D4B to #0F7A5F with mint glow 25%.
Font Plus Jakarta Sans: Display 34/38, Title 22/28, Body 15/22, Caption 12/16 (min 12). Radius: sheet 28, card 20, input 16, pill full.
Glass: blur 24, white 55% (dark: ink 45%), 1px inner highlight. AA contrast. One rounded 1.75px icon set. No emoji.

Screens:
1. Splash: gradient, centred "Converging Corridor" symbol (two curved strokes merging into a node), wordmark "Sahyan", tagline "Where journeys find company". Add 4 keyframes of the logo animation.
2. Welcome: full-bleed illustrated hero (top 60%), frosted glass bottom sheet: headline "Share the journey, not just the ride.", 3 trust chips on ONE row (Verified, Fair cost, Direct routes), primary "Continue with phone", text button "Explore as guest" (single line).
3. Sign in: big phone field with +91, "Get OTP" primary, link "Use email instead", consent line "By continuing you agree to Terms and Privacy".
4. OTP verify: 6 boxes (tabular numerals), resend timer ring; states: empty, filled, wrong code (shake + error toast), success (check morph).
5. Welcome back: time-based greeting with name and avatar, last route chip, large biometric button, link "Use another account".

Feedback components:
Toast (glass pill from top; icon, title, message, optional action, thin dismiss line; success/info/warning/error), Dialog and bottom sheet (glass, radius 28), Loader (animated logo + skeleton shimmer), Button states (default, pressed scale .97, loading ring, disabled), Input states (default, focus, filled, error with icon + message).

Prototype (Smart Animate, annotate durations):
Splash logo draw 900 ms then crossfade 300 ms.
Sheet springs up 300 ms.
Button press scale .97.
OTP shake 250 ms on error.
Check morph 400 ms on success.
Toast slide-in 250 ms.
Reduced motion: crossfade only.

DELIVER pages: Foundations, Components, Auth Light, Auth Dark, Prototype.
```

---

## 12. Out of scope / do not do

- No AR/3D features, no voice assistant yet, no paid map SDKs, no copying third-party UI kits, no emoji, no removing existing features without human approval, no committing secrets.
