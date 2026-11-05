---
id: 91db9191-1ab2-4d09-a9a8-b0dc23669066
title: Points
domain: adhsdk://recipes/points
type: ingredient
version: 1.1.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Marked list of long-form claims with optional bold lead-in text per item,
  supporting ordered and unordered presentation.
platforms:
- typescript
- web
tags:
- list
- marked-list
- claims
- landing-page
depends-on: []
related:
- adhsdk://recipes/trust
- adhsdk://recipes/cards
references: []
approved-by: ''
approved-date: ''
---

# Points

## Overview

Points is a marked list component designed for presenting a sequence of related claims or arguments, each substantial enough to be a sentence or longer. Unlike short-form lists (Trust) or parallel boxed items (Cards), Points emphasizes the logical flow of a multi-part argument by keeping items inline and marked with a consistent token. Each item has an optional bold lead-in term followed by the detail content; the lead-in provides visual scannability without truncating the full text. The marker itself is configurable via token, and the list supports both unordered and ordered presentation.

## Behavioral Requirements

- **list-element**: Component MUST render `<ul>` when `ordered` is false (default) or omitted, and MUST render `<ol>` when `ordered` is true.
- **list-items**: Component MUST render one `<li>` element for each entry in the `entries` array.
- **content-span**: Each list item content MUST be wrapped in a single `<span>` element to enforce grid layout structure (two-column: marker and content).
- **term-bold**: When an entry has a `term` property, Component MUST render it as `<b>{term}</b>`.
- **detail-text**: Component MUST render the `detail` property of each entry as ReactNode content.
- **term-detail-spacing**: When both `term` and `detail` are present, Component MUST render a space character between them.
- **term-omission**: When an entry has no `term` property, Component MUST NOT render a `<b>` element or space separator.
- **base-class**: Component MUST apply the CSS class `lp-points` to the root list element.
- **ordered-class**: Component MUST apply the CSS class `lp-points--ordered` to the root element when `ordered` is true.
- **ordered-class-exclusion**: Component MUST NOT apply `lp-points--ordered` class when `ordered` is false.
- **empty-entries**: Component MUST accept an empty `entries` array and render an empty list element with no items.

## Appearance

- **Marker appearance**: Each `<li>`'s `::before` pseudo-element supplies the marker: `content: var(--lp-points-mark, "\2192")` for unordered lists, or `counter(lp-point) var(--lp-points-ordinal-suffix, ".")` for ordered lists. Both the glyph and the ordinal suffix are CSS custom-property tokens the host can override.
- **Item spacing**: The root `.lp-points` is a single-column CSS Grid with `gap: 0.75rem` between `<li>` rows, and sets `list-style: none` so the browser's default marker is suppressed in favor of the `::before` token.
- **Typography**: Text within the `<span>` inherits `.lp-points li`'s `font-size: 0.94rem`, `font-weight: 300`, and `line-height: 1.7`; no inline typography overrides.
- **Grid layout**: The two-column structure (marker column, content column) is CSS Grid on each `<li>` (`grid-template-columns: 1.4rem 1fr`, widened to `1.9rem 1fr` when ordered) — not on the root, which is a single-column grid used only for row spacing.
- **Bold text**: Term text rendered with `<b>` element; CSS raises it to `font-weight: 500` and a brighter `--lp-ink` color token for visual weight.

## States

| State | Appearance change |
|-------|------------------|
| Default | List items display normally |
| Empty | Renders empty `<ul>` or `<ol>` element (no items rendered) |
| Ordered | Uses `<ol>` instead of `<ul>`; numbers auto-generated from CSS counter |
| Unordered | Uses `<ul>`; marker glyph from CSS token |

## Accessibility

- **Role**: List item containers are semantic `<ul>` or `<ol>` and `<li>` elements, providing correct list semantics to assistive technologies.
- **List role preservation**: The root sets `list-style: none` (see #appearance) without an explicit `role="list"`. Some older WebKit/VoiceOver combinations dropped the implicit list/listitem roles when `list-style: none` was present; current Safari and other major browsers preserve the implicit roles regardless. A consumer targeting older WebKit SHOULD add `role="list"` to the root and `role="listitem"` to each `<li>` at integration time.
- **Ordered list semantics**: When `ordered=true`, the `<ol>` element signals to screen readers that the sequence is ordered. Position announcements (e.g. "item 3 of 7") are common but not universal across screen reader/browser combinations for either `<ol>` or `<ul>`, so content MUST NOT depend on a position announcement for meaning.
- **Unordered list semantics**: When `ordered=false`, the `<ul>` element signals that items are not sequenced.
- **Label requirements**: The component itself has no explicit label; list context is provided by surrounding content or page structure. Each item's `detail` content SHOULD be meaningful and complete on its own, since the component neither truncates nor supplements it.
- **Text content**: Term and detail text are read in sequence; whether bold formatting on the term is announced as emphasis depends on the screen reader and is not guaranteed.
- **No interactive elements**: Points is a static list and does not require focus management, keyboard navigation, or state announcement beyond list semantics.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| points-001 | list-element, base-class, empty-entries | `{entries: [], ordered: false}` | Renders `<ul class="lp-points"></ul>` |
| points-002 | list-element, ordered-class | `{entries: [], ordered: true}` | Renders `<ol class="lp-points lp-points--ordered"></ol>` |
| points-003 | list-items, content-span | `{entries: [{detail: "Content"}]}` | Renders `<li><span>Content</span></li>` |
| points-004 | term-bold, term-detail-spacing | `{entries: [{term: "Term", detail: "Description"}]}` | Renders `<li><span><b>Term</b> Description</span></li>` |
| points-005 | list-element | `{entries: [{detail: "First"}]}` (`ordered` prop omitted) | Renders `<ul class="lp-points">…` — omitting `ordered` defaults to unordered |
| points-006 | term-bold, term-omission, term-detail-spacing | `{entries: [{term: "A", detail: "First"}, {detail: "Second"}]}` | First item: `<li><span><b>A</b> First</span></li>`. Second item: `<li><span>Second</span></li>` with no `<b>` |
| points-007 | ordered-class | `{entries: [{detail: "First"}, {detail: "Second"}], ordered: true}` | Root element has class `lp-points--ordered` |
| points-008 | ordered-class-exclusion | `{entries: [{detail: "Item"}], ordered: false}` | Root element does not have class `lp-points--ordered` |
| points-009 | term-bold, detail-text | `{entries: [{term: <em>Note</em>, detail: <a href="#more">link</a>}]}` | Renders `<li><span><b><em>Note</em></b> <a href="#more">link</a></span></li>` — ReactNode `term`/`detail` render as-is |

## Edge Cases

- **Empty entries array**: Component renders an empty list container. Expected behavior: list is rendered but contains no items.
- **Null or undefined term property**: When term is undefined, no term text or spacing is rendered. Expected behavior: detail text appears without preceding bold text.
- **ReactNode as term or detail**: Both `term` and `detail` accept ReactNode (can be strings, elements, fragments). Expected behavior: ReactNode is rendered as-is within the wrapper structure.
- **Very long term or detail text**: No truncation occurs in the component; wrapping and overflow are delegated to CSS. Expected behavior: text flows according to CSS rules.
- **Empty detail text**: An entry with empty string or empty ReactNode as detail renders an empty span. Expected behavior: `<li><span></span></li>` for that entry.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| entries | `PointEntry[]` | (required) | Array of list items, each with optional `term` and required `detail` |
| ordered | `boolean` | `false` | When true, renders `<ol>` and applies `lp-points--ordered` class |

## Deep Linking

Not applicable: Points is a presentational list component with no interactive navigation or state that maps to a URL.

## Localization

Not applicable: The component renders the `term` and `detail` content as-is. Localization of list text is the responsibility of the parent component or content source.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Points is a static list with no animations or transitions. |
| Increase Contrast | Delegated to CSS; the component does not set any color values. Parent styles SHOULD ensure sufficient contrast (see **compliance/contrast-ratio**). |
| Differentiate Without Color | Delegated to CSS; the component does not rely on color to distinguish content. The term is marked with bold weight (`<b>` element) and distinct in layout. |

## Feature Flags

Not applicable: Points is a core presentational component with no conditional behavior requiring feature flags.

## Analytics

Not applicable: Points is a static list component without user interaction. No events are generated by the component itself.

## Privacy

Not applicable: Points is a presentational component that does not collect, store, or transmit user data.

## Logging

Not applicable: Points is a presentational component with no state changes, errors, or lifecycle events to log.

## Platform Notes

- **React/Web**: Exported as a React functional component from `packages/web/packages/landing/src/blocks/Points.tsx`. Accepts `entries: PointEntry[]` and `ordered?: boolean`. `PointEntry` is an object type — not a union — with an optional `term` (`ReactNode`) and a required `detail` (`ReactNode`). The component renders `<ul>` or `<ol>` with class `lp-points` and conditionally `lp-points--ordered`. CSS Grid structure assumes two columns (marker, content) via class-based selectors on each `<li>`.
- **SwiftUI**: Use a plain `VStack` of rows rather than `List` — a static, non-scrolling claims list doesn't need `List`'s selection/swipe chrome, and SwiftUI has no `.listStyle(.numbered)` variant to lean on. Each row is a two-column `HStack`: a leading marker `Text` (a bullet glyph, or the 1-based index when ordered — computed from the item's position, not a built-in numbered style), then a single `Text`/`AttributedString` built inline with a bold run for the term immediately followed by a space and the detail, matching the web's inline rendering. Build the run without the bold segment when `term` is absent.
- **Compose**: Use a plain `Column` of rows rather than `LazyColumn` — the list is static and short enough not to need lazy layout. Each row is a `Row` with a marker `Text` (bullet `'•'`, or the 1-based index when ordered), then a single `Text` built from an `AnnotatedString` that applies `SpanStyle(fontWeight = FontWeight.Bold)` to the term span followed by a space and the detail, rendered inline as on the web. `fontWeight` is a parameter of `Text`/`SpanStyle`, not a `Modifier`.
- **AppKit / UIKit**: Use a plain `NSStackView` (macOS) or `UIStackView` (iOS) of rows rather than `NSTableView`/`UITableView` — a static list doesn't need cell reuse, and `UIListContentConfiguration` is for cell-based lists, not a fit here. Each row is a horizontal stack: a leading `NSTextField`/`UILabel` for the marker (bullet or 1-based index), then a single `NSTextField`/`UILabel` whose attributed string renders the term in bold immediately followed by a space and the detail, inline as on the web. Build the attributed string without the bold run when `term` is absent.
- **WinUI 3**: Use `ItemsControl` with a plain `StackPanel` (Vertical) as the `ItemsPanel` — `ItemsStackPanel` is designed for `ListViewBase`-derived controls (`ListView`, `GridView`), and `ListView` does not number items automatically, so neither is the right fit for a static templated list. Each item template is a `Grid` with two columns (auto, *): the first column is a `TextBlock` with the marker (bullet or the 1-based index, computed from the item's position in the bound collection), the second column is a single `TextBlock` with a bold `Run` for the term (`FontWeight="Bold"`) immediately followed by a space and a plain `Run` for the detail, inline as on the web. Bind the term `Run`'s presence to whether the entry has a term.

## Design Decisions

**Decision**: Each list item's content (the optional term plus the detail) is wrapped in a single `<span>` (see **content-span**).
**Rationale**: Each row is a two-column CSS Grid — marker in column one, content in column two. An unwrapped term would land in the grid as its own item and break the intended "marker → lead-in + body" structure instead of flowing inline with the detail.
**Approved**: pending

**Decision**: The `ordered` prop switches both the HTML element (`<ul>` vs. `<ol>`) and the CSS class (`lp-points--ordered`), rather than the class alone (see **ordered-class**).
**Rationale**: The sequence is part of the claim itself ("first this, then that"), and only `<ol>` communicates that to assistive technology — a `ul` announces a bullet where an `ol` announces ordered position. The digits come from a CSS counter rather than content, so a re-ordered source can never disagree with the numbers on screen.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `Points.tsx`'s render logic (native `<ul>`/`<ol>`/`<li>` elements with no hardcoded user-facing strings, all content passed via props) and `blocks.css`'s use of relative (`rem`) typography, host-supplied CSS custom-property color tokens whose actual contrast the source cannot confirm, and `list-style: none` applied without an explicit `role="list"`. separation-of-concerns passes because `Points.tsx` only maps props to markup while every visual decision lives in `blocks.css`. unit-test-coverage passes because the `Points` suite in `blocks-frame.test.tsx` renders term-plus-detail entries, detail-only entries, the ordered variant, and the default unordered list.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | Code-review conformance fixes: compliance citations, Change History and template sections. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Compliance links moved to the agenticdevelopercookbook scheme; separation-of-concerns and unit-test-coverage added |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename `must-*` requirements to subject-only names everywhere they're cited; correct Platform Notes APIs (drop nonexistent SwiftUI/WinUI/Compose calls, recommend lightweight stacks, rename Typescript/Web to React/Web, fix PointEntry's type description) and make native term/detail rendering inline to match the web; correct Appearance and Accessibility to match the actual CSS grid structure and screen-reader behavior; reformat Design Decisions into Decision/Rationale/Approved entries; replace redundant test vectors and add compliance links; reword consumer-facing MUSTs as SHOULD guidance; add tags and related recipes. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
