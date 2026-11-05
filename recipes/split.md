---
id: 8F4C2B7A-9D3E-4C5F-B2E8-7F6A3C1D5E9B
title: Split
domain: adhsdk://recipes/split
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Responsive layout container that renders two panels side by side on wide
  viewports and stacked on narrow ones.
platforms:
- typescript
- web
tags:
- layout
- responsive
depends-on: []
related:
- adhsdk://recipes/deck
- adhsdk://recipes/screen
- adhsdk://recipes/wrap
references: []
approved-by: ''
approved-date: ''
---

# Split

## Overview

Split is a responsive layout container that arranges child elements in two columns on wide viewports and switches to a single-column stacked layout below a specified breakpoint. It is commonly used to position prose content beside an illustration or complementary visual element.

## Behavioral Requirements

- **renders-children**: Component MUST render all child elements passed to it.
- **root-class**: Component MUST apply the `lp-split` class to its root element.
- **merges-classname**: Component MUST merge the `lp-split` class with any additional `className` prop provided, applying both to the root element with no empty or duplicate class tokens.
- **responsive-breakpoint**: Component MUST lay out children as a single-column CSS Grid (`2rem` gap) below a `62rem` (992px) viewport width, and switch to a two-column CSS Grid (`grid-template-columns: minmax(0, 5fr) minmax(0, 6fr)`, `3rem` gap) at and above that breakpoint, as defined in `packages/web/packages/landing/src/css/base.css`.
- **preserves-reading-order**: Component MUST NOT reorder its children visually relative to DOM order (no CSS `order` or `row-reverse`), and the root element MUST carry no ARIA role, per WCAG 1.3.2 (Meaningful Sequence).

## Appearance

- **Layout**: CSS Grid — single column (stacked, top-to-bottom) below `62rem` (992px); two-column grid (`minmax(0, 5fr) minmax(0, 6fr)`) at and above it
- **Container**: `display: grid` (a single layout model; see Design Decisions and Platform Notes)
- **Breakpoint**: `62rem` (992px), defined in `packages/web/packages/landing/src/css/base.css`
- **Gap**: `2rem` below the breakpoint, `3rem` at and above it
- **Padding**: Inherited from component nesting and layout context
- **Background**: Transparent (inherits from parent)
- **Foreground/Text**: Inherits from child elements
- **Border**: None by default
- **Shadow**: None by default
- **Min/Max size**: No explicit constraints; see edge case **very-wide viewports**

## States

Split is a stateless layout container with no interactive states.

| State | Appearance change |
|-------|------------------|
| Default | Two columns wide / single column narrow |

## Accessibility

Split is a generic container with no interactive semantics. Child elements retain their own accessibility properties. The component itself requires no special accessibility attributes — semantic meaning is determined by its children. Per **preserves-reading-order**, the root carries no ARIA role, and DOM order matches visual order (WCAG 1.3.2, Meaningful Sequence) in both the stacked and two-column layouts.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-001 | renders-children | Two `<div>` children | Both children rendered in DOM |
| split-002 | root-class | No `className` prop | Root element has class `lp-split` |
| split-003 | merges-classname | `className="custom-class"` | Root element has both `lp-split` and `custom-class` in its `classList` (order not asserted; verified via `classList.contains`, not string equality) |
| split-004 | responsive-breakpoint | Playwright, viewport 900px then 1024px (bracketing the `62rem`/992px breakpoint) | Computed `grid-template-columns` changes from a single track to two tracks in a `5:6` ratio; jsdom cannot evaluate the media query, so this vector runs only in Playwright |
| split-005 | preserves-reading-order | Two `<div>` children, inspected at both breakpoint states | Root element has no `role` attribute; each child's DOM order matches its visual order |
| split-006 | responsive-breakpoint | Playwright, viewport ≥992px, `dir="rtl"` on an ancestor | The first child's bounding box is to the right of the second child's — native CSS Grid direction-aware mirroring, since `css/base.css` sets no explicit `direction` override |
| split-007 | merges-classname | `className={undefined}`, then `className=""` | Root `classList` is exactly `['lp-split']`; the `class` attribute string has no leading/trailing whitespace and no empty token |
| split-008 | renders-children | No children | Root renders with class `lp-split` and zero child DOM nodes; no error thrown |
| split-009 | renders-children | One `<div>` child | Child renders normally; `grid-template-columns` is unaffected by child count at either breakpoint state |
| split-010 | responsive-breakpoint | Playwright, viewport 2560px | Column widths remain in a `5:6` ratio (`minmax(0, 5fr) minmax(0, 6fr)`); no `max-width` is applied |
| split-011 | responsive-breakpoint | Playwright, viewport 320px | Single-column stack; no horizontal overflow/scrollbar |

## Edge Cases

- **Empty children**: When no children are provided, the component renders an empty `lp-split` container; this is not an error state. See split-008.
- **Single child**: When only one child is provided, the component renders it within the split container; the single-column layout renders it normally, and in the two-column layout the second grid cell is simply empty — the column ratio and breakpoint are unaffected by child count. See split-009.
- **Empty or undefined className**: `className` is typed `string | undefined`, never `null`. When it is `undefined` or `""`, the component does not append an empty class token or trailing whitespace; only `lp-split` (or `lp-split` plus a non-empty `className`) is applied. See split-007.
- **Viewport resize**: The component responds to dynamic viewport resizes (e.g., orientation change, window resize) via the CSS media query at `62rem`; no JavaScript-based resize listener is implemented. See split-004.
- **Very wide viewports**: No maximum width is enforced, by design — the `fr`-based column tracks scale to fill the available width in a `5:6` ratio. Capping the overall width is the parent's responsibility (for example, composing `Split` inside `Wrap`, which constrains the content column). See split-010.
- **Very narrow viewports**: Below the `62rem` breakpoint the component stacks to a single column with no minimum width enforced. See split-011.
- **RTL directionality**: `Split` sets no explicit `direction`, so CSS Grid's native direction-aware column placement mirrors the two-column layout under an ancestor `dir="rtl"` without any component-level code; this is not yet exercised by an automated test. See split-006 and Localization.

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

- **TypeScript/Web**: `Split.tsx` accepts `children: ReactNode` and optional `className?: string`. Renders a `<div>` with class `lp-split` merged with any provided `className`. The single-to-two-column switch, the `62rem` breakpoint, the `minmax(0, 5fr) minmax(0, 6fr)` column template, and the `2rem`/`3rem` gap are all defined in `packages/web/packages/landing/src/css/base.css`.
- **SwiftUI**: Use `ViewThatFits` or an `AnyLayout` switched between an `HStack` (two-column, `5:6` proportions) and a `VStack` (single column), driven by the container's measured width (e.g., via a `GeometryReader` or a horizontal size class) against the `992pt` breakpoint — not an imperative resize callback.
- **Compose**: Use `BoxWithConstraints` to read the available width and switch between a `Row` (two-column, `Modifier.weight(5f)` / `Modifier.weight(6f)`) and a `Column` (single column) at `992.dp`; `LocalConfiguration.current.screenWidthDp` measures the screen, not the container, and MUST NOT be used here.
- **AppKit / UIKit**: On iOS, use a `UIStackView` with `axis` toggled between `.horizontal` and `.vertical`, driven by `registerForTraitChanges(_:handler:)` on `UITraitHorizontalSizeClass` (`traitCollectionDidChange(_:)` is deprecated). AppKit has no size classes; on macOS, drive the equivalent `NSStackView` orientation from the container's measured width (e.g., a resize-driven Auto Layout constraint swap) against the `992pt` breakpoint instead.
- **WinUI 3**: Use a `Grid` with `VisualStateManager` and an `AdaptiveTrigger` (`MinWindowWidth="992"`) to declare a two-column state (`ColumnDefinitions="5*,6*"`) and a single-column state below it — matching the declarative approach in Design Decisions. Do not drive this with a `SizeChanged` event handler or `Window.Current.Bounds`, which is null in WinUI 3 desktop apps.

## Design Decisions

**Decision**: All styling and layout values — the breakpoint (`62rem`/992px), the column template (`minmax(0, 5fr) minmax(0, 6fr)`), and the gap (`2rem` stacked, `3rem` two-column) — live in CSS (`packages/web/packages/landing/src/css/base.css`), not in the component. The component only renders children with the merged `lp-split`/`className` classes.
**Rationale**: Keeps the component stateless and its responsibility narrow; centralizing the values in one CSS file keeps this spec from drifting out of sync with the actual breakpoint. Platform ports should mirror this: use a native declarative layout primitive (SwiftUI `ViewThatFits`/`AnyLayout`, Compose `BoxWithConstraints`, a WinUI `Grid` with `AdaptiveTrigger`) driven by measured width or size class, rather than an imperative resize/orientation event handler.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on `Split.tsx` rendering a bare `<div>` with no ARIA role or attributes (semantic-markup), and on `css/base.css` defining the two-column grid with no explicit `direction` override, which gives native RTL mirroring but is not yet exercised by an automated test (rtl-layout-support). `separation-of-concerns` passes because `Split.tsx` is pure presentation, with all layout values living in CSS rather than the component. `unit-test-coverage` fails because no test in the repository renders `Split` — the landing package's `deck.test.tsx` covers `Screen` and `Deck` but not `Split`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: stated concrete breakpoint/column/gap values from `css/base.css`; collapsed Appearance to a single CSS Grid model; renamed requirements to subject-only kebab-case everywhere they're cited; reformatted Design Decisions to Decision/Rationale/Approved; corrected Platform Notes to real native APIs (WinUI `Grid`+`AdaptiveTrigger`, Compose `BoxWithConstraints`, UIKit `registerForTraitChanges`, SwiftUI `ViewThatFits`) and aligned WinUI with the declarative Design Decision; linked Compliance rows to real catalog checks; added a reading-order requirement and RTL edge case with vectors; added missing edge-case test vectors; added related landing-layout siblings |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
