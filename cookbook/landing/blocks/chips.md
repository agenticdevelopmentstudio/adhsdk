---
id: 12cc7564-cb08-4b62-9785-c3b1cc0c46f0
title: "Chips"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A row of inline label chips that displays provider availability or planned features with optional visual variants."
platforms:
  - typescript
  - web
tags:
  - chips
  - list
  - badge
  - landing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Chips

## Overview

A horizontal list component that renders a row of labeled chips. Each chip displays a `label` and MAY be marked active. The list itself supports two visual treatments: a standard appearance, and a dimmed, dashed "upcoming" variant for a list whose items are not yet available.

## Behavioral Requirements

- **list-rendering**: Component MUST render the entries within a single semantic list.
- **list-item-rendering**: Component MUST render each entry as one item within that list.
- **item-label-content**: Component MUST render the entry's `label` as the content of its list item.
- **active-item-state**: Component MUST mark a list item as active when its entry's `open` property is `true`.
- **inactive-item-state**: Component MUST NOT mark a list item as active when `open` is not `true`.
- **upcoming-list-variant**: Component MUST present the list in its de-emphasized, "upcoming" variant when `soon` is `true`.
- **default-list-variant**: Component MUST NOT present the upcoming variant when `soon` is not `true`.
- **base-list-styling**: Component MUST apply the list's baseline styling identity regardless of which variant is active.

## Appearance

- **List container**: A semantic list that always carries its baseline styling identity (see **base-list-styling**), plus an additional "upcoming" modifier when `soon` is `true` (`lp-chips`, optionally with `lp-chips--soon`)
- **List items**: Each item optionally carries an "active" modifier when its entry's `open` is `true` (`lp-chip--open`); items that are not active carry no per-item modifier of their own
- **Active item meaning**: `open: true` marks that specific chip as the emphasized/current item within the row, visually distinguished from the row's other (default) chips. The exact emphasis (e.g. accent color or border) is defined by the consuming stylesheet (`css/blocks.css`) rather than by this component
- **Label content**: Rendered as-is from the `label` property; styling for both the standard and upcoming variants lives in `css/blocks.css`
- **Standard appearance**: Baseline treatment applied to every chip list
- **Upcoming variant**: Dashed, dimmed, accent-free treatment applied at the list level when the list represents items that are not yet available, independent of any individual item's active state

## States

| State | Appearance change |
|-------|------------------|
| Default | Renders with base list styling; active items carry the active-item modifier |
| Upcoming | Renders with base styling plus the upcoming-variant modifier; dashed, dimmed, accent-free treatment; item-level active modifiers still apply independently |

## Accessibility

Semantic HTML: component uses standard `<ul>` and `<li>` elements, which are recognized by assistive technologies as a list structure (see **base-list-styling**, **list-item-rendering**). The active-item and upcoming-variant states are expressed only through CSS classes (`lp-chip--open`, `lp-chips--soon`); the component adds no corresponding ARIA attribute (e.g. `aria-current`) or text alternative for either state, so an assistive-technology user perceives only the plain list unless the caller's own styling conveys the distinction some other way. Labels are rendered as passed; if labels require accessible text alternatives or ARIA attributes, that is the responsibility of the caller to provide through the `label` prop (which accepts ReactNode).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| chips-001 | list-rendering, base-list-styling | `{ entries: [{ label: "Chip A" }], soon: false }` | `<ul class="lp-chips">` contains rendered entries |
| chips-002 | list-item-rendering, item-label-content | `{ entries: [{ label: "Chip A" }, { label: "Chip B" }] }` | Two `<li>` elements rendered; first contains "Chip A", second contains "Chip B" |
| chips-003 | active-item-state | `{ entries: [{ label: "Active", open: true }] }` | `<li class="lp-chip--open">` contains "Active" |
| chips-004 | inactive-item-state | `{ entries: [{ label: "Default" }] }` | `<li>` (no `lp-chip--open` class) contains "Default" |
| chips-005 | upcoming-list-variant | `{ entries: [{ label: "Coming Soon" }], soon: true }` | `<ul class="lp-chips lp-chips--soon">` rendered |
| chips-006 | default-list-variant | `{ entries: [{ label: "Available" }], soon: false }` | `<ul class="lp-chips">` (no `lp-chips--soon` class) |
| chips-007 | default-list-variant | `{ entries: [{ label: "Available" }] }` | `<ul class="lp-chips">` (no `lp-chips--soon` class) |
| chips-008 | list-rendering | `{ entries: [] }` | `<ul class="lp-chips"></ul>` (empty list) |
| chips-009 | active-item-state, inactive-item-state | `{ entries: [{ label: "First", open: true }, { label: "Second" }] }` | First `<li class="lp-chip--open">` contains "First"; second `<li>` (no `lp-chip--open`) contains "Second" |
| chips-010 | item-label-content | `{ entries: [{ label: <strong>Bold</strong> }] }` | `<li>` renders the `<strong>Bold</strong>` element as-is, not stringified |
| chips-011 | active-item-state, upcoming-list-variant | `{ entries: [{ label: "Both", open: true }], soon: true }` | `<ul class="lp-chips lp-chips--soon">` contains `<li class="lp-chip--open">Both</li>`; the item's active state and the list's upcoming variant apply independently |

## Edge Cases

- **Empty entries array**: Component renders an empty `<ul class="lp-chips"></ul>` with no list items (see **list-rendering**).
- **Undefined `soon` property**: Treated as not `true`; the upcoming variant is not applied (see **default-list-variant**). Component renders with its baseline styling only.
- **Undefined `open` property on entry**: Treated as not `true`; no active-item modifier is applied to that list item (see **inactive-item-state**).
- **Mixed active states**: Some entries have `open: true`, others do not. Each entry's active-item modifier is applied independently of the others (see **active-item-state**, **inactive-item-state**; chips-009).
- **ReactNode label**: The `label` prop accepts any ReactNode (string, number, element, fragment, etc.). Component renders it as-is without validation or transformation (chips-010).
- **Null, undefined, or boolean label**: React does not render `null`, `undefined`, `true`, or `false` children, so the list item renders with empty content in that case; the `<li>` element itself is still emitted. An empty string likewise renders as empty content. Numeric `0` renders as the text "0", since React does treat `0` as a renderable child.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `entries` | `ChipEntry[]` | (required) | Array of chip entries, each with a required `label` and optional `open` boolean |
| `soon` | `boolean` | `undefined` (falsy) | When `true`, switches the list to the upcoming/de-emphasized visual treatment |

## Deep Linking

Not applicable: component is a stateless display element with no navigation targets.

## Localization

Not applicable: component renders labels provided by the caller. Any string localization is the responsibility of the caller passing localized text via the `label` prop.

## Accessibility Options

Not applicable: component renders semantic HTML (`<ul>` / `<li>`) and does not respond to display accessibility options. Label content and meaning are determined by what the caller passes.

## Feature Flags

Not applicable: component has no feature-flag-gated behavior.

## Analytics

Not applicable: component is a stateless display element with no user interactions or state changes to track.

## Privacy

Not applicable: component does not collect, store, or transmit any data. It renders labels provided by the caller.

## Logging

Not applicable: component has no logging.

## Platform Notes

- **React/Web**: Defined in `packages/web/packages/landing/src/blocks/Chips.tsx`. Styling applied via the CSS classes `lp-chips`, `lp-chip--open`, and `lp-chips--soon`, defined in `css/blocks.css`. The component maps entries to `<li>` elements, applying `lp-chip--open` only when an entry's `open` is `true` and `lp-chips--soon` on the `<ul>` only when the list's `soon` prop is `true`; no item receives a baseline per-item class of its own (see **base-list-styling** and Design Decisions for why).

- **SwiftUI**: Create a horizontal or wrapping layout (an `HStack`, or a custom wrapping container for longer lists) containing one view per entry. Mark the active entry's chip using `.foregroundStyle()` or an accent background rather than the deprecated `.foregroundColor()`. Dim the entire row when the list represents the upcoming variant — bound to `soon`, not to any individual item's `open` state — and draw the dashed border for that variant with `StrokeStyle(dash:)` on a `Capsule` or `RoundedRectangle` shape.

- **Compose**: Implement as a `FlowRow` (so chips wrap) containing a Chip composable (or `Surface` + `Text`) per entry. Apply `Modifier.alpha()` to a chip's content to mark the active entry, and dim the whole row for the upcoming variant. Draw the dashed border for the upcoming variant with `Modifier.drawBehind { drawRoundRect(style = Stroke(pathEffect = PathEffect.dashPathEffect(floatArrayOf(4f, 4f)))) }` rather than `BorderStroke`, which has no path-effect parameter.

- **AppKit / UIKit**: Create an `NSStackView` (macOS) or `UIStackView` (iOS) with axis `.horizontal` containing a custom `NSView`/`UIView` subclass per chip. Use a `CAShapeLayer` for the dashed border on the upcoming variant. Dimming applies to the whole row (bound to `soon`), not to individual chips, matching the list-level nature of the upcoming variant in the source. Mark the active chip's own emphasis independently via its background or border, with no accompanying opacity or animation change, since the source defines no transition behavior for either state.

- **WinUI 3**: Implement using a `StackPanel` (`Orientation="Horizontal"`) or `ItemsRepeater`, containing a non-interactive `Border` per chip rather than a `Button`, since chips are not interactive. Bind the active chip's emphasis and the row's upcoming-variant dimming using a custom `IValueConverter` under the `Microsoft.UI.Xaml` namespace. Draw the dashed border for the upcoming variant with a `Rectangle`/`Path` using `StrokeDashArray`, rather than the UWP-only `Windows.UI.Xaml.Media.StrokeStyle`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Chips.tsx` | unverified |

## Design Decisions

**Decision**: List items receive no baseline per-item class; only an item marked active (`open: true`) gets a modifier class (`lp-chip--open`).
**Rationale**: The list container already carries the shared baseline styling for every chip, so a per-item class only needs to exist for the state that diverges from that baseline (active). Adding a matching baseline class to every item would duplicate what the container already expresses.
**Approved**: pending

**Decision**: The upcoming/de-emphasized treatment (`soon`) is a single modifier on the list container, not a flag on each entry.
**Rationale**: Every chip in an "upcoming" list shares the same de-emphasized treatment together, so expressing it once at the list level lets it compose independently with each entry's own active state, rather than requiring every entry to repeat the same flag.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` statuses rest on the source using plain `<ul>`/`<li>` markup and rendering the caller's `label` ReactNode unmodified, with no strings of its own to hardcode or transform; the `partial` statuses reflect that contrast, dynamic-type, RTL, and text-expansion behavior are governed by the CSS in `css/blocks.css`, which is outside this recipe's source file. separation-of-concerns passes because `Chips.tsx` is pure presentation over its `entries`/`soon` props with no logic beyond a class-name join, and unit-test-coverage passes because `blocks-argument.test.tsx`'s `Chips` suite exercises the `open` marker and the `soon` modifier with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku | Initial creation from web source (drafted by Claude Haiku) |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, genericized provider/roadmap language into reusable active-item and upcoming-list-variant concepts, reformatted Design Decisions into Decision/Rationale/Approved form, replaced the Compliance prose with a checked table, corrected the WinUI 3, Compose, SwiftUI, and AppKit platform notes, clarified the null-label edge case, and added test vectors for mixed active states, non-string labels, and soon-plus-open combinations |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
