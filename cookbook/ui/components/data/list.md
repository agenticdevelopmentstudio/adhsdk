---
id: 3785363d-118e-4d7e-98e6-afaca8bf0838
title: "List"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A bordered container component with row dividers for displaying flat collections of items."
platforms:
  - typescript
  - web
tags:
  - ui
  - list
  - collection
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# List

## Overview

List is a semantic container component for displaying flat collections of items (e.g., team members, search results). It provides consistent visual treatment with borders and row dividers. The component comprises two parts: `List` (the container) and `ListItem` (individual rows). Both are simple presentational wrappers that forward all React props to their underlying HTML elements.

## Behavioral Requirements

- **semantic-list**: The List component MUST render a `<ul>` element.
- **semantic-item**: The ListItem component MUST render an `<li>` element.
- **classname-merge**: Both List and ListItem MUST accept a `className` prop and merge it with their base styles using the `cn()` utility (`twMerge(clsx(...))`); when the caller's `className` conflicts with a base Tailwind class, the caller's class MUST win.
- **prop-forwarding**: Both List and ListItem MUST forward all remaining React props (`...props`) to their underlying HTML element. This includes props such as `role`, which can override the element's implicit semantics — restoring or removing that semantics is the caller's responsibility.
- **data-slot**: The List component MUST set `data-slot="list"` on the rendered `<ul>`. The ListItem component MUST set `data-slot="list-item"` on the rendered `<li>`.

## Appearance

### List Container

- **Border**: 1px solid border on all sides, using `border-apt-border` color token
- **Border Radius**: Rounded corners via `rounded-lg`
- **Layout**: Flex column layout with `flex flex-col`
- **Row Dividers**: Horizontal dividers between rows via `divide-y` with `divide-apt-border` color
- **Overflow**: Content overflow hidden via `overflow-hidden`
- **Background**: Inherits from parent (not explicitly set)

### ListItem

- **Minimum Height**: 36px (Tailwind `min-h-9`)
- **Layout**: Flex row layout (`flex items-center`)
- **Horizontal Padding**: 12px on left and right (`px-3`)
- **Vertical Padding**: 6px on top and bottom (`py-1.5`)
- **Item Gap**: 12px spacing between flex children (`gap-3`)

## States

Not applicable: List and ListItem are static presentational components with no interactive states. State management is the responsibility of parent components.

## Accessibility

List and ListItem render semantic HTML (`<ul>` and `<li>`) without additional ARIA attributes or accessible labels; list semantics, item announcements, and screen reader handling are inherited from these elements. Because both components forward all remaining props (see **prop-forwarding**), a caller can pass a `role` that overrides this implicit semantics; restoring or removing list semantics in that case is the caller's responsibility, not the component's. Safari/VoiceOver also drops the implicit `list` role from a `<ul>` styled with `display:flex` and no `list-style` — which is how `List`'s base classes (`flex flex-col`) render — so consumers targeting VoiceOver on Safari SHOULD set `role="list"` explicitly to restore the announced list semantics. Parent components remain responsible for adding labels or descriptions for the content displayed within the list items.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| list-001 | semantic-list, data-slot | Render `<List />` | Output contains `<ul data-slot="list">` |
| list-002 | semantic-item, data-slot | Render `<ListItem />` | Output contains `<li data-slot="list-item">` |
| list-003 | classname-merge | Render `<List className="custom-class" />` | Output element has both base classes and `custom-class` applied |
| list-004 | classname-merge | Render `<ListItem className="custom-item" />` | Output element has both base classes and `custom-item` applied |
| list-005 | prop-forwarding | Render `<List id="test-list" role="region" />` | Output `<ul>` contains `id="test-list"` and `role="region"` attributes |
| list-006 | prop-forwarding | Render `<ListItem id="item-1" data-test="value" />` | Output `<li>` contains `id="item-1"` and `data-test="value"` attributes |
| list-007 | classname-merge | Render `<ListItem className="px-6" />` | Output `<li>` class list contains `px-6` and does not contain the conflicting base class `px-3` |

## Edge Cases

- **Empty list**: Rendering `<List />` with no children produces an empty bordered container.
- **Single item**: Rendering a List with one ListItem produces the container with no visible row dividers (dividers appear between rows, not above or below).
- **Nested flex content**: ListItem uses flex layout; when child content includes flex or grid elements, they inherit the flex context.
- **className collision**: If a `className` prop contains a Tailwind class that conflicts with a base class (e.g., `px-6` conflicting with the base `px-3`), `cn()` resolves it with `tailwind-merge`: the caller's class wins and the conflicting base class is dropped, rather than emitting both classes for the CSS cascade to resolve. See **classname-merge** and test vector list-007.

## Configuration

Not applicable: List and ListItem have no configuration options. All appearance and behavior is determined by Tailwind classes and React props.

## Deep Linking

Not applicable: List and ListItem are UI components, not views or pages. Deep linking is not applicable.

## Localization

Not applicable: List and ListItem render no text content and require no localization.

## Accessibility Options

Not applicable: List and ListItem do not implement accessibility display options (such as Reduce Motion, Increase Contrast, or Differentiate Without Color). These concerns are the responsibility of the consuming component.

## Feature Flags

Not applicable: List and ListItem have no feature flags.

## Analytics

Not applicable: List and ListItem do not emit analytics events.

## Privacy

Not applicable: List and ListItem do not collect, store, or transmit any data.

## Logging

Not applicable: List and ListItem do not emit any logs.

## Platform Notes

- **SwiftUI**: SwiftUI has no `.divider()` modifier, and `List` does not render an outer border by default. Compose the container as `VStack(spacing: 0) { ForEach(...) { item in ...; Divider() } }` for row dividers, and add `.overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.aptBorder))` to reproduce the bordered, rounded-corner container.
- **Compose**: Android Compose's `LazyColumn` with `Divider()` composables between items provides equivalent row divider behavior. Combine with `Card` or custom styling to add the border treatment.
- **React/Web**: The source implementation is in `packages/web/packages/ui/src/components/list.tsx`. The List component renders a styled `<ul>` with Tailwind classes (`flex flex-col divide-y divide-apt-border overflow-hidden rounded-lg border border-apt-border`). The ListItem component renders a styled `<li>` with Tailwind classes (`flex min-h-9 items-center gap-3 px-3 py-1.5`). Both use the `cn()` utility from `lib/utils` to merge classnames.
- **AppKit / UIKit**: `separatorStyle = .singleLine` on `NSTableView`/`UITableView` gives row separators but not this component's outer border or rounded corners. A plain stack view (`NSStackView`/`UIStackView`) with a hairline divider view between rows, wrapped in a container view with a 1pt border and rounded corners, reproduces the source's appearance without the selection and reuse chrome a table view brings.
- **WinUI 3**: `SingleSelectionMode` is not a real WinUI API, and `ListView` adds selection behavior this static component doesn't have. Use `ItemsRepeater` with a separator element between rows, hosted inside a `Border` with `CornerRadius` and `BorderThickness` to reproduce the outer border and rounded corners. Use a `Grid`/`StackPanel` for cell layout with column spacing equivalent to `gap-3`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/list.tsx` | unverified |

## Design Decisions

**Decision**: List and ListItem manage no internal state and enforce no content structure.
**Rationale**: Simplicity and reusability; state management is left to parent components.
**Approved**: pending

**Decision**: Both components forward all remaining props to their underlying HTML element.
**Rationale**: Allows flexible composition and styling without a bespoke prop API.
**Approved**: pending

**Decision**: Use `data-slot` attributes (`data-slot="list"`, `data-slot="list-item"`) instead of a class-based API.
**Rationale**: Enables targeted CSS and testing selectors without requiring a class-based API.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Status rests on `list.tsx`: it renders plain `<ul>`/`<li>` elements with correct implicit roles, but it forwards an overridable `role` prop (**prop-forwarding**) and does not add `role="list"` to guard against Safari/VoiceOver dropping list semantics on a flexed `<ul>` (see Accessibility). `separation-of-concerns` passes because `List`/`ListItem` are pure presentation over their props with no logic beyond prop forwarding; `unit-test-coverage` fails because no test file imports `components/list`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated all citations; corrected the className-collision edge case and added a tailwind-merge test vector (list-007); reformatted Design Decisions into Decision/Rationale/Approved entries; corrected the SwiftUI, AppKit/UIKit, and WinUI 3 platform notes; marked Accessibility applicable with role-override and WebKit list-semantics guidance; corrected the Compliance entry to semantic-markup/partial |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
