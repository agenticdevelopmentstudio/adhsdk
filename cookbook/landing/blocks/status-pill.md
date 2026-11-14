---
id: ba2377b1-f831-4ef8-bf2c-d8393e5eb2c1
title: "Status Pill"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A small pill-shaped badge displaying a status label, optionally accented to highlight a free tier or special status."
platforms:
  - typescript
  - web
tags:
  - status
  - badge
  - indicator
depends-on: []
related:
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
references: []
approved-by: ""
approved-date: ""
---

# Status Pill

## Overview

StatusPill is a small, presentational pill-shaped label. It accepts arbitrary children as its status text and an optional `free` boolean prop that switches on an accented style — a distinct border color over a dimmed background — to make one status stand out from the rest. Per the source comment, it backs two call sites that deliberately share this same pill shape: a `Hero`'s shipping status and a `Chips` list of model providers, where `free` marks the one item that should read as accented.

## Behavioral Requirements

- **accept-children**: Component MUST accept and render any `ReactNode` as children content.
- **base-style**: Component MUST render the root element in the pill's base style (see **Appearance**). The React/Web implementation applies this via the `lp-status` CSS class.
- **accent-style**: When the `free` prop is explicitly `true`, the component MUST render the accented style — a distinct border color over a dimmed background (see **Appearance**). The React/Web implementation applies this by adding the `lp-status--free` CSS class alongside `lp-status`.
- **accent-opt-in**: When the `free` prop is absent or falsy, the component MUST NOT render the accented style; accenting is opt-in, never the default.
- **status-conveyed-by-text**: The status MUST be conveyed by the children text content; the accented border and background are supplementary and MUST NOT be the only way the status is communicated.

## Appearance

- **Corner radius**: `border-radius: 99px` (fully rounded pill).
- **Padding**: `0.32rem` vertical × `0.6rem` horizontal.
- **Font**: weight 600, size `0.62rem`, line-height 1, `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`; `letter-spacing: 0.16em`; `text-transform: uppercase` (locale-sensitive — see **Localization**).
- **Background**: transparent by default; `var(--lp-accent-dim, rgba(216, 216, 216, 0.14))` when `free={true}`.
- **Border**: `1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))` by default; border color becomes `var(--lp-status-free-border, rgba(216, 216, 216, 0.5))` when `free={true}`.
- **Foreground/Text**: `var(--lp-accent, #9a9a9a)` by default; `var(--lp-accent-bright, #d8d8d8)` when `free={true}`.
- **Shadow**: None.
- **Min/Max size**: No explicit min/max; `white-space: nowrap` prevents children from wrapping (see the long-text edge case below), so width grows with content and height follows the font's line box plus padding.

## States

| State | Appearance change |
|-------|------------------|
| Default | Base `lp-status` styling: `--lp-hairline` border, `--lp-accent` text, transparent background |
| Free (`free={true}`) | Adds `lp-status--free`: `--lp-status-free-border` border, `--lp-accent-dim` background, `--lp-accent-bright` text |

## Accessibility

StatusPill has no interactive behavior of its own, so `screen-reader-support`, `keyboard-navigable`, and `focus-management` do not apply. It renders as a `<p>` element, which carries paragraph (block-level) semantics rather than being semantically neutral, so it MUST NOT be nested inside another `<p>`, inside a `<button>`, or inside other inline-only content (see the nesting edge case in **Edge Cases**); doing so produces invalid HTML. The status itself MUST be legible from the children text alone (see **status-conveyed-by-text**): the accented border and background are supplementary. The containing context remains responsible for heading hierarchy or ARIA roles if the status conveys structural meaning.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-pill-001 | accept-children | `<StatusPill>Active</StatusPill>` | Component renders the text "Active" within the pill |
| status-pill-002 | base-style | `<StatusPill>Free</StatusPill>` | Root element has CSS class `lp-status` |
| status-pill-003 | accent-style | `<StatusPill free={true}>Free Plan</StatusPill>` | Root element has both classes `lp-status` and `lp-status--free`, giving it `border-color: var(--lp-status-free-border)` and `background: var(--lp-accent-dim)` |
| status-pill-004 | accent-opt-in | `<StatusPill>Standard</StatusPill>` | Root element has class `lp-status` only; `lp-status--free` is absent |
| status-pill-005 | accent-opt-in | `<StatusPill free={false}>Standard</StatusPill>` | Root element has class `lp-status` only; `lp-status--free` is absent |
| status-pill-006 | status-conveyed-by-text | `<StatusPill free={true}>Free Plan</StatusPill>` | The rendered text content reads "Free Plan" regardless of the `free`-driven border and background, so the status is legible with color and border removed |

## Edge Cases

- **Long or non-wrapping text**: The base style sets `white-space: nowrap` (see **Appearance**), so the component MUST NOT wrap children onto multiple lines; long content overflows its container instead, and the parent SHOULD size or scroll to accommodate it.
- **Nesting inside inline-only content**: The component always renders a `<p>` element (see **Accessibility**). The component MUST NOT be nested inside another `<p>`, a `<button>`, or other elements that only accept inline content, since that produces invalid HTML; callers needing an inline pill SHOULD override `display` on the root or wrap it in block-level content.
- **`free` prop omitted**: When `free` is not provided, the component MUST behave identically to `free={false}` (see **accent-opt-in**).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| children | ReactNode | required | Content to render inside the pill |
| free | boolean \| undefined | undefined | When `true`, renders the accented style (see **accent-style**) via the `lp-status--free` class |

## Deep Linking

Not applicable: StatusPill is a presentational component with no navigation or deep-link behavior.

## Localization

The base style applies `text-transform: uppercase` to the children text (see **Appearance**). Casing transforms are locale-sensitive — uppercasing is not a no-op in every language (for example, Turkish's dotted/dotless I, or scripts with no case distinction at all) — so text rendered through StatusPill is always forced to uppercase by CSS regardless of the caller's locale; the component performs no locale-aware casing conversion of its own. Callers translating the children text should also expect longer translations to overflow rather than adapt, since the component neither wraps nor truncates (`white-space: nowrap`; see `text-expansion-tolerance` in **Compliance**).

## Accessibility Options

Not applicable: StatusPill has no interactive states or motion, and is a presentational wrapper only.

## Feature Flags

Not applicable: No feature flag behavior is implemented in the source.

## Analytics

Not applicable: StatusPill does not emit analytics events; event tracking is the responsibility of the parent component.

## Privacy

Not applicable: StatusPill does not collect, store, or transmit data.

## Logging

Not applicable: No logging is implemented in the source.

## Platform Notes

- **React/Web**: Component is defined in `packages/web/packages/landing/src/blocks/StatusPill.tsx`. Renders a `<p>` element with conditional CSS class application via `['lp-status', free === true ? 'lp-status--free' : ''].filter(Boolean).join(' ')`. Props are `children: ReactNode` and optional `free?: boolean`. Base and accent styling live in the `lp-status` / `lp-status--free` rules in `blocks.css` (see **Appearance**).

- **SwiftUI**: Implement as `Text` inside a pill shape. Do not clip with `.clipShape(Capsule())`, since that also clips the border stroke; instead apply `.background(Capsule().fill(backgroundColor))` and `.overlay(Capsule().stroke(borderColor, lineWidth: 1))`, switching `backgroundColor`/`borderColor` on an `isFree: Bool` parameter. Match font, letter-spacing, and uppercase casing to the source tokens (see **Localization** for the uppercase caveat).

- **Compose**: Implement using a `Text` composable inside a `Box` or `Surface`. Apply the pill shape via `shape = RoundedCornerShape(percent = 50)`, and switch the `background()`/`border()` colors on a Boolean `free` parameter, matching the source's default vs. accent tokens.

- **AppKit / UIKit**: Implement as a `UILabel` (UIKit) or `NSTextField` (AppKit) inside a small container view that draws the pill's background and border. Apply the pill shape via `layer.cornerRadius = bounds.height / 2`, and switch the border/background colors on an `isFree` property, matching the source's default vs. accent tokens.

- **WinUI 3**: Implement as a `TextBlock` inside a `Border`. Set `CornerRadius` to half the rendered height (not a fixed value) so the shape stays a pill at any size, and use `Border.Padding` — not `Margin` — to reproduce the `0.32rem × 0.6rem` padding. Switch `Background` and `BorderBrush` on a `Free` dependency property. Leave `HorizontalAlignment`/`VerticalAlignment` to the parent layout rather than fixing them on the pill itself.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/StatusPill.tsx` | unverified |

## Design Decisions

**Decision**: Render the root as a `<p>` element rather than `<span>` or `<div>`.
**Rationale**: Trades semantic neutrality for a block-level default; consumers that need it inline override `display` via CSS rather than the component switching elements itself.
**Approved**: pending

**Decision**: `free` defaults to `undefined` (falsy) rather than requiring an explicit value.
**Rationale**: Lets the common case (`<StatusPill>Active</StatusPill>`) skip passing `free={false}`.
**Approved**: pending

**Decision**: Build the class list with `['lp-status', free === true ? 'lp-status--free' : ''].filter(Boolean).join(' ')` instead of a class-name utility library.
**Rationale**: One conditional class does not justify a dependency; the filter-and-join pattern keeps the component dependency-free.
**Approved**: pending

**Decision**: Keep the prop named `free` rather than a neutral name such as `accent` or `variant`.
**Rationale**: The source docstring documents `free` as marking "the one status that gets the accented treatment" for a specific known use (a complimentary/free tier); the component was built for that one accent, not a general variant system, so the name says what it does.
**Approved**: pending

**Decision**: Keep StatusPill separate from `badge` ([adhsdk.ingredient.ui.controls.badge](cookbook:2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f)) rather than folding it in as a variant.
**Rationale**: The two differ in root element (block `<p>` here vs. inline `<span>` in badge), token namespace (`--lp-*` landing tokens vs. badge's own tokens), and variant model (one binary accent here vs. badge's six tone variants); merging them would mean badge's `<span>` consumers inherit a block element, or StatusPill's callers inherit six unrelated tones.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `blocks.css`'s `.lp-status` / `.lp-status--free` rules and `StatusPill.tsx`: foreground/background/border are theme-supplied CSS variables with hardcoded fallbacks, so contrast cannot be fully verified from the source alone; sizing uses fixed `rem` font values with no accommodation noted for native Dynamic Type; and `white-space: nowrap` with no truncation means expanded translations overflow rather than adapt, while all displayed text is caller-supplied rather than hardcoded in the component; the component is a single conditional class over caller-supplied children with no business logic (separation-of-concerns passed), and `blocks-close.test.tsx` renders it with `free` and asserts the modifier class (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and restated them behaviorally, added a status-conveyed-by-text requirement and vector for the color-only-signal risk, filled Appearance with concrete values and tokens from blocks.css, replaced low-value edge cases with the real nowrap/nesting behaviors, corrected the `<p>` semantics claim in Accessibility, reformatted Design Decisions into Decision/Rationale/Approved blocks and added two documenting the `free` naming and the badge overlap, rebuilt Compliance as a linked table with grounded statuses, rewrote Localization for the uppercase casing transform and text overflow, fixed the SwiftUI and WinUI platform notes, renamed the platform-notes bullet to React/Web, generalized the Overview while keeping the sourced usage examples, and added badge to related |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
