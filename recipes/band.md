---
id: e0b59d60-0a56-4bf4-85cb-fb0e58170f8e
title: Band
domain: adhsdk://recipes/band
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Horizontal section of a flow page layout with tone variation and optional
  diagonal seam.
platforms:
- typescript
- web
tags:
- layout
- section
- landing
- flow
depends-on:
- adhsdk://recipes/wrap
related:
- adhsdk://recipes/flow
- adhsdk://recipes/flow-hero
references: []
approved-by: ''
approved-date: ''
---

# Band

## Overview

Band is a semantic section container that divides a flow page into horizontal regions. Each band is sized to its content and can adopt one of three tones (dark, soft, or paper) to create visual rhythm. An optional diagonal seam at the top creates a visual overlap with the band above. The seam uses CSS clip-path and negative margin to reveal the overlapped band's background rather than the page background.

## Behavioral Requirements

- **render-section**: Band MUST render as an HTML `<section>` element.
- **accept-id**: Band MUST accept an optional `id` prop that is forwarded to the rendered section; when omitted, the section renders without an `id` attribute.
- **support-three-tones**: Band MUST support three tone values: `'dark'`, `'soft'`, and `'paper'`.
- **default-dark-tone**: Band MUST default to tone `'dark'` if the `tone` prop is not specified.
- **seam-prop**: Band MUST accept an optional `seam` prop, defaulting to `true`, that controls whether the diagonal cut is rendered along the top edge.
- **apply-seam-when-true**: When `seam` is `true`, Band MUST render the diagonal cut along the top edge using CSS `clip-path` and a negative top margin, both derived from the `--lp-seam` CSS variable (default `4.5vw`): `clip-path: polygon(0 var(--lp-seam), 100% 0, 100% 100%, 0 100%)` and `margin-top: calc(var(--lp-seam) * -1)`.
- **omit-seam-when-false**: When `seam` is `false`, Band MUST NOT apply the diagonal cut to the top edge; the `lp-band--seam` class is withheld.
- **paper-cuts-foot**: When `tone` is `'paper'`, Band MUST render a diagonal cut along the bottom edge independent of the `seam` prop, using `clip-path: polygon(0 0, 100% 0, 100% 100%, 0 calc(100% - var(--lp-seam)))` and `margin-bottom: calc(var(--lp-seam) * -1)`. When `seam` is also `true`, the top edge is cut in addition, not instead.
- **stacking-order**: Band MUST establish a stacking context (`position: relative`, `z-index: 1`) so a later sibling's top seam paints over it through document order alone. The `paper` tone MUST raise this to `z-index: 2` so its own bottom cut paints above the band that follows it in the DOM.
- **wrap-children**: Band MUST wrap its children with the `Wrap` component.
- **accept-classname**: Band MUST accept an optional `className` prop.
- **apply-tone-class**: Band MUST apply a CSS class matching the pattern `lp-band--{tone}` corresponding to the tone prop.
- **band-base-class**: Band MUST apply the CSS class `lp-band` to the section.
- **seam-class-when-true**: When `seam` is `true`, Band MUST apply the CSS class `lp-band--seam` to the section.

## Appearance

- **Background**: Tone-dependent. `dark` uses `background: var(--lp-ground, #101010)` with `color: var(--lp-ink, #ededed)`; `soft` uses `background: var(--lp-tone-soft, #171717)` with the same `--lp-ink`; `paper` uses `background: var(--lp-tone-paper, #f4f4f4)` with `color: var(--lp-paper-ink, #171717)` and overrides `--lp-ink-dim` to `var(--lp-paper-dim, #5c5c5c)` for children that read it directly.
- **Spacing**: Band height equals its content height. Vertical rhythm (`padding-top`/`padding-bottom`) comes from `--lp-band-pad` (default `clamp(4.5rem, 9vw, 8rem)`) on `.lp-band` itself, not from `Wrap`; the last band in a flow adds `--lp-dock-clear` to its bottom padding. `Wrap` controls horizontal centering and max measure only — see **wrap-children**.
- **Seam styling**: Diagonal cut uses CSS `clip-path` with angle and depth set by `--lp-seam` (default `4.5vw`); see **apply-seam-when-true** and **paper-cuts-foot** for the exact formulas. The negative margin pulls the cutting band by the same amount so the wedge reveals the neighboring band rather than the page background.

## States

Not applicable: Band is a layout container without interactive states. The seam is a static visual property, not a state.

## Accessibility

- **Semantic role**: Band renders as a `<section>` element, providing semantic structure for assistive technology.
- **Heading hierarchy**: Content within Band SHOULD follow proper heading hierarchy starting with `<h2>` or lower (assuming a page-level `<h1>` exists).
- **No interactive content required**: Band itself has no interactive controls and requires no ARIA attributes beyond what its children provide.
- **Not an exposed landmark**: Band accepts no `aria-label`/`aria-labelledby` prop, so its `<section>` has no accessible name and is not exposed as a landmark region to assistive technology; it is a visual/layout boundary only.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| band-001 | render-section | Render `<Band />` | Output contains a `<section>` element |
| band-002 | default-dark-tone | Render `<Band />` without tone prop | Rendered section includes class `lp-band--dark` |
| band-003 | accept-id | Render `<Band id="section-1" />` | Rendered section has `id="section-1"` |
| band-004 | support-three-tones, apply-tone-class | Render `<Band tone="soft" />` | Rendered section includes class `lp-band--soft` |
| band-005 | support-three-tones, apply-tone-class | Render `<Band tone="paper" />` | Rendered section includes class `lp-band--paper` |
| band-006 | seam-prop, seam-class-when-true | Render `<Band />` without seam prop | Rendered section includes class `lp-band--seam` |
| band-007 | omit-seam-when-false | Render `<Band seam={false} />` | Rendered section does not include class `lp-band--seam` |
| band-008 | band-base-class | Render `<Band />` | Rendered section includes class `lp-band` |
| band-009 | accept-classname | Render `<Band className="custom-class" />` | Rendered section class list includes `custom-class` |
| band-010 | wrap-children | Render `<Band><p>Content</p></Band>` | Section's direct child is a `<div>` with class `lp-wrap`, containing `<p>Content</p>` |
| band-011 | accept-id | Render `<Band />` without an id prop | Rendered section has no `id` attribute |
| band-012 | band-base-class, apply-tone-class, seam-class-when-true, accept-classname | Render `<Band tone="soft" seam={true} className="custom-class" />` | Rendered section class list includes `lp-band`, `lp-band--soft`, `lp-band--seam`, and `custom-class` |
| band-013 | accept-classname | Render `<Band className="" />` | Rendered section class list contains no empty-string entries or doubled whitespace |
| band-014 | paper-cuts-foot | Render `<Band tone="paper" seam={false} />` | Rendered section includes class `lp-band--paper` and its computed `clip-path` cuts the bottom-left vertex by `--lp-seam`, regardless of `seam` being `false` |
| band-015 | stacking-order | Render `<Band />` | Rendered section has computed `position: relative` and `z-index: 1` |
| band-016 | stacking-order | Render `<Band tone="paper" />` | Rendered section has computed `z-index: 2` |

## Edge Cases

- **Multiple classes**: When `seam`, `tone`, and `className` are all provided, all resulting classes (`lp-band`, `lp-band--{tone}`, `lp-band--seam`, and custom class) MUST be present in the section's class list.
- **Empty children**: Band MUST accept empty or no children and render without error. The `Wrap` component determines rendering behavior for empty content.
- **Falsy className**: If `className` is an empty string or falsy, it MUST NOT add extra spaces or broken classes to the section; filtering MUST remove it from the class list.
- **Missing id**: If `id` is not provided, Band MUST render the section without an `id` attribute rather than an empty or literal `"undefined"` value.
- **Tone with seam combinations**: All three tones (dark, soft, paper) MUST work with both `seam: true` and `seam: false` without conflict. On `tone="paper"`, the `seam` prop controls the top edge only; the bottom cut always applies — see **paper-cuts-foot**.
- **First band on a page**: `seam` defaults to `true`, so a band with no preceding sibling still pulls itself upward by `--lp-seam` with nothing behind it to reveal. Band does not detect this case. The caller SHOULD pass `seam={false}` for the first band under a hero that already ends on an angle, and for any band whose neighbor above shares the same tone (an invisible seam between identical grounds still costs the overlap).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `string` | undefined | Optional HTML id attribute for the section |
| `tone` | `'dark' \| 'soft' \| 'paper'` | `'dark'` | Background tone and color scheme |
| `seam` | `boolean` | `true` | Whether to render the diagonal cut at the top edge |
| `className` | `string` | undefined | Additional CSS classes to apply to the section |
| `children` | `ReactNode` | (required) | Content to render inside the band, wrapped with Wrap |

## Deep Linking

Not applicable: Band is a layout container and does not support deep linking.

## Localization

Not applicable: Band has no user-facing strings.

## Accessibility Options

- **Reduce Motion**: Seam rendering does not involve animation; no motion reduction required.
- **Increase Contrast**: Tone backgrounds MUST maintain sufficient contrast ratios per WCAG 2.1 AA with text and controls rendered within. This is verified via the tone's CSS color values (see **Appearance**), not Band itself.
- **Differentiate Without Color**: Seam is a visual boundary; if seams are critical to page structure, content SHOULD include text or heading hierarchy so meaning is not conveyed by seam presence alone.

## Feature Flags

Not applicable: Band has no feature-gated behavior.

## Analytics

Not applicable: Band is a layout container with no user interaction.

## Privacy

Not applicable: Band does not collect, store, or transmit data.

## Logging

Not applicable: Band has no operational events to log.

## Platform Notes

- **TypeScript/Web**: Implemented in `packages/web/packages/landing/src/flow/Band.tsx`. Uses CSS classes `lp-band`, `lp-band--{tone}`, and `lp-band--seam` for styling. The seam uses CSS `clip-path` and a negative top margin derived from `--lp-seam` (default `4.5vw`); `paper` additionally cuts its bottom edge unconditionally. Children are wrapped with the `Wrap` component, which handles horizontal centering and max measure, not padding rhythm.
- **SwiftUI**: Port as a `VStack` (or `ZStack` for the paper case) clipped with a custom `Shape` via `.clipShape`, since SwiftUI has no clip-path equivalent. Map tones to distinct background colors using `.background(_:)`. Pull a seamed band upward with negative top spacing on the parent stack rather than `.offset()`, which does not shrink measured layout height and would leave a gap below. Use `@ViewBuilder` for children to match Band's flexible content.
- **Compose**: Implement as a `Box` or `Column` with tone-mapped background, clipped to a custom `GenericShape` via `Modifier.clip()` for the diagonal. Because `Modifier.offset()` does not change layout, pull the band upward with a custom `Modifier.layout { ... }` (or an equivalent negative-spacing arrangement) so the measured height actually shrinks and the following sibling closes the gap. Wrap children in a horizontal padding wrapper equivalent to `Wrap`.
- **AppKit / UIKit**: On iOS, use a `UIView` subclass with a `CAShapeLayer` set as `layer.mask` — a `CAShapeLayer` combined with `clipsToBounds` alone does not clip to an arbitrary diagonal path. On macOS, use an `NSView` with the equivalent `CALayer` mask. Map tone to `backgroundColor` or gradient. Implement the seam as a masked path with a negative frame offset equal to the seam depth. Wrap children in a container view that applies horizontal padding.
- **WinUI 3**: Implement as a `Grid` or `StackPanel` (Vertical orientation); do not use `Viewbox` for the children wrapper, since it scales its content instead of padding it — use a `Border` or inner `Grid` with `Padding` for horizontal spacing equivalent to `Wrap`. Set `Background` to a `SolidColorBrush` or `LinearGradientBrush` mapped to the tone. `UIElement.Clip`/`RectangleGeometry` cannot express an angled edge, so render the diagonal with a `PathGeometry` (via `Clip` or a Composition `CompositionPathGeometry`) and apply a negative `Margin` equal to the seam depth to pull the band upward.

## Design Decisions

- **Decision**: Band is sized to its content, not to a fixed height or viewport unit.
  **Rationale**: This distinguishes it from a full-screen container and allows bands to flex based on content, unlike the deck's `Screen`, which reasons in viewport units.
  **Approved**: pending

- **Decision**: The seam uses `clip-path` and a negative margin together, both derived from the same `--lp-seam` CSS variable (default `4.5vw`); the seam is a static visual property toggled only by the boolean `seam` prop and is never animated.
  **Rationale**: Deriving both the cut and the offset from one variable prevents them from drifting apart; keeping the seam static avoids Reduce Motion concerns entirely.
  **Approved**: pending

- **Decision**: Tones are named by their visual role (`dark`, `soft`, `paper`), not by semantic meaning (e.g., not "primary", "secondary").
  **Rationale**: Naming by role keeps the palette flexible as design systems evolve, rather than binding a tone name to a meaning that may not fit a future theme.
  **Approved**: pending

- **Decision**: `tone="paper"` always cuts its own bottom edge, regardless of the `seam` prop; `seam` controls only the top edge.
  **Rationale**: Paper is an inserted card rather than a step down in the tone rhythm, so it always wants a matching angle at its base. This is enforced unconditionally by the `lp-band--paper` CSS rule (see **paper-cuts-foot**) rather than by a separate prop, since no consumer needs to opt out of it.
  **Approved**: pending

- **Decision**: Band always wraps children with `Wrap`, non-configurably.
  **Rationale**: Guarantees consistent horizontal padding and alignment across every band; a developer cannot override `Wrap`'s behavior per instance.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`semantic-markup` passes because Band always renders a real `<section>` element. `contrast-ratio` is partial because Band pairs a background and ink color per tone (the source shows the pairing), but does not compute or verify the actual rendered contrast, which depends on whatever values a host supplies for `--lp-ground`, `--lp-tone-soft`, `--lp-tone-paper`, `--lp-ink`, and `--lp-paper-ink`. Best-practices statuses rest on `Band` being pure presentation composing `Wrap` with no embedded logic (separation-of-concerns: passed), and on `flow.test.tsx` directly rendering `Band` and asserting its tone/seam class output (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and merged the seam requirements; added paper-cuts-foot and stacking-order requirements; specified seam and tone CSS token defaults and formulas; fixed Appearance's Wrap padding-axis contradiction; added edge cases for the first band, paper's foot cut, falsy className, and missing id; corrected the Wrap test vector and added vectors for the new requirements and edge cases; corrected the WinUI/UIKit/SwiftUI/Compose platform notes; reformatted Design Decisions to Decision/Rationale/Approved; rebuilt Compliance as a linked passed/partial table; added tags, depends-on, and related; fixed RFC 2119 casing, added a landmark note to Accessibility |
| 1.0.0 | 2026-09-22 | Generated | Initial creation from source |
