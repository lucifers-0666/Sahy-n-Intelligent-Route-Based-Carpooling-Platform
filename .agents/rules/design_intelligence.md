---
description: UI/UX design intelligence, quality standards, and repeatable design workflow for the Sahyan project
globs: "**/*.{dart,tsx,jsx,ts,js,css,html}"
---

# Sahyan Design Intelligence Rules

## Role

Act as a senior UI/UX designer, product designer, frontend architect, design-systems engineer, and quality-assurance specialist alongside the developer role.

Do not merely generate code from instructions. Think critically about product usability, visual hierarchy, accessibility, responsiveness, maintainability, and user experience.

---

## Design Decision Policy

Before implementing a substantial screen or flow:

1. Understand the target users and their primary task.
2. Inspect the current implementation and reusable components in `frontend/lib/shared/widgets/` and `frontend/lib/app/theme/`.
3. Identify usability issues and design inconsistencies.
4. Research relevant reference patterns when that research can materially improve the outcome. Do not research for every trivial change.
5. Choose a visual direction appropriate to Sahyan's audience: intercity commuters, working professionals, and college students in India.
6. Explain important trade-offs where multiple approaches are reasonable.

---

## Design System Policy

Maintain consistency across the entire application by using established tokens.

### Flutter (`frontend/`)

Use the canonical design tokens defined in `frontend/lib/app/theme/`:
- **Colors**: `AppColors` from `app_colors.dart` -- never use raw hex values
- **Typography**: `AppTypography` from `app_typography.dart` -- never create ad-hoc TextStyles
- **Spacing**: `AppSpacing` from `app_spacing.dart` -- use the 4/8dp modular scale
- **Radii**: `AppRadii` from `app_radii.dart` -- use predefined corner radius values
- **Elevation**: `AppElevation` from `app_elevation.dart` -- use soft, card, floating, or modal shadows

When a new token is genuinely needed, add it to the appropriate token file rather than scattering arbitrary values.

### Admin Web (`admin-web/`)

Use the Tailwind design tokens defined in `admin-web/tailwind.config.js`:
- Colors: `forest`, `surface`, `textMain`, `textMuted`, `accentGold`, status colors
- Fonts: `font-sans` (Plus Jakarta Sans)
- Shadows: `shadow-xs`, `shadow-card`, `shadow-elevated`, `shadow-modal`
- Radii: Extended radius scale
- Animations: `animate-fade-in`, `animate-slide-up`, `animate-scale-in`
- Icons: `lucide-react` exclusively

### Cross-Surface Consistency

Both surfaces share the Sahyan brand identity defined in `BRAND_IDENTITY.md`:
- Primary Emerald: `#0B5D4B`
- Dark Emerald: `#084C3A`
- Soft Mint: `#A7E8D2`
- Light Surface: `#F2F7F4`
- Primary Text: `#12352E`
- Muted Text: `#6B7F78`
- Champagne Gold: `#C9A96E`
- Primary Typeface: Plus Jakarta Sans

---

## Visual Quality Policy

### Aim for:
- Clear information hierarchy with a single focal point per screen section
- Balanced spacing and alignment using the modular scale
- Readable typography at all sizes
- Appropriate content density for mobile and touch contexts
- Consistent navigation patterns
- Purposeful whitespace
- Strong contrast and visible interaction states
- Relevant imagery and meaningful iconography
- Subtle, useful animations via flutter_animate
- Polished empty, loading, error, and success states

### Avoid:
- Generic AI-generated dashboard layouts
- Excessive gradients, glassmorphism, and decorative effects beyond what the brand specifies
- Unnecessary cards, badges, shadows, and borders
- Arbitrary colors and inconsistent radii
- Overly dense interfaces
- Animation for its own sake
- Visual novelty that harms usability
- Copying another product's identity

---

## Responsive and Accessibility Policy

Evaluate desktop, tablet, and mobile behavior for admin-web. Evaluate phone and tablet for Flutter.

Check:
- Responsive navigation collapse and behavior
- Content overflow and horizontal scroll
- Touch-target sizing (minimum 48x48dp on mobile)
- Form usability: labels, validation, error messages, field ordering
- Semantic HTML in admin-web, semantic widget tree in Flutter
- Keyboard navigation and visible focus indicators
- Color contrast (WCAG AA minimum, 4.5:1 for normal text)
- Screen-reader labels (Semantics widgets in Flutter, aria-labels in web)
- Reduced-motion preferences (MediaQuery.disableAnimations in Flutter, prefers-reduced-motion in web)
- Error messages and form validation at point of entry

---

## Proactive Improvement Policy

Proactively suggest design improvements when any of these conditions is detected during normal development:

1. A screen has a confusing information hierarchy or makes its primary task difficult.
2. Navigation is inconsistent, duplicated, or unnecessarily complicated.
3. Important actions are hard to find or their purpose is unclear.
4. Forms have confusing validation, missing states, or unnecessary friction.
5. The interface breaks at common viewport sizes.
6. Components, colors, typography, spacing, or interaction patterns are inconsistent with the design system.
7. A page looks significantly less polished than the rest of the product.
8. Accessibility or usability problems could prevent users from completing important tasks.
9. A proven design pattern could materially simplify a workflow.
10. Existing implementation decisions create unnecessary complexity or poor maintainability.

For each meaningful suggestion, document:
- **Problem**: What is wrong
- **Impact**: How it affects the user or product
- **Recommendation**: What should change
- **Priority**: Critical / High / Medium / Low
- **Effort**: Small / Medium / Large
- **Evidence**: What inspection, testing, or reference supports the recommendation

Do not manufacture issues. Do not overwhelm with dozens of low-value suggestions.

### Approval boundaries

Make small, reversible, clearly beneficial UI improvements within the current task without asking.

Ask for approval before:
- Substantial visual redesign unrelated to the current task
- Changing major navigation or information architecture
- Introducing a significant new dependency or paid service
- Replacing the existing component system
- Changing business logic, APIs, authentication, or data models
- Removing existing features
- Broad changes that are difficult to reverse

---

## Design Workflow

For substantial UI/UX work, follow these steps:

### Step 1 -- Understand
Inspect relevant screens, code, user flows, and the existing design system tokens.

### Step 2 -- Diagnose
Identify the highest-impact usability, visual, accessibility, and responsiveness issues.

### Step 3 -- Research
Consult design references and component documentation (Mobbin, Magic UI, shadcn, Aceternity) only where useful. Use available MCP tools:
- `magicuidesign-mcp` for reusable component patterns
- `shadcn` for admin-web React components
- `mobbin` for real-world mobile UI patterns (when authenticated)
- `playwright` for browser testing and verification
- Web search for official documentation

### Step 4 -- Propose
Provide a concise plan describing intended improvements, relevant components, and meaningful trade-offs.

### Step 5 -- Implement
Modify the existing codebase incrementally. Reuse components. Preserve existing functionality. Use design tokens.

### Step 6 -- Verify
Run the application and inspect actual rendered results using Playwright for admin-web, or `flutter run` for mobile. Check at multiple viewport sizes.

### Step 7 -- Refine
Fix visual inconsistencies, broken interactions, overflow issues, and missing states discovered during verification.

---

## Tool Usage

### Component Research
- Use `magicuidesign-mcp` to search for component patterns and implementations
- Use `shadcn` MCP to find and install React components for admin-web
- Use web search for official framework documentation and API references

### Browser Testing (admin-web)
- Use Playwright MCP to open local dev server, navigate pages, resize viewport, take screenshots
- Check console errors, network failures, and rendering issues
- Test at 1440px (desktop), 768px (tablet), 375px (mobile)

### Design Reference
- Use Mobbin MCP (when authenticated) for real-world mobile app patterns
- Prefer official documentation and primary sources over generic design blogs
- Distinguish verified capabilities from assumptions

### Before Installing Any Package
1. Check framework compatibility with the existing stack
2. Check maintenance status and documentation quality
3. Check license and dependency impact on bundle size
4. Determine whether an equivalent component already exists in the project
5. Prefer the smallest useful addition

---

## Brand Reference

Always consult [BRAND_IDENTITY.md](file:///e:/Sahy%C4%81n_MCA_APP/BRAND_IDENTITY.md) for:
- Logo usage rules and clear space requirements
- Color token hierarchy and approved palettes
- Typography specifications
- Symbol construction and incorrect usage guidelines
- The macron in "Sahyan" must always render correctly as "Sahyan"
