---
id: a63de97e-d75c-4733-a875-bad20e001fcb
title: "Stats"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A three-column grid of statistics that wraps at narrow widths: number-and-caption pairs scanned in one visual sweep."
platforms:
  - typescript
  - web
tags:
  - statistics
  - data-display
  - semantic-html
depends-on: []
related:
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/73b254b4-c611-434a-a9f4-67c8a7155576
  - 4cd07922-a00d-4029-8cb5-2307463129cc
  - 7e4a2c5b-8f3d-4a7e-b9f2-1c5e8d3b6a2f
references: []
approved-by: ""
approved-date: ""
---

# Stats

## Overview

Stats renders a three-column grid of statistics pairs—each a number or metric (`term`) paired with its explanation or label (`detail`). At viewport widths of 34rem (≈544px at the browser's default 16px font size; a media query's `rem` resolves against that initial size, not the page's root font size) and above, entries lay out three per row and a fourth entry wraps onto a new row; below 34rem — for example at 375px — the grid collapses to a single column and entries stack one per row. The component is designed for quick visual scanning across multiple statistics without interaction. It uses semantic HTML (`dl`, `dt`, `dd`) to encode the relationship between statistic and caption, making it accessible and SEO-friendly. Use it to display side-by-side key metrics, counts, or comparable measurements.

## Behavioral Requirements

- **render-entries**: Component MUST render one entry for each item in the `entries` array.
- **wrap-each-entry**: Component MUST wrap each entry in its own `div` container (the wrapper div, not the `dl`, is the grid item).
- **render-term-and-detail**: Component MUST render the `term` and `detail` of each entry as `dt` and `dd` elements respectively within the entry wrapper.
- **preserve-node-content**: Component MUST accept and render `term` and `detail` as `ReactNode`, preserving inline elements, text, and component structures passed by the caller.
- **use-semantic-markup**: Component MUST wrap all entries in a `dl` (description list) element to encode the statistical relationship.
- **maintain-order**: Component MUST render entries in the order they appear in the `entries` array.

- **three-column-wrap**: At viewport widths of 34rem and above, Component MUST lay entries out three per row, with a fourth entry wrapping onto a new row; below 34rem it MUST collapse to a single column with entries stacked one per row.
## Appearance

- **Layout**: Explicit three-column grid (`grid-template-columns: repeat(3, minmax(0, 1fr))`) at viewport widths ≥34rem; a fourth entry wraps onto a new row rather than forcing a fourth column. Below 34rem the grid collapses to `grid-template-columns: minmax(0, 1fr)` and entries stack one per row. The column count is declared explicitly rather than derived from an `auto-fit`/`auto-fill` floor — see Design Decisions. Defined in `packages/web/packages/landing/src/css/blocks.css`.
- **Container**: `dl` with class `lp-stats`.
- **Grid item**: Each entry is wrapped in its own `div`. That wrapper carries no class of its own — the `lp-stats` class lives on the `dl`, and the wrapper is styled only through the `.lp-stats div` descendant selector in `packages/web/packages/landing/src/css/blocks.css`.
- **Grid**: `1rem` gap and `2rem` top margin.
- **Entry wrapper**: a hairline start-side divider (`1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`) with `1rem` padding on that side. The web CSS writes it as physical `border-left` and `padding-left`, so it does not flip under `dir="rtl"`.
- **Term (`dt`)**: font size `clamp(1.3rem, 3vw, 1.8rem)`, weight 200, line height 1.3, color `var(--lp-accent-bright, #d8d8d8)`.
- **Detail (`dd`)**: font size `0.8rem`, letter-spacing `0.06em`, color `var(--lp-ink-dim, #a0a0a0)`.

## States

Not applicable: Stats is a static, non-interactive component. It has no pressed, disabled, focused, loading, or hover states.

## Accessibility

- **Semantic structure**: The `dl`/`dt`/`dd` markup encodes a description-list relationship: each entry's `dt` holds the statistic's value (the `term`) and its `dd` holds the caption that explains it (the `detail`). Screen-reader support for the `dl`/`dt`/`dd` pattern is inconsistent across assistive technology, so this markup is a progressive enhancement rather than a guarantee that the relationship will be announced.
- **Label requirement**: No separate `aria-label` is added by the component. Each entry pairs the value (`dt`) with its caption (`dd`) in a single wrapper `div`, which conveys the relationship visually regardless of how a given screen reader handles `dl`/`dt`/`dd`.
- **Minimum tap/click target**: Inline text links within `term` or `detail` are exempt from touch-target minimums. If interactive elements (buttons, links) are added to the term or detail content by the caller, those elements SHOULD each have a minimum touch target of 44×44pt (per [adc.guideline.implementing.ui.touch-click-targets](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/73b254b4-c611-434a-a9f4-67c8a7155576)).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|-------|----------------------------------------|-------------------|-------------|
| stats-001 | render-entries, wrap-each-entry | `entries: [{term: "10", detail: "Users"}]` | Component renders one entry as a `div` child of the `dl` |
| stats-002 | render-entries | `entries: [{...}, {...}, {...}]` (3 items) | Component renders three entry wrapper divs |
| stats-003 | render-term-and-detail | `entries: [{term: "42", detail: "Days"}]` | Rendered as `<dt>42</dt><dd>Days</dd>` within the entry div |
| stats-004 | preserve-node-content | `entries: [{term: <strong>99</strong>, detail: "Active"}]` | Strong element is preserved and rendered within the `dt` |
| stats-005 | preserve-node-content | `entries: [{term: "10", detail: <em>Total Users</em>}]` | Em element is preserved and rendered within the `dd` |
| stats-006 | use-semantic-markup | Any valid entries array | Top-level element is `dl` with class `lp-stats` |
| stats-007 | maintain-order | `entries: [{term: "A", detail: "First"}, {term: "B", detail: "Second"}]` | First entry renders before second entry in DOM order |
| stats-008 | render-entries | `entries: []` | Component renders an empty `dl` with class `lp-stats` and no child `div`s |
| stats-009 | preserve-node-content | `entries: [{term: null, detail: "Users"}]` | Component renders an empty `dt` within the entry `div`; `dd` renders normally |

| stats-010 | three-column-wrap | Playwright at 375px viewport width, 3 entries | One column: each entry's top offset is greater than the previous entry's, and all share one left edge |
| stats-011 | three-column-wrap | Playwright at 768px and 1440px viewport width, 4 entries | Three entries share a row (same top offset) and the fourth is on a new row under the first column |
## Edge Cases

- **Empty entries array**: If `entries` is an empty array, the component MUST render an empty `dl` with class `lp-stats` and no child divs (see #test-vectors/stats-008).
- **Single entry**: If `entries` contains only one item, the component MUST render that entry in a single wrapper div. At viewport widths ≥34rem the three-column grid places it in the first column, leaving the remaining two columns of that row empty (see #requirements/three-column-wrap).
- **Null or undefined ReactNode content**: If `term` or `detail` is `null` or `undefined`, the component MUST render the corresponding `dt` or `dd` as an empty element (see #test-vectors/stats-009). The component does not skip or substitute placeholder content for a null/undefined entry: `entries` is rendered positionally and unconditionally, so silently dropping an item would break the one-to-one correspondence between the `entries` array and the rendered list. Callers that want to omit a statistic MUST filter it out of `entries` before passing it to the component, rather than passing `null`/`undefined` `term`/`detail`.
- **Large content in term or detail**: If the `term` or `detail` contains very long text or large inline components, layout may wrap or overflow according to CSS rules; the component itself places no constraint on content size.
- **React Fragments or multiple children**: If the caller passes a React Fragment or array as the `term` or `detail`, the Fragment/array is rendered as-is within the `dt` or `dd`. React handles this transparently.

## Configuration

| Option | Type | Default | Required | Description |
|--------|------|---------|----------|-------------|
| `entries` | `StatEntry[]` | — | Yes | Array of `{term: ReactNode, detail: ReactNode}` objects to display. |

## Deep Linking

Not applicable: Stats is a display-only component without its own route or deep-link semantics. Any deep linking is handled by the consuming page or application.

## Localization

The grid columns follow the document's writing direction under `dir="rtl"`: `packages/web/packages/landing/src/css/blocks.css` declares `grid-template-columns` with no explicit `direction` or column-order override. The entry divider is not mirrored: `.lp-stats div` uses the physical `border-left` and `padding-left`, so under RTL the divider stays on the left, the wrong side. Logical properties (`border-inline-start`, `padding-inline-start`) would fix it; until the stylesheet changes, RTL support is partial. Native ports SHOULD use leading-edge (start) dividers. Stats accepts `term` and `detail` as `ReactNode`, giving the caller full control over localized content; the component renders whatever is passed and applies no formatting of its own. Callers MUST format numbers (and any other locale-sensitive values) for the user's locale before passing them as `term`/`detail` — an invariant/culture-insensitive formatter would render the wrong digit grouping, decimal separator, or numeral system for the viewer's locale.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Stats is static and contains no animations. |
| Increase Contrast | Not applicable: The component sets no colors itself, but `blocks.css` supplies fallbacks that render whenever the host leaves the `--lp-*` variables unset: `#d8d8d8` for terms, `#a0a0a0` for details and `rgba(216, 216, 216, 0.18)` for the divider. Their contrast against the host background has not been checked; the divider is decorative. |
| Differentiate Without Color | Not applicable: Stats uses semantic HTML and does not rely on color alone to convey meaning. The `dt`/`dd` structure encodes the relationship independent of color. |

## Feature Flags

Not applicable: Stats contains no conditional features or toggles. All functionality is always active.

## Analytics

Not applicable: Stats is a static display component and does not emit user-interaction events. Any analytics tracking is the responsibility of the consumer context or parent component.

## Privacy

Not applicable: Stats does not collect, store, or transmit user data. It simply renders content passed to it.

## Logging

Not applicable: Stats does not emit logs. Errors in rendering (e.g., invalid React children) are reported by React's own dev-mode warnings, not by the component.

## Platform Notes

- **TypeScript/Web (React)**: See `packages/web/packages/landing/src/blocks/Stats.tsx`. The component returns a `dl` with class `lp-stats` containing entry wrapper `div`s (no class of their own), each with a `dt` (term) and `dd` (detail). Styling and the three-column grid are defined in `packages/web/packages/landing/src/css/blocks.css`; the column count is declared explicitly rather than derived from an `auto-fit`/`auto-fill` floor (see Design Decisions, and #requirements/three-column-wrap for the layout).
- **SwiftUI**: Use `Grid` or `LazyVGrid` with three columns (for example three `GridItem(.flexible())` tracks) rather than `HStack`, so a fourth entry wraps onto a new row instead of forcing a fourth column. Each statistic is a `VStack` with `Text` for the term (value) and a smaller secondary `Text` for the detail (label). Group each pair into one accessibility element with `.accessibilityElement(children: .combine)` so assistive technology announces the value and its caption together. No semantic equivalent to `dl`/`dt`/`dd` exists in SwiftUI; label each statistic via proximity, visual hierarchy, and the combined accessibility element.
- **Compose**: Use `LazyVerticalGrid(columns = GridCells.Fixed(3))`, or `FlowRow` with `maxItemsInEachRow = 3`, rather than a plain `Row`, so a fourth entry wraps instead of forcing a fourth column. Each statistic is a `Column` containing a `Text` for the term (value, larger) and a `Text` for the detail (label, smaller). Apply `Modifier.semantics(mergeDescendants = true)` to each statistic's `Column` so it is announced as one element. Compose has no semantic description-list equivalent; the visual arrangement, size difference, and merged semantics convey the relationship.
- **AppKit / UIKit**: On macOS, use `NSGridView` configured for three columns (or nested `NSStackView`s following the SwiftUI/Compose pattern above), with each statistic's value/caption pair wrapped as one `NSAccessibilityElement` combining the term and detail. On iOS, use `UICollectionView` with a compositional or flow layout fixed to three items per row — not `UIStackView`, which lays every entry in one row that never wraps. Each cell hosts a `UILabel` for the term (larger font, prominent) and a `UILabel` for the detail (smaller font, secondary), wrapped in a single `UIAccessibilityElement` with an `accessibilityLabel` combining term and detail (e.g., "10 users").
- **WinUI 3**: Use a `Grid` with three star-sized columns (`ColumnDefinition Width="*"` × 3), or `ItemsRepeater` with a `UniformGridLayout` (`MaximumRowsOrColumns = 3`), rather than a horizontal `StackPanel`, which never wraps and ignores `Stretch`/`Width="Auto"` when sharing width. Each statistic is a vertical `StackPanel` containing a `TextBlock` for the term (larger `FontSize`, `FontWeight.Bold`) and a `TextBlock` for the detail (smaller `FontSize`, `Opacity=0.7`). Set `AutomationProperties.Name` on each statistic's container (not on the outer `Grid`/`ItemsRepeater`) so assistive technology announces each pair individually.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Stats.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Each entry is wrapped in its own `div` rather than placing `dt` and `dd` directly as children of the `dl`.
**Rationale**: This lets the CSS grid layout in `packages/web/packages/landing/src/css/blocks.css` treat each entry pair as a single grid item; the `dl` itself is not the grid container — the wrapper `div`s are the grid items.
**Approved**: pending

**Decision**: `term` and `detail` accept `ReactNode` rather than being restricted to strings.
**Rationale**: Gives the caller full flexibility to compose rich content (formatted numbers, icons, inline components) without the component prescribing a structure.
**Approved**: pending

**Decision**: The component defines no styling of its own; all visual properties (padding, font, color, layout) are delegated to CSS rules applied via the `lp-stats` class.
**Rationale**: Keeps the component focused on semantic structure; presentation is the responsibility of `packages/web/packages/landing/src/css/blocks.css` and the calling context.
**Approved**: pending

**Decision**: The three-column layout is declared explicitly (`grid-template-columns: repeat(3, minmax(0, 1fr))`) rather than derived with an `auto-fit`/`auto-fill` minmax floor.
**Rationale**: Stats lives in the narrow column of a `.lp-split` layout, where a floor wide enough to keep a long caption off four lines only fits two columns, stranding a third entry alone under an empty cell. An explicit three-column count avoids that. A `minmax` floor tuned to produce a specific column count is also arithmetic against an assumed font size that stops holding the moment the base font size changes. The 34rem collapse breakpoint is a media query, so it resolves against the browser's default font size (16px unless the user changed it), not the page's root font size. See `packages/web/packages/landing/src/css/blocks.css`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

- semantic-markup and no-hardcoded-strings passed: `Stats.tsx` renders `dl`/`dt`/`dd` directly with no string literals.
- dynamic-type-support partial: `blocks.css` sizes `dt`/`dd` in `rem` and `clamp()` units, but no native guidance has been verified.
- contrast-ratio partial: colors are custom properties with fallbacks (`#d8d8d8`, `#a0a0a0`), and the computed contrast depends on the host background, which the source cannot confirm.
- locale-aware-formatting partial: the component renders caller-supplied `ReactNode` values and applies no locale formatting of its own.
- rtl-layout-support partial: the column order follows `dir`, but `.lp-stats div` uses physical `border-left` and `padding-left`, so the divider does not flip.
- separation-of-concerns passed: the component is pure presentation mapping `entries` to markup.
- unit-test-coverage passed: the `Stats` suite in `blocks-argument.test.tsx` renders the component and asserts on the wrapped dt/dd pairs.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source (Stats.tsx) |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; cited the full `blocks.css` path in Appearance, Platform Notes, and Design Decisions and moved the column-count rationale into Design Decisions; described the layout as a wrapping three-column grid with narrow-width stacking instead of a horizontal strip; corrected the `dt`/`dd` role description and softened the screen-reader claim; clarified that the wrapper `div` carries no class of its own; added AppKit and grid-based native platform notes with accessibility-grouping guidance; replaced Compliance with a real accessibility/internationalization table; merged overlapping test vectors and added empty-array and null-content vectors; reformatted Design Decisions into Decision/Rationale/Approved entries; documented RTL grid mirroring and required locale-aware number formatting; added related cross-references |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Added the three-column-wrap requirement and Playwright layout vectors, stated the stylesheet's appearance values, downgraded rtl-layout-support to partial (physical border-left/padding-left), listed the fallback colors under Increase Contrast, fixed the rem/breakpoint explanation, and split the compliance prose into one line per check. |
