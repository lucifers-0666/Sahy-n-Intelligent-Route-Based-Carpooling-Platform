# Sahyān Hybrid Mobile Design System

**Status:** Proposed implementation specification  
**Scope:** Flutter mobile application; initial rollout starts with app launch/auth entry and authentication, then expands after review.  
**Reference baseline commit:** `13a7d558e1f5814a9d7f64d29f65a72c57c91976`  
**Primary reference:** [JoyRide Ride-Sharing UI Kit — selected frame](https://www.figma.com/design/aGT8oN9vmeq0Mm7RAUWDZE/JoyRide---Ride-Sharing-App-UI-Kit--Preview-?node-id=32427-29884&t=oSEUUEo5yOPoHhiu-1)  
**Additional references:** [Glassmorphism Community file](https://www.figma.com/design/f4uqCnimBIdL5xNBLzdJEk/%F0%9F%99%80-Glassmorphism-is-on-Figma---Community-?node-id=1-1083&t=Oi3kdCSaWVHHSABR-1), [Figma Web Design Trends](https://www.figma.com/resource-library/web-design-trends/), [Dribbble modern app UI](https://dribbble.com/tags/modern-app-ui), [Figma Community mobile apps](https://www.figma.com/community/mobile-apps?resource_type=files&editor_type=figma).

## 1. Product and design intent

Sahyān is an intelligent, planned-route peer-to-peer carpooling platform, not an on-demand taxi service. The UI should communicate trust, shared journeys, route compatibility, safety, transparent fuel/toll cost sharing, and explainable matching.

Create an original hybrid visual language: borrow useful interaction patterns and information hierarchy from ride-sharing references, combine them with Sahyān's existing identity, and add restrained contemporary motion, depth, adaptive surfaces, dark mode, and accessible authentication. Do not copy any reference screen, logo, illustration, or proprietary artwork wholesale.

## 2. Existing architecture is authoritative

Preserve the current project stack and patterns:
- Flutter and Dart.
- Riverpod for state management.
- GoRouter for navigation.
- Existing API/repository/service architecture.
- flutter_secure_storage for sensitive local session material.
- FlutterMap, OpenStreetMap, OSRM, Nominatim and Geolocator for maps/location.
- Existing backend, JWT/OTP authentication and Socket.IO behaviour.

Do not add a second navigation or state-management framework, paid map APIs, or a web framework to the mobile app. Inspect `docs/UI_UX_MASTER_SAHYAN.md` before any UI change; this file supplements and does not silently override it. When specifications conflict, follow the explicit latest user instruction and document the conflict.

## 3. Brand tokens

Use the established palette unless a reviewed design experiment proves a token needs adjustment:
- Brand forest: `#0B5D4B`
- Deep emerald: `#084C3A`
- Mint accent: `#A7E8D2` (selective, not as a large-area default)
- Light background: `#F2F7F4`
- Surface: `#FFFFFF`
- Primary text: `#12352E`
- Muted text: `#6B7F78`
- Optional premium accent: `#C9A96E` (rare, purposeful use)
- Restricted/destructive states: accessible red with a documented light/dark pair.
- Success, warning, information and disabled states must have semantic tokens and must not rely on colour alone.

Typography: Plus Jakarta Sans, using a small, consistent scale for display, page title, section title, body, label, caption and numeric data. Verify font assets and licensing before adding or changing bundled fonts.

Create central light and dark ThemeData/ColorScheme definitions and shared spacing, radius, border, elevation, icon and motion tokens. Avoid per-screen arbitrary colours, spacing values, shadow recipes or corner radii. Do not force a complete global palette replacement as part of a single-screen experiment.

## 4. Visual principles

- Minimal, editorial hierarchy with compact but generous-enough spacing.
- Clear route-first information architecture.
- Crisp controls and carefully layered surfaces.
- Glass/translucent material only for limited overlays where content remains legible; never make every card glass.
- Shadows are subtle and functional, not a substitute for hierarchy.
- Consistent icon family and stroke weight; no emoji in UI, code, docs, assets or commit messages.
- No giant empty hero areas that push the primary action below the fold.
- No generic Material-default screen where a bespoke shared component is appropriate.
- No decoration that misrepresents a real feature or system state.
- Layouts must respect small Android screens, system bars, keyboard, safe areas and text scaling.

## 5. Motion system

Motion must communicate a cause-and-effect relationship:
- Tap/press feedback: subtle scale or tonal response.
- Navigation: short, coherent transition without disorienting movement.
- Logo animation: a short route-convergence sequence representing multiple journeys connecting; the mark settles into its static brand shape. Keep it brief and play it once at launch, not continuously.
- Loading: show only while a real operation is pending; use a branded, restrained progress indicator.
- Search field focus, origin/destination swap, selected tabs and status transitions need clear feedback.
- Respect reduced-motion preferences where practical; all motion must have a static fallback.
- Avoid repeated looping, excessive spring bounce, full-screen particle effects and heavy blur on low-end devices.
- Do not animate a success state before the server confirms success.

Use Flutter-native animation controllers/widgets where practical. Do not introduce Lottie or another package until checking existing dependencies and weighing asset size, accessibility and maintenance.

## 6. Brand mark and animated logo

Use a unique Sahyān route-convergence motif rather than copying Blinkit's delivery character or JoyRide's branding. The mark should be recognisable at app-icon scale and work in one colour, light/dark surfaces and static contexts.

The launch animation can draw two or three route strokes toward a shared junction, then resolve into the static route mark. Use a custom Flutter painter or a small local vector animation that the project already supports. The logo must not delay startup, block authentication-state resolution, or replay on every rebuild.

Use the mark in:
- Splash/launch screen.
- Welcome/auth entry.
- A small brand context in authentication pages.
- Appropriate empty/loading states where it adds value.

Do not put a large logo on every screen. Provide reduced-motion/static variants. Check app icon, Android launch theme and native splash configuration separately; a Flutter animation cannot replace native launch-screen constraints before Flutter starts.

## 7. Authentication and security UX

Authentication pages should have a consistent brand header, field styles, password visibility, validation, focus states, loading state and clear error recovery. Support existing password and OTP flows. Preserve existing biometric capability if implemented.

Biometric login:
- Must use the existing secure biometric service and operating-system prompt.
- Must never simulate a successful fingerprint/Face ID result.
- Must explain when no prior secure session exists and provide a safe password/OTP fallback.
- Must not store passwords or biometric data directly.
- Must not display a generic system error when a designed inline/banner message can explain the recoverable problem.
- Keep real authentication, token handling and suspension enforcement in existing auth/repository layers.

Do not claim passkeys or true passwordless auth unless the backend and platform support them.

## 8. Dark mode

Provide a genuine light/dark theme based on semantic tokens, not a simple global inversion. Use deep neutral/emerald surfaces, sufficient contrast, readable muted text, accessible borders, and distinct warning/error colours. Respect system theme by default and retain a user override only if the app already has or can safely add a persisted settings preference.

Check map labels, translucent overlays, fields, dialogs, bottom navigation, status bars and keyboard appearance in both themes.

## 9. Notifications, errors and feedback

Do not use default-looking SnackBar/toast messages as the sole interaction design for every event. Build a consistent feedback system with:
- Inline field validation for form errors.
- A compact, accessible in-app banner for recoverable network or account-state issues.
- A branded bottom sheet/dialog for important decisions and destructive confirmations.
- A non-blocking success confirmation for completed actions when appropriate.
- Persistent page-level error/retry state for failed data loading.
- A clear loading state while requests are pending.

Feedback must be accessible to screen readers, dismissible where appropriate, not cover primary controls, and never hide a real backend error. Avoid stacking duplicate messages. Do not suppress system-critical permission/authentication feedback simply to avoid a default component.

## 10. AI and personalization

Personalization is optional and evidence-based:
- It may reorder genuine saved/recent corridors or offer contextual shortcuts only when the data exists and the behaviour is explainable.
- Ask consent for sensitive personalization and location access.
- Provide a way to clear or disable personalization if introduced.
- Never fabricate AI-generated recommendations, real-time predictions, live traffic, prices, available rides or route-match percentages.
- Keep the core interface deterministic and usable without AI.
- A chatbot is not required for the first redesign; add one only if it solves a validated product need and has real backend capability.

## 11. Shared components to standardize

Create or improve a small reusable set aligned with the current code:
- BrandMark / AnimatedBrandMark.
- AppScaffold and page container.
- Primary, secondary, text and destructive buttons.
- Text fields with leading/trailing actions.
- Route input and route summary.
- Standard card/surface.
- Status indicator and semantic badge.
- Branded loading indicator.
- Inline form error, feedback banner and empty/error state.
- Confirmation bottom sheet/dialog.
- Consistent bottom navigation.
- Light/dark theme definitions and motion constants.

Do not create abstractions used by only one tiny element unless they clearly simplify that screen. Avoid a giant generic design framework.

## 12. Performance and accessibility

- Avoid unnecessary rebuilds and expensive blur.
- Dispose AnimationControllers and text controllers.
- Respect safe areas and the on-screen keyboard.
- Support text scaling and screen readers.
- Use meaningful semantics and minimum comfortable touch targets.
- Ensure readable contrast in both themes.
- Provide static fallbacks for motion.
- Use real app data and real API states.
- Test on a narrow phone and a typical Android device.

## 13. Definition of done for the first rollout

The first approval stage covers launch/welcome/auth entry and login only. Other screens must not be bulk-redesigned until the user approves the result.

The first rollout is done when:
- The design tokens and shared primitives exist in the repository.
- The launch/welcome/auth/login flow has a coherent visual language.
- The original Sahyān branding is retained and improved.
- A short, tasteful logo animation has a static fallback.
- Light and dark themes are usable.
- Existing password, OTP and biometric flows still work as supported.
- No fake data, fake biometric success or fake AI appears.
- Analysis and relevant tests are run and results reported honestly.
