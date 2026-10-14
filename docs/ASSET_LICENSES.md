# Sahyān — Asset Provenance & License Record

This document records the visual assets, vector graphics, and media included in the Sahyān mobile application codebase.

---

## 1. Vector Hero Illustration (`frontend/assets/branding/sahyan_highway_hero.jpg`)
- **Asset Description:** Flat vector art depiction of a generic, everyday compact hatchback/MPV traveling on a smooth Gujarat intercity expressway at sunrise. Includes faceless passenger and driver silhouettes, green Gujarat bilingual highway signage (`AHMEDABAD / VADODARA`), and wind turbines across the plains.
- **Source:** Generated specifically for Sahyān MCA Project via DeepMind visual synthesis tools under pair programming instructions.
- **License:** Proprietary project asset, licensed for open educational and commercial use in the Sahyān Route-Based Carpooling Platform.
- **Modifications:** Optimized resolution, color-calibrated to `#0B5D4B` (Brand Emerald), `#3DDC97` (Mint), and `#F5A524` (Sunrise Marigold). Converted for lightweight mobile display (< 250 KB).

---

## 2. Master Route Convergence Logos & Marks
- **Files:**
  - `frontend/assets/branding/sahyan_symbol.svg`
  - `frontend/assets/branding/sahyan_logo_horizontal.svg`
  - `frontend/assets/branding/sahyan_logo_stacked.svg`
  - `frontend/assets/branding/sahyan_logo_white.svg`
  - `frontend/assets/branding/sahyan_app_icon.svg`
- **Concept:** Geometric abstraction of two independent travel routes originating from distinct points, sweeping upward and converging into a single shared highway ending at a destination node pin.
- **Designer / Origin:** Custom hand-coded SVG & Flutter Canvas Vector implementations for Sahyān.
- **License:** MIT / Open Project License for Sahyān.

---

## 3. Typography
- **Font Family:** Plus Jakarta Sans
- **Designer:** Tokotype (Gumpita Rahayu)
- **License:** Open Font License (OFL 1.1)
- **Bundling:** Bundled via `google_fonts` package.
