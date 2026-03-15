# Nightlight Design System

Warm, intimate, premium dark-mode design language for 3am parents.

## Problem

MomCare's current design system looks and feels generic. The typography is 4 system-default tokens, every card is `.ultraThinMaterial` on pure black, and every screen follows the same VStack + card pattern. There is no visual signature, no depth hierarchy, no typographic personality, and no motion design language. The app works but doesn't have a point of view.

## Design Direction

"Nightlight" -- the warm glow of a phone screen in a dark nursery. Premium comes from craft, restraint, and warmth -- not complexity. Three layers build on each other:

- **Foundation**: Typography, color, spacing, elevation (the "bones")
- **Polish**: Pow transitions and effects (the "texture")
- **Emotion**: Nova Canvas illustrations and Lottie celebrations (the "soul")

---

## Pillar 1: Typography

Three-font system: **Nunito** (brand identity) + **SF Pro** (readability) + **New York** (emotion).

### Display Tier (Nunito Variable, ~100KB bundle)

| Token | Font | Size | Use |
|-------|------|------|-----|
| `.display` | Nunito ExtraLight | 48pt | Hero numbers, percentile callouts |
| `.timer` | Nunito Thin | 72pt | Feeding/sleep timers |
| `.title1` | Nunito SemiBold | 28pt | Screen titles |
| `.title2` | Nunito SemiBold | 22pt | Section headers |
| `.title3` | Nunito Medium | 20pt | Card headers |
| `.headline` | Nunito SemiBold | 17pt | Emphasized body |
| `.stat` | Nunito Bold mono | 20pt | Data values ("5.2 kg", "48th") |
| `.button` | Nunito SemiBold | 17pt | Button labels |
| `.badge` | Nunito Bold | 11pt | Chip/badge text |

### Body Tier (SF Pro -- system text styles)

| Token | Style | Size | Use |
|-------|-------|------|-----|
| `.body` | Regular | 17pt | Primary reading text |
| `.callout` | Regular | 16pt | Secondary text |
| `.subheadline` | Regular | 15pt | Tertiary text |
| `.footnote` | Regular | 13pt | Small annotations |
| `.caption` | Regular | 12pt | Captions |
| `.caption2` | Regular | 11pt | Smallest text |
| `.timestamp` | Regular mono | 12pt | Times, dates |

### Emotional Tier (New York -- system serif)

| Token | Style | Size | Use |
|-------|-------|------|-----|
| `.affirmation` | Regular italic | 20pt | Daily affirmations |
| `.milestone` | Medium | 22pt | Milestone celebration text |

### Rules

- Nunito for navigation/identification ("what screen am I on?")
- SF Pro for reading/data ("what does this say?")
- New York only for rare emotional moments (max once per screen, usually zero)
- All custom sizes use `.relativeTo:` for Dynamic Type scaling

---

## Pillar 2: Color & Opacity

### Color Palette (existing -- keep as-is)

| Token | Color | Use |
|-------|-------|-----|
| `MCColor.accent` | Mauve/rose | Primary brand, CTAs, active states |
| `MCColor.feeding` | Dusty blue | Feeding feature |
| `MCColor.selfCare` | Muted purple | Self-care feature |
| `MCColor.babyStatus` | Muted teal-green | Baby status, dashboard |
| `MCColor.baby` | Soft periwinkle | Baby avatar, sleep/nap |
| `MCColor.diaper` | Dusty teal | Diaper feature |
| `MCColor.error` | Red | Errors, validation |

### Opacity Tokens (new)

| Token | Value | Use |
|-------|-------|-----|
| `MCOpacity.ghost` | 0.04 | Canvas tinting, barely visible warm hue |
| `MCOpacity.whisper` | 0.08 | Inactive card fills, subtle dividers |
| `MCOpacity.soft` | 0.12 | Active overlays, selected state backgrounds |
| `MCOpacity.medium` | 0.20 | Emphasis overlays, prominent selections |
| `MCOpacity.strong` | 0.40 | Dashed lines, semi-visible elements |
| `MCOpacity.heavy` | 0.60 | Dimming scrims, modal backdrops |

### Canvas Tint (new)

`MCColor.canvas = Color(red: 0.04, green: 0.03, blue: 0.04)` -- barely perceptible warm near-black. Not visible as a color, felt as warmth. White text still exceeds 15:1 contrast ratio.

### Gradient Tokens (new)

| Token | Type | Use |
|-------|------|-----|
| `MCGradient.canvas` | Radial, canvas center to black edges | Screen-level warmth |
| `MCGradient.glow(color:)` | Radial, color at 0.15 to transparent | Nightlight halo on active elements |
| `MCGradient.accent` | Linear, accent shifted 15 degrees warmer | Button/CTA fills |

---

## Pillar 3: Elevation & Surfaces

### Four-Level Depth System

| Level | Name | Background | Material | Radius | Use |
|-------|------|-----------|----------|--------|-----|
| 0 | Canvas | MCColor.canvas + gradient | -- | -- | Screen background |
| 1 | Surface | white @ MCOpacity.whisper | .ultraThinMaterial | MCRadius.md | Data cards, history rows |
| 2 | Elevated | white @ MCOpacity.soft | .thinMaterial | MCRadius.lg | Action cards, active states |
| 3 | Overlay | white @ MCOpacity.medium | .regularMaterial | MCRadius.xl | Sheets, modals, alerts |

### Corner Radii Tokens

| Token | Value | Use |
|-------|-------|-----|
| `MCRadius.sm` | 8pt | Chips, badges, inline elements |
| `MCRadius.md` | 12pt | Data cards, list rows |
| `MCRadius.lg` | 16pt | Action cards, buttons |
| `MCRadius.xl` | 24pt | Sheets, modals |
| `MCRadius.full` | .infinity | Pills, capsules, avatars |

### Card Archetypes

**Data Card** (quiet): Level 1, no border, MCSpacing.md padding. History rows, stats, journal entries.

**Action Card** (interactive): Level 2, 1pt border at feature color + MCOpacity.whisper, MCSpacing.lg padding. Glow on active state. BabyActionCard, dashboard cards.

**Hero Card** (prominent): Level 2-3, no border (glow provides edge), MCSpacing.xl padding, MCRadius.xl. Always-on glow. Timer views, active feeding.

---

## Pillar 4: Motion -- Pow

### Animation Curves

| Token | Spec | Use |
|-------|------|-----|
| `MCAnimation.quick` | spring(0.25, damping: 0.8) | Button press, toggle, selection |
| `MCAnimation.standard` | spring(0.35, damping: 0.75) | Card transitions, sheets |
| `MCAnimation.gentle` | spring(0.5, damping: 0.8) | Glow effects, backgrounds |
| `MCAnimation.slow` | spring(0.7, damping: 0.85) | Celebrations, onboarding |

All check `accessibilityReduceMotion`. When on, changes are instant.

### Pow Transitions (view lifecycle)

| Token | Pow Effect | Use |
|-------|-----------|-----|
| `MCTransition.cardAppear` | .movingParts.pop | Cards entering screen |
| `MCTransition.cardDismiss` | .movingParts.vanish | Cards leaving screen |
| `MCTransition.listInsert` | .movingParts.move(.bottom) | New list items |
| `MCTransition.listRemove` | .movingParts.poof | Deleted list items |
| `MCTransition.sheetPresent` | .movingParts.blur | Sheet/modal appearance |
| `MCTransition.heroReveal` | .movingParts.iris | Charts, hero content |
| `MCTransition.sectionExpand` | .movingParts.blinds | Expanding sections |

### Pow Effects (state feedback)

| Token | Pow Effect | Haptic | Use |
|-------|-----------|--------|-----|
| `MCEffect.glow` | .glow | -- | **SIGNATURE** -- active/hero elements |
| `MCEffect.celebrate` | .spray | .success() | Milestones, completions |
| `MCEffect.shine` | .shine | .tap() | CTA buttons, confirmations |
| `MCEffect.error` | .shake | .error() | Validation failures |
| `MCEffect.success` | .rise | .success() | Saved/confirmed states |
| `MCEffect.attention` | .jump | .select() | New badges, notifications |

### Screen Entrance Choreography

| Step | Element | Curve | Delay |
|------|---------|-------|-------|
| 1 | Background gradient | MCAnimation.gentle | 0.0s |
| 2 | Illustration/hero | MCAnimation.standard | 0.1s |
| 3 | Title text | MCAnimation.standard | 0.2s |
| 4 | Body/cards | MCAnimation.standard | 0.3s |
| 5 | CTA button + .shine | MCAnimation.standard | 0.4s |

### Interaction Pairing Table

| Action | Haptic | Pow | Curve |
|--------|--------|-----|-------|
| Button tap | .tap() | .shine | .quick |
| Timer start | .toggle() | .glow | .standard |
| Timer end | .success() | .celebrate | .standard |
| Item logged | .tap() | .success | .quick |
| Item deleted | .tap() | .poof (transition) | .quick |
| Sheet present | -- | .blur (transition) | .standard |
| Error/invalid | .error() | .shake | .quick |
| Milestone hit | .success() | .celebrate | .slow |
| Daily complete | .success() | .celebrate | .slow |
| Toggle on/off | .toggle() | .shine | .quick |
| New data point | .select() | .pop (transition) | .standard |

---

## Pillar 5: Illustrations -- Nova Canvas

### Visual Language

- **Style**: Minimal line art, thin elegant strokes (2-3pt equivalent)
- **Color**: Monochromatic mauve-rose (MCColor.accent) + white at 40%
- **Shapes**: Soft, rounded -- matches Nunito's rounded terminals
- **Subjects**: Abstract and symbolic -- never literal, never faces
- **Background**: Transparent (composited over canvas gradient)
- **Mood**: Warm, gentle, premium, grown-up

### Nova Canvas Prompt Template

Suffix (every prompt):
> "minimal line art illustration, thin elegant strokes, monochromatic mauve-rose color palette, soft rounded shapes, modern premium aesthetic, gentle warm mood, transparent background, no text, no faces, abstract and symbolic, clean vector quality, centered composition with generous negative space"

Negative (every prompt):
> "cartoon, childish, colorful, busy, cluttered, realistic, photographic, faces, text, words, logos, harsh, neon"

Color palette: `[#DE94C7 primary, #FFFFFF40 secondary]`

Generate all illustrations in a single batch session for visual consistency.

### Inventory

**Empty States (6) -- 120pt, animated with Pow:**

| Name | Subject |
|------|---------|
| empty-feeding | Elegant bottle with gentle milk drop |
| empty-sleep | Crescent moon with small stars |
| empty-growth | Small plant sprout with upward curve |
| empty-diapers | Soft folded cloth/blanket |
| empty-journal | Open book with flowing ribbon bookmark |
| empty-selfcare | Heart with gentle radiating warmth lines |

**Onboarding Heroes (3) -- 240pt, full-screen:**

| Name | Subject |
|------|---------|
| onboarding-welcome | Hands cradling a soft warm glow |
| onboarding-features | Abstract tracking symbols orbiting a center |
| onboarding-privacy | Shield with gentle lock, reassuring warmth |

**Status Indicators (2) -- 60pt, inline with timers:**

| Name | Subject |
|------|---------|
| status-sleeping | Crescent moon with subtle zzz motif |
| status-feeding | Gentle drop/flow motif |

### Animation via Pow (not Lottie)

- Empty states: Fade in with upward drift + Pow .glow (continuous, subtle)
- Status indicators: Pow .pulse (gentle breathing scale) + Pow .glow in feature color
- Onboarding heroes: Pow .heroReveal (.iris) + subtle parallax drift

### Asset Format

- PNG with transparency, @2x and @3x in Assets.xcassets
- Generated at 1024x1024 from Nova Canvas, downscaled
- Named: `mc-illustration-{category}-{name}`

---

## Pillar 6: Celebrations -- Lottie

### Lottie's Role

Focused on abstract particle effects only. Four files, each under 50KB.

### File Inventory

| File | Visual | Duration | Trigger |
|------|--------|----------|---------|
| celebration-confetti.json | Warm confetti particles falling | 2.5s, once | Major milestones (percentile, streaks) |
| celebration-sparkle.json | Radial twinkle expanding outward | 1.5s, once | Daily completion, first-time events |
| celebration-warmglow.json | Expanding warm light ring/ripple | 2.0s, once | End of feeding/sleep session |
| loading-breathe.json | Abstract dots expanding/contracting | 2.0s, loop | Data loading states |

### Celebration Triggers

| Milestone | Trigger | Lottie | Pow | Haptic |
|-----------|---------|--------|-----|--------|
| Daily completion | All self-care items checked | sparkle | .celebrate | .success() |
| Streak (3/7/14/30) | Consecutive tracking days | confetti | .celebrate | .success() |
| Growth milestone | New measurement logged | warmglow | .glow | .success() |
| First-time event | First feeding/sleep/diaper | sparkle | .shine | .success() |
| Session complete | End feeding or sleep timer | warmglow | .success | .success() |

### Rules

- No streak-shaming. Ever.
- Celebrations are brief (1.5-2.5s) and auto-dismiss
- Maximum one celebration per user action
- Track shown milestones in UserDefaults to avoid repeats
- First-time events fire once ever per event type

### CelebrationOverlay Component

Orchestrates the full multi-sensory moment:

1. MCHaptic fires immediately
2. Pow effect fires on trigger element (0ms)
3. Lottie animation appears as overlay (50ms delay)
4. New York `.milestone` text fades in ("Look how far you've come")
5. Auto-dismiss after Lottie completes
6. Mark milestone as shown in UserDefaults

### MCLottieView Wrapper

- `reduceMotion` ON: Static fallback (checkmark icon + text)
- `reduceMotion` OFF: Plays Lottie animation
- VoiceOver label describes semantic meaning
- Animation never conveys information alone -- always paired with text

### Sourcing

1. Search LottieFiles.com for base animations matching descriptions
2. Customize colors to MCColor.accent palette
3. Adjust timing to match MCAnimation curves
4. Verify file size under 50KB each

---

## What Changes vs What Stays

### Changes

| Area | Before | After |
|------|--------|-------|
| Background | `Color.black` | Warm-tinted `MCGradient.canvas` |
| Typography | 4 system tokens | 18 tokens across 3 fonts |
| Cards | Uniform `.ultraThinMaterial` | 3 archetypes (data/action/hero) |
| Active states | Color overlay | Warm Pow `.glow` + color overlay |
| Whitespace | 16pt screen padding | 24pt screen padding |
| Corner radii | Magic numbers (8/12/16) | `MCRadius` tokens |
| Opacity | Scattered (0.06-0.5) | `MCOpacity` tokens |
| Animation | Scattered springs | `MCAnimation` 4 curves |
| Transitions | None | Pow-powered `MCTransition` |
| Empty states | SF Symbol + text | Nova Canvas illustration + Pow |
| Celebrations | None | Lottie overlay + Pow + haptic |
| Loading | None / SkeletonUI once | Lottie breathing animation |

### Stays the Same

- Color palette (warm, feature-distinct, non-gendered)
- Haptic strategy (comprehensive MCHaptic)
- Touch targets (56pt buttons, 44pt minimum)
- Accessibility (reduceMotion, Dynamic Type, VoiceOver)
- Dark-mode-first philosophy
- Feature color assignments
- 8pt spacing grid

---

## HIG Compliance

| Decision | HIG Status | Rationale |
|----------|-----------|-----------|
| Nunito for titles | Compliant | HIG allows custom fonts with Dynamic Type via `.relativeTo:` |
| Warm canvas tint | Compliant | HIG recommends "very dark gray rather than black" for dark mode |
| Pow glow effects | Compliant | Static shadows, not animation. Respects reduceMotion. |
| Gradient backgrounds | Compliant | Text contrast maintained across gradient range (>15:1) |
| Elevation via lightness | Compliant | Apple's own recommendation for dark mode depth |
| Lottie celebrations | Compliant | All have reduceMotion fallbacks and VoiceOver labels |
| Three-font strategy | Compliant | HIG: "supplement system fonts" -- SF Pro for body maintains platform consistency |
