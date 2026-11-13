---
id: 51d3b1ba-ced7-4c08-8a63-c83094d91299
title: "Wrap"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Layout wrapper that constrains content width while allowing full-width backgrounds on the screen."
platforms:
  - typescript
  - web
tags:
  - layout
  - container
  - landing
  - content-column
depends-on: []
related:
  - 07c437af-a291-4356-bd83-c896bd4facde
  - 05930e64-fa82-49ef-b50d-22d87fa7d182
references: []
approved-by: ""
approved-date: ""
---

# Wrap

## Overview

Wrap is a presentational layout component that renders a `div` element containing child content. It applies a consistent CSS class (`lp-wrap`) and optionally accepts additional CSS classes, filtering out falsy values. The component enables a screen to paint edge-to-edge while constraining the logical content to a single centered column.

## Behavioral Requirements

- **render-children**: Component MUST render all child elements unchanged.
- **apply-lp-wrap-class**: Component MUST apply the class `lp-wrap` to the rendered div element.
- **class-composition**: Component MUST combine `lp-wrap` with an optional `className` prop, filtering out falsy values and joining the result with a space separator.
- **constrains-width**: Component MUST constrain its content to the smaller of the available width minus a fixed `2.5rem` gutter and the `--lp-measure` custom property (default `70rem`).
- **centers-horizontally**: Component MUST center itself horizontally within its containing block via `margin-inline: auto`.

## Appearance

Wrap itself accepts no appearance-related props, but it is not stylistically inert: it ships the `.lp-wrap` class as part of the landing package's own stylesheet, not the consuming application's. The rule lives in `.lp-wrap`, defined in `packages/web/packages/landing/src/css/base.css`:

```css
.lp-wrap {
  width: min(100% - 2.5rem, var(--lp-measure, 70rem));
  margin-inline: auto;
}
```

This caps content width at the smaller of two values — the available width minus a `2.5rem` gutter (`100% - 2.5rem`), or the `--lp-measure` custom property (default `70rem`) at its full value, never `--lp-measure` minus the gutter — and centers it horizontally with `margin-inline: auto`. `margin-inline: auto` splits whatever space is left outside the computed width evenly between the two sides. Only when the gutter branch is binding (the container is narrower than `--lp-measure + 2.5rem`) does that split work out to `1.25rem` per side; when `--lp-measure` is the binding branch instead, the per-side margin is `(available width - --lp-measure) / 2`, unrelated to the `2.5rem` figure.

## States

Not applicable: Wrap is a static, non-interactive container with no state-dependent behavior.

## Accessibility

Not applicable: Wrap is a transparent layout container that passes all content through to the DOM. Accessibility roles and labels are determined by the child elements it contains, not by Wrap itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wrap-001 | render-children | `<Wrap><span>Hello</span></Wrap>` | Rendered output includes `<span>Hello</span>` |
| wrap-002 | apply-lp-wrap-class | `<Wrap><div></div></Wrap>` | Rendered div has class `lp-wrap` |
| wrap-003 | class-composition | `<Wrap className={undefined}><div></div></Wrap>` | Rendered div has only the `lp-wrap` class, no `undefined` token in the class attribute |
| wrap-004 | class-composition | `<Wrap className=""><div></div></Wrap>` | Rendered div has only the `lp-wrap` class |
| wrap-005 | class-composition | `<Wrap className="custom"><div></div></Wrap>` | Class attribute reads exactly `lp-wrap custom` |
| wrap-006 | constrains-width | `<Wrap><div></div></Wrap>` rendered in a 1200px-wide block with `--lp-measure` unset | Computed width is `min(100% - 2.5rem, 70rem)` — `70rem` (1120px at a 16px root) rather than the full 1200px |
| wrap-007 | centers-horizontally | `<Wrap><div></div></Wrap>` rendered in a block wider than `--lp-measure` | Computed `margin-inline-start` equals computed `margin-inline-end` |

## Edge Cases

- **Empty children**: Wrap MUST render an empty div when children is undefined, null, or an empty array. The `lp-wrap` class is still applied.
- **Undefined or empty-string className**: TypeScript's `className?: string` signature restricts the prop to `string | undefined`, so only these two falsy shapes can reach `.filter(Boolean)`; both are dropped, leaving only `lp-wrap` (see **class-composition**).
- **Direct child of a non-centered Screen**: When Wrap is a direct child of `.lp-screen` (excluding `.lp-screen--center`), it additionally receives `min-height: max(0px, calc(100vh / 3 - var(--lp-screen-pad-top, ...)))` and `align-content: safe center` (the `.lp-screen:not(.lp-screen--center) > .lp-wrap` rule in `base.css`). This is Screen's rule reaching into its Wrap child, not a property of Wrap in isolation. The `safe` keyword falls back to start alignment when the content is taller than that band, so overflow pushes content down into view rather than up and out of reach behind the fixed header.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--lp-measure` | CSS custom property (length) | `70rem` | Maximum content width Wrap caps its children at. |
| gutter | fixed, not configurable | `2.5rem` | Subtracted once from the available width (`100% - 2.5rem`) — total across both sides, not per side — before comparing that result to `--lp-measure` and taking the smaller. When this branch wins, centering splits it evenly into `1.25rem` per side; when `--lp-measure` wins instead, the gutter plays no role in the actual per-side margin. |

## Deep Linking

Not applicable: Wrap is a layout container with no semantic URL representation or deep-linking capability.

## Localization

Not applicable: Wrap contains no user-facing strings or localization concerns.

## Accessibility Options

Not applicable: Wrap is a transparent container that does not respond to accessibility display options.

## Feature Flags

Not applicable: Wrap is a foundational layout component with no feature flag gates.

## Analytics

Not applicable: Wrap is a non-interactive container that produces no user interaction events.

## Privacy

Not applicable: Wrap does not collect, store, or transmit any data.

## Logging

Not applicable: Wrap is a simple presentational component with no noteworthy lifecycle or state change events to log.

## Platform Notes

- **TypeScript / Web**: React functional component in `packages/web/packages/landing/src/deck/Wrap.tsx`. Accepts `children: ReactNode` and `className?: string`, combined via `['lp-wrap', className].filter(Boolean).join(' ')`. Width and centering come from the `.lp-wrap` rule in `packages/web/packages/landing/src/css/base.css` (`width: min(100% - 2.5rem, var(--lp-measure, 70rem)); margin-inline: auto`).
- **SwiftUI**: read the available width via `GeometryReader`, compute `min(proposedWidth - 40, measure)` (mirroring the source's `min(100% - 2.5rem, var(--lp-measure))`), and apply that as an explicit `.frame(width:)` centered with `.frame(maxWidth: .infinity, alignment: .center)`. A separate `.frame(maxWidth: measure).padding(.horizontal)` applies the gutter inside the measure cap instead of choosing the smaller of the two, and does not reproduce the source's behavior.
- **Compose**: compute `min(constraints.maxWidth - gutterPx, measurePx)` in a custom `Layout` (or `Modifier.layout`) and constrain the child to that computed width before centering. `Modifier.widthIn(max = measure).padding(horizontal = gutter)` applies the gutter inside the measure cap rather than choosing between the two alternatives, and does not reproduce the source's behavior.
- **AppKit / UIKit**: constrain the content to an explicit width constraint computed as `min(superview width - 40, measure)`, centered in its superview, rather than subclassing `NSView` / `UIView`. A fixed readable-width constraint plus separate edge insets has the same mismatch as the SwiftUI/Compose notes above.
- **WinUI 3**: bind `MaxWidth` to a value computed as `Math.Min(availableWidth - 40, measure)` (mirroring the source's `min()`), `HorizontalAlignment="Center"`. A static `MaxWidth` set to `measure` plus a separate fixed `Padding` for the gutter applies the gutter inside the cap instead of choosing the smaller of the two, and does not reproduce the source's behavior. Wrap holds one content tree, not a collection, so no `VisualStateManager` or visibility converters are needed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/deck/Wrap.tsx` | unverified |

## Design Decisions

**Decision**: Compose the div's class list with `['lp-wrap', className].filter(Boolean).join(' ')` rather than a conditional ternary.
**Rationale**: `.filter(Boolean)` handles `className` being `undefined` or an empty string uniformly, without an explicit type guard, even though the `className?: string` signature already restricts the prop to those two falsy shapes at compile time.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The first two rest on the `.lp-wrap` rule in `base.css`: the cap and gutter are expressed in `rem`, so they scale with root font-size / type-size settings, and Wrap renders a plain `div` with no ARIA roles or attributes of its own to misuse. `separation-of-concerns` passes because `Wrap.tsx` itself holds no width/gutter logic at all — it only joins class names — and that logic lives entirely in the `.lp-wrap` CSS rule. `unit-test-coverage` is partial: `deck.test.tsx`'s `Wrap` block only confirms the `lp-wrap` class is applied; the `min()` cap-vs-gutter behavior this revision corrects is expressed in CSS and has no unit test (jsdom does not compute layout), so it can only be verified by reading the stylesheet.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed gutter/measure min() math (total not per-side); dropped source line-number citations. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and merged the className ones into class-composition; added constrains-width and centers-horizontally with vectors; corrected Appearance to cite the package stylesheet; documented --lp-measure and the gutter under Configuration; fixed Platform Notes for SwiftUI, Compose, AppKit/UIKit, and WinUI 3; reformatted Design Decisions and replaced Compliance with a checks table; added tags, related entries, and the Screen band/safe-center edge case |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
