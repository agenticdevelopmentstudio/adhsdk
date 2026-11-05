---
id: 5182f5ec-186b-4605-8c40-ea70a49262c2
title: Checklist
domain: adhsdk://recipes/checklist
type: ingredient
version: 1.1.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Columnar list of checked items, grouped under quiet headings, designed
  for dense scanning.
platforms:
- typescript
- web
tags:
- list
- informational
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Checklist

## Overview

Checklist renders one or more columns of items, each grouped under a heading. The component is designed for dense, scannable layouts where a user needs to see what features, features-to-come, or status items are present. Every item renders with the same "checked" mark by default — there is no `checked` field; the only per-item variation is the optional `soon` state. Empty item groups render no list element at all (to avoid invisible layout artifacts).

## Behavioral Requirements

- **group-structure**: Component MUST accept an array of `ChecklistGroup` objects, each containing a `heading` (ReactNode) and `items` array of `ChecklistItem` objects.
- **heading-element**: Component MUST render the heading for each group as an `<h3>` element.
- **item-structure**: Component MUST render each item in a group as an `<li>` element, wrapping the item's `text` (ReactNode) in a `<span>`.
- **empty-group-omits-list**: Component MUST NOT render a `<ul>` element for groups with zero items; the group div and heading still render.
- **soon-class**: Component MUST support an optional `soon` boolean property on items; when `soon` is true, the item's `<li>` element MUST receive the `lp-checklist__item--soon` CSS class.
- **root-class**: Component MUST apply the `lp-checklist` CSS class to the root container div.
- **stable-group-order**: Callers MUST NOT reorder, insert into, or remove from the `groups` or `items` arrays between renders. The component keys both by array index (see **Map index as key** in Design Decisions), so element identity across such changes is not guaranteed.

## Appearance

- **Container**: `<div class="lp-checklist">` with no inline styles; styling is via CSS class.
- **Layout**: `.lp-checklist` is a CSS grid: 1 column below a 34rem viewport width, 2 columns at ≥34rem, 3 columns at ≥58rem (`packages/web/packages/landing/src/css/blocks.css`). The column count is a fixed value chosen for the current six-group content (three per row across two full rows), not derived from the number of groups; the source notes revisiting the number if a seventh group is added.
- **Group container**: `<div>` wrapping each group heading and list, with no class or inline styles.
- **Heading**: `<h3>` with no class or inline styles.
- **List**: `<ul>` with no class or inline styles, rendered only when items array is non-empty.
- **List item**: `<li>` with optional `lp-checklist__item--soon` class (applied when `item.soon` is truthy).
- **Item text**: `<span>` containing the item's `text` ReactNode, with no class or inline styles.

## States

Not applicable: Checklist is a presentational component that renders items in a static state. State transitions are managed by the parent component updating the `groups` prop.

## Accessibility

- Role: The component uses semantic HTML (`<h3>`, `<ul>`, `<li>`, `<span>`) to convey structure; no additional ARIA roles are applied.
- Heading hierarchy: Group headings are always rendered as `<h3>` — a fixed level-3 heading, not configurable by the caller. The containing page MUST place each Checklist instance where a level-3 heading is correct for the surrounding document outline.
- List semantics: Items are wrapped in `<ul>` and `<li>` elements to signal a list to assistive technologies.
- Labels: Item text is directly embedded in the item; there is no explicit labeling mechanism beyond the text itself.
- Differentiate without color: The **soon-class** state is marked by a distinct glyph (`○` vs `✓`, via the `--lp-checklist-mark-soon` / `--lp-checklist-mark` tokens) as well as a dimmer color, so the distinction does not rely on color alone (`packages/web/packages/landing/src/css/blocks.css`).
- **Text equivalent for soon**: The component does not provide a text equivalent for assistive technology beyond the visual glyph change — no ARIA attribute, visually hidden text, or other screen-reader-specific markup accompanies the `soon` state, so a screen reader announces the item's text with no distinction from a non-`soon` item (`Checklist.tsx`).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| checklist-001 | group-structure | groups array with one group `{ heading: "Group 1", items: [{ text: "Feature A" }] }` | Renders `div.lp-checklist` containing an `h3` with text "Group 1" and one `li` containing a `span` with text "Feature A" |
| checklist-002 | heading-element | groups array with heading "Group 1" | `h3` element contains heading text "Group 1" |
| checklist-003 | item-structure | group with items array `[{ text: "Item A" }, { text: "Item B" }]` | `ul` renders two `li` elements, each containing a `span` with the respective text |
| checklist-004 | empty-group-omits-list | group with empty items array `[]` | `h3` heading renders, but no `ul` element is rendered for that group |
| checklist-005 | soon-class | item with `{ text: "Coming soon", soon: true }` | `li` element receives class `lp-checklist__item--soon` |
| checklist-006 | soon-class | item with `{ text: "Available", soon: false }` or `soon` undefined | `li` element does not receive the `lp-checklist__item--soon` class |
| checklist-007 | root-class | any valid groups array | root `div` element has class `lp-checklist` |
| checklist-008 | group-structure | groups array `[{ heading: "First", items: [{ text: "A" }] }, { heading: "Second", items: [{ text: "B" }] }]` | Component renders a separate `div` for each group, in the same order as the input array: "First" precedes "Second" |
| checklist-009 | stable-group-order | render with `groups = [{ heading: "A", items: [{ text: "1" }] }, { heading: "B", items: [{ text: "2" }] }]`, then re-render with the same groups reordered to `[B, A]` | Rendered content matches the new order ("B" then "A"); the component provides no guarantee that element identity for a given group or item follows it across the reorder, since keys are by array index |

## Edge Cases

- **Empty groups array**: If the groups prop is an empty array, the component renders an empty div with class `lp-checklist`. No error occurs.
- **Null or undefined items array**: Not applicable: TypeScript interface requires `items: ChecklistItem[]` (non-nullable); items array is always present and is always an array.
- **Empty text**: An item with an empty string or empty ReactNode for `text` renders the list item and span; the span contains the empty text. No special handling or hiding occurs.
- **soon property edge cases**: `soon` is typed as an optional `boolean`, so it is either `true`, `false`, or absent; absent or `false` means not soon.
- **ReactNode content in heading and text**: Both `heading` and `text` accept ReactNode, permitting complex nested content (elements, fragments, conditionals). The component renders them as-is without validation or sanitization.

## Configuration

Not applicable: Checklist is a presentational component with no configuration options. The component's appearance and behavior are entirely controlled via the `groups` prop structure and the parent's CSS.

## Deep Linking

Not applicable: Checklist is a presentational component with no URL routes, navigation, or deep-linking behavior.

## Localization

Not applicable: Checklist does not render any static text or labels. All user-facing strings are provided via the `groups` prop by the parent component; localization is the parent's responsibility.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component has no animation. |
| Increase Contrast | Not handled by the component; contrast comes from the host's `--lp-accent` / `--lp-ink-dim` tokens (see Compliance). |
| Differentiate Without Color | Satisfied: the `soon` state is marked by a distinct glyph (`○` vs `✓` via `--lp-checklist-mark-soon`), not by color or opacity alone (`packages/web/packages/landing/src/css/blocks.css`). |

## Feature Flags

Not applicable: Checklist is a presentational component with no feature flags or conditional behavior.

## Analytics

Not applicable: Checklist does not emit any events or analytics. Parent components are responsible for tracking user interactions with checklist content.

## Privacy

Not applicable: Checklist does not collect, store, transmit, or retain any data. It is a presentational component that renders data provided by the parent.

## Logging

Not applicable: Checklist does not perform any logging. Subsystem-level logging is the responsibility of parent components.

## Platform Notes

- **TypeScript/React (Web)**: Render using React's JSX syntax with the `Checklist` functional component from `packages/web/packages/landing/src/blocks/Checklist.tsx`. The component accepts a `groups` prop of type `ChecklistGroup[]`. Styling via CSS class selectors `.lp-checklist` and `.lp-checklist__item--soon`; see `css/blocks.css` for the column-count breakpoints noted under Appearance.
- **SwiftUI**: Use a `VStack` containing multiple sections, each with a header `Text` rendering the group heading and a `VStack` of `Text` or `Label` elements for items. Mark the "soon" state with a distinct symbol (e.g., a different SF Symbol or glyph), not opacity or foreground color alone, to stay distinguishable without color — matching the source's `✓` vs `○` marks. Do not render the list container if items are empty.
- **Compose**: Use a `Column` containing multiple sections, each with a `Text` composable for the group heading and a plain `Column` of `Row` elements for items — not a `LazyColumn` nested inside the outer `Column`, which causes nested-scroll and height-measurement problems for what is a static, non-scrolling list. Mark the "soon" state with a distinct icon or glyph, not opacity or color alone, when the item's `soon` property is true. Do not render the list if items are empty.
- **AppKit / UIKit**: On AppKit (macOS), use `NSStackView` or `NSGridView` with an `NSTextField` for each group heading and `NSTableView` or `NSStackView` for items, conditionally hiding the list view if items are empty. On UIKit (iOS), use `UIStackView` with `UILabel` for headings and `UITableView` or `UIStackView` for items, similarly hiding the list if empty. Mark the "soon" state with a distinct glyph or icon, not italics, reduced opacity, or color alone, matching the source's structural distinction.
- **WinUI 3**: Use a `Grid` or `StackPanel` for each group, with a `TextBlock` for the group heading and a `ListView` or `ItemsControl` for items. Set the `ItemsControl` visibility to `Collapsed` if the items collection is empty. Mark the "soon" state with a distinct glyph or icon bound via a converter or template selector, not opacity or `Foreground` brush alone. Style the root `Grid` or `StackPanel` via a named `Style` resource (or wrap it in a themeable `UserControl`) rather than an `x:Name`, which is an element handle, not a styling hook, so it cannot substitute for `.lp-checklist`'s CSS-class styling.

## Design Decisions

- **Decision**: The `<ul>` element for a group is rendered only when `items.length > 0`.
  **Rationale**: An empty `<ul>` is invisible on screen but still carries the list's CSS spacing, so it would read as a layout bug rather than absent content.
  **Approved**: pending

- **Decision**: The "coming soon" state is carried by the boolean `soon` field on `ChecklistItem`, not by a phrase embedded in `text`.
  **Rationale**: A structural field lets the component apply one consistent visual treatment via a CSS class without duplicating the concept as text in multiple places. Per the source comment: "The distinction has to be structural, which is why it is a field here and not a phrase in `text`."
  **Approved**: pending

- **Decision**: `heading` and `text` accept `ReactNode`, not just strings.
  **Rationale**: This allows rich content (nested elements, conditionals, fragments) without changing the component; the parent is responsible for the accessibility of any complex content it supplies.
  **Approved**: pending

- **Decision**: The array index is used as the React key for both groups (`key={i}`) and items (`key={j}`).
  **Rationale**: This is appropriate for stable lists that are not reordered, filtered, or have items inserted; see **stable-group-order** for the resulting constraint on callers.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`dynamic-type-support` and `semantic-markup` pass because the component sizes text in `rem` units and renders through native `h3` / `ul` / `li` / `span` elements (`Checklist.tsx`, `css/blocks.css`); `contrast-ratio` is `partial` because the actual computed contrast depends on the host's `--lp-ink-dim` / `--lp-accent` token values, which the source does not fix. separation-of-concerns passes because `Checklist.tsx` is pure presentation over its `groups` prop with no logic beyond a length check, and unit-test-coverage passes because `blocks-argument.test.tsx`'s `Checklist` suite exercises grouping, the `soon` modifier, and the empty-group case with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and added stable-group-order; reformatted Design Decisions to Decision/Rationale/Approved; populated Compliance and Accessibility Options tables; documented the grid column layout; corrected checklist-001/checklist-008 test vectors and added checklist-009; fixed Compose and WinUI platform notes; clarified heading-level wording and simplified the soon edge case and summary |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
