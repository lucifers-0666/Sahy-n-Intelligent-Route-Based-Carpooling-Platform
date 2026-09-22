# Sahyān - Brand Identity & Design System Specification

**Project**: Sahyān — Intelligent Route-Based Carpooling Platform  
**Program**: Master of Computer Applications (MCA) Major Project  
**Author**: Sahyān Product & Design Engineering  
**Version**: 1.0 (Production Release)  

---

## Executive Summary

Sahyān is a peer-to-peer planned-route carpooling platform. Unlike on-demand taxi-hailing platforms, Sahyān enables drivers to publish planned intercity journeys and pairs them with passengers travelling along the same corridor through an explainable **Route Match Score** (e.g., *94% Match*).

This document establishes the official, original visual identity for Sahyān. It provides mathematical construction rules, color token hierarchies, typography specifications, logo variations, and mobile app UI applications suitable for production engineering and academic viva defense.

---

## Page 1: Brand Logo Hero Presentation

![Sahyān Hero Brand Presentation](file:///C:/Users/zaid%20amreliya/.gemini/antigravity-ide/brain/ee63094e-9564-4fbe-bf6a-958d2d68cc8a/sahyan_hero_brand_1790097335805.jpg)

### Brand Essence & Philosophy
* **Core Idea**: "Shared Journeys Along Intelligent Routes"
* **Tone**: Modern, Intelligent, Trustworthy, Premium, Human, Calm, Sustainable.
* **Tagline**: *Intelligent journeys, shared naturally.*

The identity deliberately moves away from literal clichés (such as taxicab checkers, steering wheels, generic GPS map pins, or artificial intelligence brains). Instead, it relies on a proprietary geometric symbol: **The Converging Corridor**.

---

## Page 2: Primary Logo (Symbol + Wordmark)

The Primary Logo is the signature lockup of Sahyān. It pairs the Converging Route Symbol with the custom geometric wordmark `Sahyān`.

```text
    [ SYMBOL ]   Sahyān
                 INTELLIGENT CARPOOLING
```

### Visual Rationale
1. **The Symbol**: Sits on the left as a forward-moving dynamic anchor.
2. **The Wordmark**: Features the exact brand spelling `Sahyān`, retaining the proper phonetic macron (`ā`) to ensure correct cultural and linguistic pronunciation.
3. **The Lockup Proportions**: Symbol height equals the cap-height of the wordmark (1.0x ratio), with an optical kerning space of 0.28x symbol width.

---

## Page 3: Symbol-Only Mark (The Converging Corridor)

The standalone symbol acts as the core geometric emblem across mobile application icons, avatars, system navigation, and favicon contexts.

### Symbolic Components:
1. **Upper Route Arc**: Represents the driver's planned highway corridor originating from their departure point.
2. **Lower Route Arc**: Represents the passenger's travel trajectory originating from their pickup location.
3. **Convergence Apex**: The central intersection where the two curves seamlessly synchronize into a single forward-pointing aerodynamic corridor.
4. **Focal Node**: A circular white coordinate point located at the convergence intersection, representing the optimal route matching lock.

---

## Page 4: Wordmark Specification

The wordmark is custom-proportioned for high legibility at micro and macro scales.

* **Base Typographic Family**: Geometric / Humanist Sans-Serif (inspired by Plus Jakarta Sans and Inter).
* **Weight**: ExtraBold (800) for "Sahyān", SemiBold (600) for optional subtitle.
* **Tracking / Letter Spacing**: `-0.6px` (tight, confident corporate posture).
* **The Diacritic (Macron `ā`)**:
  * Shape: Clean horizontal bar with subtle rounded caps (radius 1.75px).
  * Placement: Positioned 4px above the letter `a`, precisely matching the letter's stem thickness (3.5px).

---

## Page 5: Mobile App Icon

![Sahyān App Icon](file:///C:/Users/zaid%20amreliya/.gemini/antigravity-ide/brain/ee63094e-9564-4fbe-bf6a-958d2d68cc8a/sahyan_app_icon_1790097355798.jpg)

### Icon Specifications:
* **Background**: Deep Emerald Green (`#0B5D4B` to `#084C3A`) with a subtle radial gradient creating depth.
* **Silhouette**: Continuous smooth squircle (corner radius ~22.5% of total width, conforming to Android Adaptive Icon and iOS App Store standards).
* **Central Symbol**: Crisp white (`#FFFFFF`) route arcs converging into a luminous Soft Mint (`#A7E8D2`) forward apex.
* **Small-Size Rendering**: Tested and legible down to 24px and 48px without degradation.
* **Zero Clutter**: Strictly no text or tagline inside the app icon.

---

## Page 6: Logo Variations Family

To ensure maximum versatility across all digital and print mediums, the brand includes 10 approved lockups:

| Variation | Layout Description | Primary Use Case |
|---|---|---|
| **1. Primary Horizontal** | Symbol left + Wordmark right | App top bar, website header, official documents |
| **2. Stacked Vertical** | Symbol centered above Wordmark | Splash screen, login header, marketing collateral |
| **3. Symbol-Only** | Standalone Converging Route Symbol | App icon, favicon, vehicle window badge |
| **4. Wordmark-Only** | Sahyān text with macron | Editorial, inline copy, legal documents |
| **5. Circular Avatar** | Symbol centered in 1:1 circle | Social media profiles, user profile default avatar |
| **6. App Store Icon** | Squircle icon with gradient background | Google Play Store, Android home screen |
| **7. Monochrome Dark** | All elements in Solid Charcoal (`#12352E`) | Black-and-white print, official academic thesis |
| **8. Monochrome White** | All elements in Pure White (`#FFFFFF`) | Dark mode headers, dark vehicle wraps |
| **9. Green Brand Version** | Deep Emerald (`#0B5D4B`) with Soft Mint | Default high-contrast brand application |
| **10. Luxury Gold Accent** | Emerald green with Champagne Gold (`#C9A96E`) | Premium driver tier, VIP corridor badges |

---

## Page 7: Light & Dark Surface Applications

### Light Backgrounds (`#FFFFFF`, `#F2F7F4`):
* Symbol arcs: Deep Forest Green (`#0B5D4B`)
* Convergence apex: Soft Mint (`#A7E8D2`) or Dark Emerald (`#084C3A`)
* Wordmark: Primary Text Deep Emerald (`#12352E`)

### Dark Backgrounds (`#0B5D4B`, `#084C3A`, `#0F172A`):
* Symbol arcs: Pure White (`#FFFFFF`, 95% opacity)
* Convergence apex: Luminous Soft Mint (`#A7E8D2`)
* Wordmark: Pure White (`#FFFFFF`)

---

## Page 8: Color System

The Sahyān palette is rooted in sustainability, calm confidence, and intelligent mobility.

| Token Name | Hex Code | RGB | HSL | Role & Usage |
|---|---|---|---|---|
| **Primary Emerald** | `#0B5D4B` | `11, 93, 75` | `167°, 79%, 20%` | Primary brand color, headers, CTAs |
| **Dark Emerald** | `#084C3A` | `8, 76, 58` | `164°, 81%, 16%` | Secondary depth, active states, pressed buttons |
| **Soft Mint** | `#A7E8D2` | `167, 232, 210` | `160°, 59%, 78%` | Accent color, route glow, match indicators |
| **Light Surface** | `#F2F7F4` | `242, 247, 244` | `144°, 23%, 96%` | App background, card canvas, clean surfaces |
| **Primary Text** | `#12352E` | `18, 53, 46` | `168°, 49%, 14%` | High-contrast typography, headings |
| **Muted Text** | `#6B7F78` | `107, 127, 120` | `159°, 9%, 46%` | Subtitles, secondary metadata, captions |
| **Pure White** | `#FFFFFF` | `255, 255, 255` | `0°, 0%, 100%` | Card backgrounds, crisp icon fills |
| **Champagne Accent** | `#C9A96E` | `201, 169, 110` | `39°, 46%, 61%` | Optional subtle VIP badge / rating stars |

---

## Page 9: Typography

Sahyān uses clean, open geometric typography with high x-height for clear legibility in high-stress transit environments.

* **Primary Typeface**: Plus Jakarta Sans / Inter
* **Hierarchy**:
  * **Display Title (H1)**: Plus Jakarta Sans Bold (800), 24–32px, tracking -0.6px
  * **Section Header (H2)**: Plus Jakarta Sans SemiBold (700), 18–20px, tracking -0.3px
  * **Card Title (H3)**: Plus Jakarta Sans SemiBold (600), 15–16px
  * **Body Text**: Inter Regular (400) / Medium (500), 13–14px, line-height 1.5
  * **Metrics & Badges**: Plus Jakarta Sans ExtraBold (800), 11–13px, tracking +0.8px

---

## Page 10: Geometric Construction & Design Grid

![Sahyān Geometric Grid Blueprint](file:///C:/Users/zaid%20amreliya/.gemini/antigravity-ide/brain/ee63094e-9564-4fbe-bf6a-958d2d68cc8a/sahyan_brand_grid_1790097444701.jpg)

### Mathematical Geometry:
1. **Golden Ratio ($\Phi = 1.618$)**: The arc curvature radii ($R_1 = 60\text{mm}$, $R_2 = 37.1\text{mm}$) follow golden section proportions.
2. **Forward Momentum Vector**: The apex converges at an exact 45-degree angle ($\theta = 45^\circ$), giving a natural, aerodynamic sense of forward travel without aggressive sharp edges.
3. **Harmonic Radii**: All trajectory curves terminate with smooth G2 continuity, ensuring zero visual kinks when scaled up or down.

---

## Page 11: Clear Space Rules

To preserve brand dignity and visual prominence:

```text
       +---------------------------------------------+
       |                  [ X ]                      |
       |       +-----------------------------+       |
       | [ X ] | [ SYMBOL ]  Sahyān          | [ X ] |
       |       +-----------------------------+       |
       |                  [ X ]                      |
       +---------------------------------------------+
```

* **Clear Space ($X$)**: The minimum exclusion zone around the logo equals the height of the lowercase letter `a` in the wordmark.
* No text, buttons, graphics, or borders may intrude into this exclusion perimeter.

---

## Page 12: Minimum Size Rules

To guarantee readability across all digital viewports:

| Medium | Minimum Width (Horizontal Logo) | Minimum Size (Symbol Only) |
|---|---|---|
| **Mobile App (Android/iOS)** | 110 px | 24 px |
| **Web Browser (Desktop)** | 130 px | 28 px |
| **Favicon / System Tray** | N/A | 16 px |
| **Print / Academic Report** | 28 mm | 8 mm |

---

## Page 13: Incorrect Usage (Brand Violations)

To prevent brand dilution, avoid these common design mistakes:

1. **DO NOT rotate** the symbol or change the forward convergence direction.
2. **DO NOT remove the macron** over the letter `ā` (spelling must always be `Sahyān`).
3. **DO NOT change colors** to red, blue, purple, or neon lime green.
4. **DO NOT stretch, squash, or distort** the aspect ratio.
5. **DO NOT add heavy drop shadows, 3D extrusions, or bevels**.
6. **DO NOT place text inside the app icon squircle**.
7. **DO NOT replace the symbol with a generic car or pin icon**.

---

## Page 14: Mobile App Mockup

![Sahyān Mobile Application Showcase](file:///C:/Users/zaid%20amreliya/.gemini/antigravity-ide/brain/ee63094e-9564-4fbe-bf6a-958d2d68cc8a/sahyan_mobile_ui_1790097376108.jpg)

### Application Contexts Displayed:
1. **Splash Screen**: Deep emerald green canvas with the white-and-mint converging route symbol, centered `Sahyān` wordmark, and clean tagline.
2. **Active Home Dashboard**:
   * Top app bar with horizontal brand logo.
   * Corridor pickup and drop selection cards.
   * Prominent **94% Route Match** intelligent recommendation card.

---

## Page 15: Route Match Score Branding Language

The **Route Match Score** is the core product differentiator of Sahyān. It uses a dedicated, harmonious visual badge:

```text
      ( 94% )  94% Route Match
               Optimal Corridors Aligned
```

### Visual Features:
* **Concentric Progress Ring**: Rendered in Deep Emerald Green with a Soft Mint backing track.
* **Weight Breakdown**: Represents the explainable multi-factor calculation:
  * Route Overlap (40%)
  * Pickup Deviation (20%)
  * Destination Deviation (15%)
  * Time Compatibility (10%)
  * Driver Reliability (10%)
  * Available Seats (5%)
* **Consistency**: Directly utilizes the `SahyanRouteMatchBadge` Flutter widget (`frontend/lib/shared/widgets/sahyan_logo.dart`).

---

## Implementation & Asset Repository

All vector brand assets are stored in the project repository:

1. Standalone Symbol Vector: [frontend/assets/branding/sahyan_symbol.svg](file:///e:/Sahy%C4%81n_MCA_APP/frontend/assets/branding/sahyan_symbol.svg)
2. Primary Logo Vector: [frontend/assets/branding/sahyan_logo_primary.svg](file:///e:/Sahy%C4%81n_MCA_APP/frontend/assets/branding/sahyan_logo_primary.svg)
3. App Icon Vector: [frontend/assets/branding/sahyan_app_icon.svg](file:///e:/Sahy%C4%81n_MCA_APP/frontend/assets/branding/sahyan_app_icon.svg)
4. Production Flutter Widget: [frontend/lib/shared/widgets/sahyan_logo.dart](file:///e:/Sahy%C4%81n_MCA_APP/frontend/lib/shared/widgets/sahyan_logo.dart)
