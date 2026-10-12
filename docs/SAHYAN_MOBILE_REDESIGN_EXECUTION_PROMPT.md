# Antigravity Execution Prompt — Sahyān Mobile UI/UX Redesign

Read these repository documents first:
1. `docs/UI_UX_MASTER_SAHYAN.md` — existing master specification.
2. `docs/SAHYAN_HYBRID_MOBILE_DESIGN_SYSTEM.md` — approved design direction for this work.

Reference design:
https://www.figma.com/design/aGT8oN9vmeq0Mm7RAUWDZE/JoyRide---Ride-Sharing-App-UI-Kit--Preview-?node-id=32427-29884&t=oSEUUEo5yOPoHhiu-1

Other inspiration:
https://www.figma.com/design/f4uqCnimBIdL5xNBLzdJEk/%F0%9F%99%80-Glassmorphism-is-on-Figma---Community-?node-id=1-1083&t=Oi3kdCSaWVHHSABR-1
https://www.figma.com/resource-library/web-design-trends/
https://dribbble.com/tags/modern-app-ui
https://www.figma.com/community/mobile-apps?resource_type=files&editor_type=figma
https://www.designstudiouiux.com/blog/mobile-app-ui-ux-design-trends/

## Mission

Create an original, cohesive, modern Sahyān mobile design. Blend JoyRide-inspired ride-discovery usability, restrained glass/depth, minimalism, meaningful micro-interactions, accessible dark mode, secure biometric entry and a brand-owned animated route logo. Do not copy any reference screen or brand wholesale.

## Critical scope gate

Implement **only Phase 1: splash/launch, welcome/auth-entry and login**. Audit the Home screen and existing design tokens for compatibility, but do not redesign Home or every feature yet. We will approve this first group before expanding to registration, OTP, recovery, Home, search, ride details, booking, publishing, tracking, profile and settings.

## Inspect before editing

- Check branch, git status, uncommitted work and recent commits.
- Read the two design documents above.
- Inspect `frontend/lib/core/theme/app_theme.dart`, existing shared logo/widgets, splash/onboarding/welcome/auth-decision/login/auth/OTP screens, GoRouter configuration, biometric service, auth provider/repository, `pubspec.yaml`, native Android splash/icon assets and relevant tests.
- The current login screen appears to prefill an OTP phone field with a sample number. Check whether this is test-only or visible in normal builds; remove unintended production prefill and never prefill real user credentials.
- Check why the supplied screenshots show a full-screen green startup view with a tiny route logo, a red “Dev mode” overlay, and an Android biometric prompt that says no saved session was found. Trace the real source of each issue. Do not merely hide the symptoms.

## Design implementation

1. Establish shared semantic tokens for light and dark themes, typography, spacing, borders, radii, elevation, icons and motion.
2. Preserve the approved Sahyān palette: `#0B5D4B`, `#084C3A`, `#A7E8D2`, `#F2F7F4`, `#FFFFFF`, `#12352E`, `#6B7F78`, with `#C9A96E` used sparingly.
3. Create a new original route-convergence brand mark. Do not imitate the Blinkit character or copy JoyRide's logo. Use a compact animated route-line convergence that resolves into the static mark.
4. Integrate the mark in Flutter splash/welcome/auth surfaces, and inspect native splash and app icon separately. Do not block app startup with a long animation.
5. Redesign the welcome screen with a strong hierarchy, short product message, genuine trust/cost-sharing attributes, clear Create Account / Log In actions and guest exploration only if guest mode really exists.
6. Redesign login with password and OTP modes supported by the current app, accessible fields, inline validation, loading states, password visibility, clear recovery links, and a biometric option only when the secure service confirms that a valid previously authenticated session is available.
7. Provide a polished explanation/fallback when biometrics are unavailable or no saved session exists. Never simulate biometric success, store biometric data, or bypass the existing authentication provider.
8. Add true light/dark theme support with semantic colours. Respect system preference; do not implement dark mode by inverting all colours.
9. Replace generic default-looking feedback with a small reusable Sahyān feedback system: inline errors, branded accessible banners, purposeful confirmation sheets and page-level retry states. Do not replace all feedback with custom popups; choose the correct interaction for severity and duration.
10. Add tasteful, functional micro-interactions: button response, focused fields, auth mode transitions, route-logo intro and loading feedback. Respect reduced motion where practical. Avoid constant loops, excessive blur and expensive animations.
11. Ensure responsive layouts, safe areas, keyboard scrolling, text scaling, contrast and touch targets.
12. No emojis in UI/code/comments/docs/commit messages.

## Functional and security requirements

- Keep Flutter, Riverpod, GoRouter, current HTTP layer, JWT/OTP flow and secure storage architecture.
- Do not add a second state-management/navigation framework.
- No paid map service dependency.
- No API keys, credentials, passwords, JWT secrets or privileged tokens in frontend source.
- No fake AI, fake live data, fake guest functionality, or fake biometric login.
- Do not change backend authentication semantics just to make the UI easier. If a backend change is truly required, explain why, implement it minimally, add tests and document the API contract.
- Preserve existing user flows and deep links.
- Do not remove or rename files without checking all callers and tests.

## Verification

Run commands from the `frontend/` directory as appropriate:
- `flutter pub get` only if dependency changes require it.
- `dart format` on changed Dart files.
- `flutter analyze`.
- Relevant authentication/widget tests and existing test suite.
- Build or launch the app if the environment supports it.

Inspect at least a short Android viewport and a taller viewport. Check light/dark, keyboard open, loading, validation failure, OTP mode, biometric unavailable, and normal successful-auth navigation. State clearly if any visual verification could not be performed.

## Deliverables

- Implemented Phase 1 screens and shared design primitives.
- A short design decision record in `docs/SAHYAN_MOBILE_REDESIGN_PHASE1.md`.
- Files changed and rationale.
- Existing behaviour preserved.
- Actual test/build results, with failed or unrun checks identified.
- A short list of reusable rules for the next screen batch.

Stop after Phase 1 and request design approval. Do not proceed to a full-app redesign until I approve this first group.