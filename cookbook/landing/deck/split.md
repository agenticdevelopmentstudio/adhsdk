---
id: 8f4c2b7a-9d3e-4c5f-b2e8-7f6a3c1d5e9b
title: "Split"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Responsive layout container that renders two panels side by side on wide viewports and stacked on narrow ones."
platforms:
  - typescript
  - web
tags:
  - layout
  - responsive
depends-on: []
related:
  - 05930e64-fa82-49ef-b50d-22d87fa7d182
  - 07c437af-a291-4356-bd83-c896bd4facde
  - 51d3b1ba-ced7-4c08-8a63-c83094d91299
references: []
approved-by: ""
approved-date: ""
---

# Split

## Overview

Split is a responsive layout container that arranges child elements in two columns on wide viewports and switches to a single-column stacked layout below a specified breakpoint. It is commonly used to position prose content beside an illustration or complementary visual element.

## Behavioral Requirements

- **renders-children**: Component MUST render all child elements passed to it.
- **root-class**: Component MUST apply the `lp-split` class to its root element.
- **merges-classname**: Component MUST merge the `lp-split` class with any additional `className` prop provided, applying both to the root element with no empty or duplicate class tokens.
- **responsive-breakpoint**: Component MUST lay out children as a single-column CSS Grid below the breakpoint and switch to a two-column CSS Grid at and above it, using the layout, breakpoint and gap values stated once in `#appearance/layout`, `#appearance/breakpoint` and `#appearance/gap`.
- **preserves-reading-order**: Component MUST NOT reorder its children visually relative to DOM order (no CSS `order` or `row-reverse`), and the root element MUST carry no ARIA role, per WCAG 1.3.2 (Meaningful Sequence).

## Appearance

- **Layout**: CSS Grid — single column (stacked, top-to-bottom) below `62rem` (992px); two-column grid (`minmax(0, 5fr) minmax(0, 6fr)`) at and above it
- **Container**: `display: grid` (a single layout model; see Design Decisions and Platform Notes)
- **Breakpoint**: `62rem` is the authority; `992px` is its value only at the browser's default 16px root font size, and a reader who has raised the default font size gets the two-column layout at a proportionally wider viewport. Native ports match `62rem`, not a fixed `992`. Defined in `packages/web/packages/landing/src/css/base.css`
- **Gap**: `2rem` below the breakpoint, `3rem` at and above it
- **Padding**: Inherited from component nesting and layout context
- **Background**: Transparent (inherits from parent)
- **Foreground/Text**: Inherits from child elements
- **Border**: None by default
- **Shadow**: None by default
- **Min/Max size**: No explicit constraints; see `#edge-cases/very-wide-viewports`

## States

Split is a stateless layout container with no interactive states.

| State | Appearance change |
|-------|------------------|
| Default | Two columns wide / single column narrow |

## Accessibility

Split is a generic container with no interactive semantics. Child elements retain their own accessibility properties. The component itself requires no special accessibility attributes — semantic meaning is determined by its children. Per **preserves-reading-order**, the root carries no ARIA role, and DOM order matches visual order (WCAG 1.3.2, Meaningful Sequence) in both the stacked and two-column layouts.

## Conformance Test Vectors
## Edge Cases

- **empty-children**: When no children are provided, the component renders an empty `lp-split` container; this is not an error state. See split-008.
- **single-child**: When only one child is provided, the component renders it within the split container; the single-column layout renders it normally, and in the two-column layout the second grid cell is simply empty — the column ratio and breakpoint are unaffected by child count. See split-009.
- **empty-or-undefined-classname**: `className` is typed `string | undefined`, never `null`. When it is `undefined` or `""`, the component does not append an empty class token or trailing whitespace; only `lp-split` (or `lp-split` plus a non-empty `className`) is applied. See split-007.
- **viewport-resize**: The component responds to dynamic viewport resizes (e.g., orientation change, window resize) via the CSS media query at `62rem`; no JavaScript-based resize listener is implemented. See split-004.
- **very-wide-viewports**: No maximum width is enforced, by design — the `fr`-based column tracks scale to fill the available width in a `5:6` ratio. Capping the overall width is the parent's responsibility (for example, composing `Split` inside `Wrap`, which constrains the content column). See split-010.
- **very-narrow-viewports**: Below the `62rem` breakpoint the component stacks to a single column with no minimum width enforced. See split-011.
- **rtl-directionality**: `Split` sets no explicit `direction`, so CSS Grid's native direction-aware column placement mirrors the two-column layout under an ancestor `dir="rtl"` without any component-level code; vector split-006 defines the test, but it is not yet implemented. See split-006 and Localization.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | required | Content to render within the split container |
| `className` | `string` | `undefined` | Additional CSS class(es) to merge with `lp-split` |

## Deep Linking

Not applicable: Split is a layout container without independent navigation or state representation.

## Localization

Split renders no user-facing text of its own — there are no strings to externalize. As a two-column layout, though, it is direction-sensitive: see edge case **RTL directionality** and vector split-006 for how the column order mirrors under `dir="rtl"`.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; Split contains no motion or animation. Behavior is determined by child components. |
| Increase Contrast | Not applicable; Split has no visual styling. Contrast is determined by child components. |
| Differentiate Without Color | Not applicable; Split is a layout container with no color-dependent information. |

## Feature Flags

Not applicable: Split is a foundational layout component with no conditional feature behavior.

## Analytics

Not applicable: Split is a structural component that does not track user interactions.

## Privacy

Not applicable: Split does not collect, store, or transmit any data.

## Logging

Not applicable: Split is a presentation component with no runtime state changes to log.

## Platform Notes

- **React/Web**: `Split.tsx` accepts `children: ReactNode` and optional `className?: string`. Renders a `<div>` with class `lp-split` merged with any provided `className`. The layout switch, breakpoint, column template and gap are stated once in `#appearance/layout`, `#appearance/breakpoint` and `#appearance/gap`.
- **SwiftUI**: Use an `AnyLayout` switched between an `HStack` (two-column, `5:6` proportions) and a `VStack` (single column), driven by the container's measured width (via `onGeometryChange` or a `GeometryReader`) against the `62rem` breakpoint (`992pt` at a 16px root). Do not use `ViewThatFits`: it chooses a layout by whether it fits, not by a fixed width, so it cannot honour the breakpoint.
- **Compose**: Use `BoxWithConstraints` to read the available width and switch between a `Row` (two-column, `Modifier.weight(5f)` / `Modifier.weight(6f)`) and a `Column` (single column) at `992.dp`; `LocalConfiguration.current.screenWidthDp` measures the screen, not the container, and MUST NOT be used here.
- **AppKit / UIKit**: On iOS, use a `UIStackView` with `axis` toggled between `.horizontal` and `.vertical`, driven by `registerForTraitChanges(_:handler:)` on `UITraitHorizontalSizeClass` (`traitCollectionDidChange(_:)` is deprecated). AppKit has no size classes; on macOS, host the SwiftUI `AnyLayout` described above in an `NSHostingView`, which keeps the layout declarative, rather than swapping `NSStackView` orientation or Auto Layout constraints in a resize handler. The breakpoint is `62rem` (`992pt` at a 16px root).
- **WinUI 3**: Use a `Grid` with `VisualStateManager` and an `AdaptiveTrigger` (`MinWindowWidth="992"`) to declare a two-column state (`ColumnDefinitions="5*,6*"`) and a single-column state below it — matching the declarative approach in Design Decisions. Do not drive this with a `SizeChanged` event handler or `Window.Current.Bounds`, which is null in WinUI 3 desktop apps.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/deck/Split.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: All styling and layout values (breakpoint, column template and gap, stated in Appearance) live in CSS, not in the component. The component only renders children with the merged `lp-split`/`className` classes.
**Rationale**: Keeps the component stateless and its responsibility narrow; centralizing the values in one CSS file, and stating them once in Appearance, keeps this spec from drifting out of sync with the actual breakpoint. Platform ports should mirror this: use a native declarative layout primitive (SwiftUI `AnyLayout`, including inside an `NSHostingView` on macOS; Compose `BoxWithConstraints`; a WinUI `Grid` with `AdaptiveTrigger`) driven by measured width or size class, rather than an imperative resize/orientation event handler.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on `Split.tsx` rendering a bare `<div>` with no ARIA role or attributes (semantic-markup), and on `css/base.css` defining the two-column grid with no explicit `direction` override, which gives native RTL mirroring but is covered by vector split-006, which is defined but not yet implemented (rtl-layout-support). `separation-of-concerns` passes because `Split.tsx` is pure presentation, with all layout values living in CSS rather than the component. `unit-test-coverage` fails because no test in the repository renders `Split` — the landing package's `deck.test.tsx` covers `Screen` and `Deck` but not `Split`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Stated the breakpoint, columns and gap once in Appearance, made 62rem authoritative over 992px, made macOS and SwiftUI guidance declarative (AnyLayout only), renamed React/Web, kebab-cased edge cases and sharpened vectors and RTL wording. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: stated concrete breakpoint/column/gap values from `css/base.css`; collapsed Appearance to a single CSS Grid model; renamed requirements to subject-only kebab-case everywhere they're cited; reformatted Design Decisions to Decision/Rationale/Approved; corrected Platform Notes to real native APIs (WinUI `Grid`+`AdaptiveTrigger`, Compose `BoxWithConstraints`, UIKit `registerForTraitChanges`, SwiftUI `ViewThatFits`) and aligned WinUI with the declarative Design Decision; linked Compliance rows to real catalog checks; added a reading-order requirement and RTL edge case with vectors; added missing edge-case test vectors; added related landing-layout siblings |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
