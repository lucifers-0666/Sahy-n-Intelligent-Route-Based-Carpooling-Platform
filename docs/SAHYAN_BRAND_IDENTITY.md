# Sahyān Brand Identity & Master Logo Guidelines

## 1. Brand Concept & Etymology

**Sahyān** (સહયાન / सहयान) stems from Gujarati/Sanskrit:
- *Sah* (સહ) — Together, in unison, shared.
- *Yān* (યાન) — Vehicle, journey, transit.

Sahyān represents intercity route-based carpooling for Gujarat, India. The core identity must communicate **two distinct journeys converging into one shared path**, reducing highway emissions and transit costs while ensuring verified safety.

---

## 2. Six Logo Concepts Evaluated

| Concept # | Concept Name | Graphic Description | Evaluation & Verdict |
| :--- | :--- | :--- | :--- |
| **01** | The Dynamic S-Ribbon | Two ribbon paths intertwining to form a subtle 'S' letterform. | Rejected: Looked like a standard software SaaS icon; did not convey route convergence. |
| **02** | Highway Interlock | Two highway lanes weaving together like an infinity loop. | Rejected: Too intricate at 24px; resembled highway flyovers rather than unified carpooling. |
| **03** | The Compass Arrow | Compass rose with dual arrows meeting at the northern tip. | Rejected: Looked like outdoor navigation / GPS tool rather than shared mobility. |
| **04 (Selected)** | **The Route Convergence Mark** | **Two smooth curved route lines gracefully converging into a single vertical corridor ending in a solid destination node.** | **SELECTED MASTER MARK**: Unambiguous metaphor of shared transit, bold geometry, zero tiny details, exceptionally legible down to 24px, scalable vector path. |
| **05** | Twin Waypoint Shield | Dual waypoints enclosed inside a verified security shield. | Rejected: Too heavy visually; obscured the core motion of traveling together. |
| **06** | The Gujarat Transit Knot | Organic Gujarati calligraphic loop symbolizing unified commuters. | Rejected: Complex flourishes that degraded at small Android notification/app bar sizes. |

---

## 3. Selected Master Mark Specifications

### Geometric Definition
- **Canvas Base**: 100 x 100 viewBox coordinate system.
- **Left Route Stroke**: Starts at `(24, 76)`, sweeps smoothly through cubic bezier curve `C (24, 52), (48, 50), (48, 38)` into the central corridor.
- **Right Route Stroke**: Starts at `(76, 76)`, sweeps smoothly through cubic bezier curve `C (76, 52), (52, 50), (52, 38)` into the central corridor.
- **Converged Path**: Central vertical corridor between `y = 38` and `y = 26`, stroke width `12px`, with rounded line caps (`stroke-linecap="round"`).
- **Destination Terminal Node**: Solid circular node centered at `(50, 18)` with radius `r = 7.5px`.
- **Pulse Emission Ring**: Outer concentric circle at `(50, 18)` with radius expanding from `10px` to `24px` during splash/interactive feedback.

```
          (50, 18) [Node]
             │
             │ (Converged Corridor)
           ╱   ╲
          ╱     ╲
         ╱       ╲ (Curved Route Inlets)
      (24,76)   (76,76)
```

---

## 4. Master Logo Lockup System

### 1. App Icon
- **Container**: Squircle / rounded rectangle (24% corner radius) filled with Emerald `#0B5D4B`.
- **Mark**: Centered Route Convergence Mark rendered in Mint `#3DDC97` with white highlight node.
- **File**: `frontend/assets/branding/sahyan_app_icon.svg`

### 2. Horizontal Lockup
- **Structure**: Route Convergence Mark (`32dp` height) on left + `12dp` spacing + wordmark **Sahyān** in Plus Jakarta Sans Bold (`20sp`, tracking `-0.4sp`).
- **File**: `frontend/assets/branding/sahyan_logo_horizontal.svg`
- **Widget**: `SahyanLogo.horizontal(size: 32)`

### 3. Stacked Lockup
- **Structure**: Route Convergence Mark (`48dp` height) centered + `14dp` vertical spacing + wordmark **Sahyān** (`22sp`) + `4dp` spacing + micro-tagline **VERIFIED GUJARAT INTERCITY** (`9.5sp`, tracking `1.8sp`).
- **File**: `frontend/assets/branding/sahyan_logo_stacked.svg`
- **Widget**: `SahyanLogo.stacked(size: 48, showTagline: true)`

### 4. Monochrome White Lockup
- **Structure**: 100% white mark (`#FFFFFF`) with white wordmark for dark surfaces, photographic banners, and deep forest gradient splash.
- **File**: `frontend/assets/branding/sahyan_logo_white.svg`
- **Widget**: `SahyanLogo.mono(size: 32)`

### 5. Dark Mode Variant
- **Surface**: Midnight Ink `#0A1F1A` or Canvas Dark `#11231E`.
- **Mark**: Mint `#3DDC97` with clean contrast against dark surfaces.

---

## 5. Clear-Space & Minimum Sizing Rules

- **Clear Space**: Maintain minimum clear space equal to `0.5X` around all edges of the mark, where `X` is the height of the destination node (`15px` in a `100px` mark). No typography, borders, or iconography may penetrate this exclusion boundary.
- **Minimum Size**:
  - Standalone Mark: Minimum `24px` x `24px` (`dp`).
  - Horizontal Lockup: Minimum `28px` height.
  - Stacked Lockup: Minimum `48px` height.
- **Zero Distortion**: The aspect ratio (1:1 for mark) must never be skewed, stretched, or artificially italicized.

---

## 6. Official Color Palette

| Token Name | Hex Code | Usage | Role in Brand Hierarchy |
| :--- | :--- | :--- | :--- |
| **Brand Primary** | `#0B5D4B` | Primary buttons, headers, active states, Android theme | The core Sahyān green; confident, professional, calm |
| **Brand Bright** | `#0F7A5F` | Button hover/pressed states, card highlights | Secondary forest elevation |
| **Primary Mint** | `#3DDC97` | Brand mark on dark backgrounds, pulse indicators, success badges | High-energy tech accent for dark modes only |
| **Marigold** | `#F5A524` | Match score pills (`94% Match`), verified badges | Strictly ONE highlight per screen |
| **Ink** | `#0A1F1A` | Primary headlines, dark theme canvas, high-contrast text | Deepest neutral; never pure black |
| **Muted Text** | `#5B6B66` | Body text, secondary sublines, hint labels | Complies with WCAG AA 4.5:1 contrast against `#F6F8F7` |
| **Canvas** | `#F6F8F7` | Light mode page background | Clean tinted neutral; avoids sterile pure white |
| **Card Surface** | `#FFFFFF` | Bento containers, elevated input tiles | Elevated layered surfaces |

---

## 7. Single Source of Truth in Codebase

All screens utilize the unified widget implementation:
- **Widget**: `frontend/lib/shared/widgets/sahyan_logo.dart` (`SahyanLogo`)
- **Animated Splash Implementation**: `frontend/lib/shared/widgets/sahyan_route_convergence_logo.dart` (`SahyanAnimatedRouteLogo`)
- **Native Android Splash**: `frontend/android/app/src/main/res/drawable/launch_background.xml` (matching `#0B5D4B` and vector mark)
- **Vector Assets**:
  - `frontend/assets/branding/sahyan_symbol.svg`
  - `frontend/assets/branding/sahyan_logo_horizontal.svg`
  - `frontend/assets/branding/sahyan_logo_stacked.svg`
  - `frontend/assets/branding/sahyan_logo_white.svg`
  - `frontend/assets/branding/sahyan_app_icon.svg`
