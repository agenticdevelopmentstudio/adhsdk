---
id: 1a044d34-d585-46b4-b703-dea3fb9b9642
title: "StatusDot"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A small glowing status dot — one tone colors both fill and glow; sized in px, optionally labeled for screen readers."
platforms:
  - typescript
  - web
tags:
  - component
  - status
  - indicator
  - ui
depends-on: []
related:
  - b7a4a259-620f-42a3-8bc2-9e5c07c1819d
references:
  - https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix
approved-by: ""
approved-date: ""
---

# StatusDot

## Overview

The shared `StatusDot` in `@adh-sdk/ui` — the family's "live light": a small
round dot whose **fill and soft glow both derive from one tone class**. The tone
class sets `currentColor` (`text-apt-green`, `text-apt-red`, …); the fill is
`background: currentColor` and the glow is a `box-shadow` whose color is a
`color-mix` of that same `currentColor`, so a single class drives the entire
treatment and no per-tone shadow is hand-written.

It is sized in **px** (`size`, default `10`) rather than a scale step, because it
must optically align with mono text at many sizes — a status word beside it, a
row label, a hero figure. The glow radius scales with the dot
(`max(6, round(size * 0.55))` px) so a large dot still reads as a soft light
rather than a flat disc.

Accessibility is driven by `label`: pass the status word and the dot becomes an
accessible image (`role="img"` + `aria-label`); omit it — the common case, where
visible text already carries the meaning — and the dot is `aria-hidden`
decoration. A single export ships from
`@adh-sdk/ui/components/status-dot`: the `StatusDot` component. It is a pure
presentational span with no internal state and no `"use client"` directive.

## Behavioral Requirements

- **derives-fill-from-currentcolor**: The component MUST fill the dot with `background: currentColor` so the tone class alone sets the fill color.
- **derives-glow-from-currentcolor**: The component MUST render a soft `box-shadow` glow whose color is a `color-mix` of the same `currentColor`, so one tone class drives both fill and glow.
- **tone-sets-currentcolor**: The component MUST map each `tone` to an `apt-*` text-color class (`neutral`→`apt-text-muted`, `muted`→`apt-text-dim`, `accent`→`apt-gold`, `blue`→`apt-blue`, `orange`→`apt-orange`, `success`→`apt-green`, `error`→`apt-red`).
- **defaults-to-neutral-tone**: With no `tone`, the component MUST use the `neutral` tone (`apt-text-muted`).
- **sizes-in-px**: The component MUST render the dot at `size` px square (default `10`) via inline `width`/`height`.
- **scales-glow-with-size**: The component MUST set the glow radius to `max(6, round(size * 0.55))` px so the glow grows with the dot but never falls below 6 px.
- **labeled-is-accessible-image**: Given a `label`, the component MUST expose `role="img"` and `aria-label` set to that label.
- **unlabeled-is-decorative**: With no `label`, the component MUST render `aria-hidden="true"` and no `role`, so it is skipped by assistive technology.
- **passes-label-through-verbatim**: The component MUST render a provided `label` verbatim as `aria-label`, without concatenating, translating, or otherwise transforming it — the consumer MUST supply an already-localized string.
- **merges-classname**: The component MUST merge any `className` after the tone class via `cn()`, so a consumer MAY add layout classes without losing the tone.
- **memoizes-render**: Since every prop is a primitive, the component SHOULD be wrapped in a memoization boundary (`React.memo`) so an unchanged dot skips re-render on a frequently-updating parent.

## Appearance

```
tone=success   ●  (apt-green fill + green glow halo)
tone=error     ●  (apt-red fill + red glow halo)
tone=accent    ●  (apt-gold fill + gold glow halo)

size=8   ·      size=12   ●      size=18   ⬤   (glow radius grows with size)
```

- Base: `inline-block shrink-0 rounded-full` — a shrink-proof inline circle that
  sits on the text baseline beside a label.
- Fill: `background: currentColor` (inline style), where `currentColor` comes
  from the tone's `text-apt-*` class.
- Glow: `boxShadow: 0 0 {glow}px color-mix(in srgb, currentColor 40%, transparent)`
  — a 40%-opacity halo of the same color, radius `max(6, round(size * 0.55))`.
- Size: inline `width` / `height` in px (default 10), so it aligns optically
  with adjacent mono text at any size.
- Fully token-driven (`apt-*` tones); no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Default (`neutral`) | `apt-text-muted` fill + muted glow |
| Tinted (`success`/`error`/`accent`/`blue`/`orange`/`muted`) | Fill and glow both recolor to the tone's `apt-*` color |
| Small (`size` < 10) | Dot shrinks; glow clamps to a 6 px floor so it stays visible |
| Large (`size` big) | Dot grows; glow radius scales to `round(size * 0.55)` px |
| Labeled | Announced as an image named `label` (`role="img"`) |
| Decorative (no `label`) | `aria-hidden`; ignored by AT |

## Accessibility

- **Labeled = image.** With a `label`, the dot carries `role="img"` and
  `aria-label={label}`, so a standalone dot (e.g. the only status affordance in a
  cell) announces its status word to AT.
- **Unlabeled = decorative.** Without a `label`, the dot is `aria-hidden="true"`
  and has no role — the intended pattern when visible text ("healthy", "down")
  already names the status and a labeled dot would be a redundant announcement.
- Not focusable and not interactive; it is a pure indicator.
- Color is never the *only* signal in the family's compositions: the dot pairs
  with a visible status word (see the demo and StatCard), so it does not rely on
  hue alone to convey meaning.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | unlabeled-is-decorative, derives-fill-from-currentcolor | render `<StatusDot tone="success" />` | span has `aria-hidden="true"`; inline `background` is `currentcolor` |
| T2 | labeled-is-accessible-image, tone-sets-currentcolor | `<StatusDot tone="error" size={20} label="down" />` | element found by `role="img"` name `down`; className contains `text-apt-red` |
| T3 | scales-glow-with-size, derives-glow-from-currentcolor | `size={20}` | inline `boxShadow` contains `11px` (round(20 × 0.55)) and a `color-mix` of `currentColor` |
| T4 | labeled-is-accessible-image | `label="down"` | no element matches `[aria-hidden="true"]` |
| T5 | scales-glow-with-size | `size={8}` | glow radius clamps to `6px` (max(6, round(8 × 0.55)=4)) |
| T6 | defaults-to-neutral-tone | render `<StatusDot />` (no tone) | className contains `text-apt-text-muted` |
| T7 | sizes-in-px | `size={18}` | inline `width` and `height` are `18px` |
| T8 | merges-classname | `className="ml-1"` | className contains both `ml-1` and the tone class |
| T9 | tone-sets-currentcolor | render `<StatusDot tone="muted" />` | className contains `text-apt-text-dim` |
| T10 | tone-sets-currentcolor | render `<StatusDot tone="accent" />` | className contains `text-apt-gold` |
| T11 | tone-sets-currentcolor | render `<StatusDot tone="blue" />` | className contains `text-apt-blue` |
| T12 | tone-sets-currentcolor | render `<StatusDot tone="orange" />` | className contains `text-apt-orange` |
| T13 | unlabeled-is-decorative, passes-label-through-verbatim | `<StatusDot tone="success" label="" />` | span has `aria-hidden="true"` and no `role` attribute (empty string is falsy) |
| T14 | scales-glow-with-size | `size={10}` | inline `boxShadow` contains `6px` (round(10 × 0.55) = 6, exactly at the floor) |

## Edge Cases

- **Tiny sizes.** For `size` < 10, `round(size * 0.55)` is below 6, so the glow
  clamps to the 6 px floor — a small dot still shows a visible halo rather than
  vanishing to a flat point.
- **Fractional size.** `size` is applied verbatim to `width`/`height`; only the
  glow radius is rounded, so a fractional `size` renders a fractional dot with an
  integer glow.
- **Empty-string label.** `label=""` is falsy, so the dot falls back to the
  decorative (`aria-hidden`) branch rather than announcing an empty image name.
- **No visible text.** A dot used alone with no adjacent label SHOULD pass
  `label` so its status is not lost to AT (color alone is inaccessible).
- **Glow on light surfaces.** The glow is a 40%-opacity `color-mix` with
  `transparent`, so it blends over any surface token without a hard edge.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `tone` | `"neutral" \| "muted" \| "accent" \| "blue" \| "orange" \| "success" \| "error"` | `"neutral"` | Selects the `apt-*` color that drives both fill and glow. |
| `size` | `number` | `10` | Diameter in px; the glow radius scales with it (`max(6, round(size*0.55))`). |
| `label` | `string` | — | Accessible name. Present → `role="img"` + `aria-label`; omitted → `aria-hidden` decoration. |
| `className` | `string` | — | Extra classes merged after the tone class via `cn()` (e.g. layout/margins). |

## Deep Linking

Not applicable: StatusDot is a pure presentational component with no navigation semantics.

## Localization

StatusDot renders no strings of its own — the only text-bearing surface is the
consumer-supplied `label`, exposed verbatim as `aria-label`
(**passes-label-through-verbatim**). The consumer MUST supply `label` already
localized; the component MUST NOT concatenate, translate, or otherwise
transform it before setting `aria-label`.

## Accessibility Options

Not applicable: StatusDot is a bare visual indicator. Motion, contrast, and color-differentiation preferences are managed by the tone system and inherited from the parent container's accessibility context, not by the component itself.

## Feature Flags

Not applicable: StatusDot is a primitive library component published as a reusable ingredient; feature flagging is the responsibility of consuming applications.

## Analytics

Not applicable: StatusDot is a presentational indicator with no internal state or event generation. The meaning of a status change and any telemetry around it belong to the consumer computing the tone, not the component.

## Privacy

Not applicable: StatusDot collects, stores, and transmits no data.

## Logging

No logging. `StatusDot` is a presentational indicator; the meaning of a status
and any telemetry around a health change belong to the consumer computing the
tone, not the dot.

## Platform Notes

- **SwiftUI**: Start from `Circle()` rather than a capsule, sized via `.frame(width: size, height: size)`. Apply `.shadow(color:radius:)` with a tone-mapped `Color` at 40% opacity and radius `max(6, round(size * 0.55))`. Accessibility: with `label`, apply `.accessibilityLabel(label)` and `.accessibilityAddTraits(.isImage)`; without, apply `.accessibilityHidden(true)` (`.hidden` is a view-visibility modifier, not an accessibility API).
- **Compose**: `Modifier.shadow()` is elevation-based and cannot take an arbitrary tone-colored glow radius, so draw the halo by hand with `Modifier.drawBehind { }` (or a blur `RenderEffect`), sized `max(6, round(size * 0.55))` dp; fill with `Modifier.size(size.dp).background(toneColor, CircleShape)`. Semantics: with `label`, `Modifier.semantics { contentDescription = label; role = Role.Image }`; without, `Modifier.clearAndSetSemantics {}` ("mark as decorative" is not itself an API).
- **Web/TypeScript**: File `packages/web/packages/ui/src/components/status-dot.tsx`. React functional component wrapped in `React.memo` (see **memoizes-render**) — all props are primitives, so an unchanged dot skips re-render on a ticking parent. No `"use client"` directive — it is a stateless span with inline style and renders in server components. Uses CSS `color-mix(in srgb, …)` for the glow; supported by all evergreen browsers ([MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix)). The `cn()` utility for className merging comes from `../lib/utils`.
- **AppKit / UIKit**: A layer-backed `NSView` (AppKit) or `UIView` (UIKit) with a `CALayer` glow. Fill: AppKit sets `layer.backgroundColor` from an `NSColor` derived from the tone on a layer-backed view; UIKit sets it from `UIColor(named: "apt-<tone>")`. Glow: both set `layer.shadowColor`, `layer.shadowRadius = max(6, round(size * 0.55))`, and `layer.shadowOpacity = 0.4` for the tone-colored halo. Accessibility: with `label`, AppKit sets `accessibilityRole = .image` + `accessibilityLabel`; UIKit sets `accessibilityTraits = .image` + `accessibilityLabel`. Without `label`, both set `isAccessibilityElement = false`.
- **WinUI 3**: A `Border` with `CornerRadius="{size/2}"` (half the diameter, so it reads as a circle rather than a rounded square) and `Background` bound to a tone-based brush. `ThemeShadow` cannot take a color or blur radius, so use a Composition `DropShadow` via `ElementCompositionPreview`, with `BlurRadius = max(6, round(size * 0.55))` and `Color` at 40% opacity of the tone brush. Accessibility: with `label`, set `AutomationProperties.Name`; without, set `AutomationProperties.AccessibilityView="Raw"` so it is excluded from the accessibility tree rather than merely left unnamed. Pair with a `ContentPresenter` or inline text for the status word; color alone is insufficient.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/status-dot.tsx` | unverified |

## Design Decisions

**Decision**: Both the fill (`background: currentColor`) and the glow
(`color-mix` of `currentColor`) derive from the tone's text color, so a single
`text-apt-*` class recolors the entire dot.
**Rationale**: This avoids a parallel set of per-tone shadow classes that
could drift out of sync with the fill.
**Approved**: pending

**Decision**: `size` is a raw px number rather than a `sm/md/lg` token.
**Rationale**: A status dot must optically match mono text at whatever size it
appears next to (row label, hero figure, inline word), so the caller tunes it
to the neighbouring text.
**Approved**: pending

**Decision**: The glow radius floors at 6 px (`max(6, round(size*0.55))`).
**Rationale**: This keeps small dots from losing their halo entirely,
preserving the "soft light" read even at `size={8}`.
**Approved**: pending

**Decision**: The dot is decorative (`aria-hidden`) by default and becomes
`role="img"` only when given a `label`.
**Rationale**: This matches the common case where visible text already
carries the status and a second announcement would be noise.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the source's conditional `role="img"` / `aria-label` /
`aria-hidden="true"` rendering (`semantic-markup`), and on the fact that the
component never embeds a literal user-facing string — `label` is always a
value the consumer passes in (`no-hardcoded-strings`). `separation-of-concerns`
passes: `StatusDot` is a memoized, pure presentational component, and its
tone-to-class mapping is delegated to the shared `lib/tone` table rather than
computed inline. `unit-test-coverage` is partial: `stat.test.tsx` covers the
decorative/accessible-image split and the size-driven glow, but not the
`color-mix` glow color, the small-size threshold, or the `neutral` tone
override.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 Change History wording ("Initial recipe" not "Initial ingredient"); added missing separation-of-concerns/unit-test-coverage Compliance rows. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: fix the small-size threshold to `size < 10` in States and Edge Cases, cite MDN for `color-mix` support, rewrite Compliance as a real catalog-check table, reformat Design Decisions to the Decision/Rationale/Approved form, reorder Platform Notes and correct the SwiftUI/Compose/AppKit-UIKit/WinUI 3 APIs, add `passes-label-through-verbatim` and `memoizes-render` requirements with new test vectors and a rewritten Localization section, add missing tone/empty-label/boundary conformance vectors, fix the 1.0.0 Change History summary, and trim the frontmatter summary. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise: fix domain (cookbook), add missing "not applicable" sections, complete Platform Notes for all platforms, set status to review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the currentColor-driven glowing StatusDot. |
