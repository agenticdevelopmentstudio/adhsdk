---
id: 79093eb5-83e8-46d8-9efe-3cc6ff88d8db
title: "Trust"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Unboxed list of reassurance claims shown before a feature list."
platforms:
  - typescript
  - web
tags:
  - trust
  - list
  - semantic-html
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Trust

## Overview

The Trust component renders a semantic unordered list of trust claims—things a visitor wants settled before reading product capabilities. It accepts an array of React nodes and renders each as a list item, deliberately unstyled to avoid elevating claims to the visual prominence of product features.

## Behavioral Requirements

- **list-structure**: Component MUST render the `items` array as a semantic unordered list: a `<ul>` container with each item wrapped in a distinct `<li>` element.
- **node-items**: Component MUST accept `items` as a `ReactNode[]` prop, supporting text, React elements, fragments, and null values; every entry maps to an `<li>` in order, including `null`/`undefined` entries, which render as an empty `<li>` rather than being skipped.
- **container-class**: Component MUST apply the className `lp-trust` to the rendered `<ul>` element.

## Appearance

- **Container**: Semantic `<ul>` element with className `lp-trust`; no inline styles. Visual treatment comes entirely from `packages/web/packages/landing/src/css/blocks.css`: a wrapping flex row (not a vertical stack), centered, small uppercase text (`0.72rem`, `0.14em` letter-spacing) in a dim ink color, with no border or box—lighter weight than `.lp-cards`.
- **Items**: `<li>` elements, each a flex row with a small 5px round accent-colored marker (`::before`) preceding the provided React node content; no other item-level styling.
- **Layout**: Items wrap left-to-right and center as a group (`flex-wrap: wrap; justify-content: center`), not stacked vertically; gap of `0.4rem` (row) by `1.5rem` (column) between items.

## States

Not applicable: The Trust component is a static container that does not respond to user input or exhibit interactive state changes.

## Accessibility

- **Role**: Semantic `<ul>` and `<li>` establish list structure; screen readers announce list length and each item's position.
- **Label requirements**: Individual items should provide meaningful content; if items contain interactive controls, they MUST include accessible labels or descriptions.
- **Keyboard navigation**: No interactive behavior in the container; keyboard access is inherited from item content.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| trust-001 | list-structure | `items={[<span>Claim A</span>, <span>Claim B</span>]}` | Renders `<ul class="lp-trust"><li><span>Claim A</span></li><li><span>Claim B</span></li></ul>` |
| trust-002 | list-structure | `items={[<span>Claim A</span>]}` | Rendered output contains exactly one `<ul>` element as the root, with no additional wrapping elements |
| trust-003 | container-class | `items={[<span>Claim A</span>]}` | Rendered `<ul>` has `class="lp-trust"` |
| trust-004 | node-items | `items={["Text", <Badge />, <span>Mixed</span>, null]}` | Renders one `<li>` for every entry, in order, including the `null` entry, which renders as an empty `<li>` |
| trust-005 | list-structure | `items={[]}` | Renders an empty `<ul class="lp-trust"></ul>` |

## Edge Cases

- **Empty array**: Component renders an empty `<ul>` with no error or fallback message.
- **Single item**: Component renders a `<ul>` containing one `<li>` child.
- **Null or undefined items**: The component does not filter these values—`items.map` renders one `<li>` per array entry regardless of content, so a `null` or `undefined` entry produces an empty `<li>` rather than being skipped.
- **Deeply nested React elements**: Component renders the full tree of each item without flattening or transforming structure.
- **Dynamic items**: Component re-renders when items array or item content changes; items are rendered in array order, not reordered by component logic. Items are keyed by array index (see **Design Decisions**), so reordering the array does not preserve an item's identity across renders.

## Configuration

Not applicable: The Trust component accepts only the `items` prop and provides no configuration options.

## Deep Linking

Not applicable: The Trust component is a presentational container with no navigation or routing behavior.

## Localization

Not applicable: The Trust component does not define, render, or own any translatable strings. Item content is the responsibility of consuming code.

## Accessibility Options

- **Reduce Motion**: Not applicable; component does not animate.
- **Increase Contrast**: Not applicable; component does not define foreground or background colors.
- **Differentiate Without Color**: Not applicable; component relies on semantic structure, not color-based distinctions.

## Feature Flags

Not applicable: The Trust component has no feature flag requirements or runtime configuration switches.

## Analytics

Not applicable: The Trust component does not emit user interaction events or track engagement.

## Privacy

Not applicable: The Trust component does not collect, store, or transmit personal data.

## Logging

Not applicable: The Trust component does not emit diagnostic or debug log messages.

## Platform Notes

- **TypeScript/Web**: Render as `<ul className="lp-trust">` wrapping `<li>` children. See `packages/web/packages/landing/src/blocks/Trust.tsx`. Items are passed as `ReactNode[]` and rendered in order via `map()`, including `null`/`undefined` entries, which render as empty `<li>` elements.
- **SwiftUI**: Compose using a `VStack` (or `HStack`, matching the flex-row layout) with list semantics applied through accessibility traits (e.g. `.accessibilityElement(children: .contain)`)—not `List`, which is a scrolling, selectable collection control that would give the strip more visual weight and interaction affordance than the source's deliberately unstyled, non-elevated intent. Map each item to a `Text` or custom view; styling is delegated to the consuming view's modifiers.
- **Compose**: Use a wrapping `Row`/`FlowRow` or plain `Column`—not `LazyColumn` with `verticalScroll`, which turns a short static strip into a scrolling list. Apply list semantics with `Modifier.semantics` (e.g. collection item info) rather than a scrolling container. Map each item to a composable within the layout; styling is the responsibility of item-level composables.
- **AppKit / UIKit**: Use a horizontal `NSStackView` (macOS) or `UIStackView` (iOS)—not `NSTableView`/`UITableView`, which are scrolling, selectable collection controls that would elevate the strip beyond its unstyled, non-feature intent. Provide list semantics via accessibility (list-like traits on the container, with each item announcing its position). No cell-level styling is applied by the component.
- **WinUI 3**: Use an `ItemsRepeater` without a `ScrollViewer`, or a `StackPanel`, bound to the items collection—not a scrolling `ListView`/`ScrollViewer`, which would add selection and scroll affordances the flat strip does not have. Define a `DataTemplate` per item and expose list semantics via `AutomationProperties`. Apply no item-level styling; styling is delegated to the template and the app's resource dictionary.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Trust.tsx` | unverified |

## Design Decisions

**Decision**: The component is deliberately unstyled beyond `.lp-trust`/`.lp-trust li` (a wrapping flex row with small dot markers), and is not built from `Cards`.
**Rationale**: These are trust claims a visitor wants settled, not product features; boxing them like `Cards` would give them the same visual weight as the product's actual capabilities, which the source comment explicitly rejects.
**Approved**: pending

**Decision**: Items are keyed by array index (`key={i}`) rather than a caller-supplied stable key.
**Rationale**: The component has no identity to key on for arbitrary `ReactNode` entries; index keys are adequate for the typical static list, but they mean an item's identity (and any item-local state) is not preserved if the `items` array is reordered between renders.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Both statuses rest on `Trust.tsx`: the component renders `<ul>`/`<li>` elements exclusively and nothing else (semantic-markup), but because item content is arbitrary consumer-supplied `ReactNode`s, the source cannot guarantee accessible labels on any interactive children it wraps (screen-reader-support). `separation-of-concerns` passes because the component is pure presentation over its `items` prop with no business logic, and `unit-test-coverage` passes on `blocks-close.test.tsx`'s assertion that each item renders as its own list item.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | (recipe-author) | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename must-prefixed requirements to subject-only names and merge the duplicate list-structure requirement; correct the null/undefined-item edge case, requirement, and test vector to match the unfiltered `map()` in the source; fix trust-003's attribute assertion and give trust-002 concrete input; correct Appearance/Layout from a vertical stack to the source's wrapping flex row and cite the stylesheet; rewrite non-web Platform Notes from scrolling/selectable controls to non-scrolling stacks with accessibility-driven list semantics; reformat Design Decisions into Decision/Rationale/Approved entries and add one for the index-key choice; add a Compliance table; correct the screen-reader accessibility wording; rephrase the summary; and drop frontmatter date quoting to match the template. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
