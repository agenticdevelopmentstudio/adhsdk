---
id: 7e4a2c5b-8f3d-4a7e-b9f2-1c5e8d3b6a2f
title: "Cards"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Responsive grid container for arranging card items with adaptive column layout."
platforms:
  - typescript
  - web
tags:
  - layout
  - grid
  - cards
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Cards

## Overview

A responsive grid container that arranges card items in a flexible column layout. By default, cards flow through a shared `auto-fit` track. The caller opts a set of cards into an explicit column count only when the shared track would otherwise leave a lone item stranded on its own row: `pair` for a four-item set (which the shared track would otherwise lay out as 3 + 1) and `trio` for a nine-item set (which it would otherwise lay out as 4 + 4 + 1). The component never counts its own children — the caller chooses `pair`/`trio` based on how many children it is passing. The component renders a single `<div>` container that accepts children and optional styling.

## Behavioral Requirements

- **render-as-div**: Component MUST render as a single `<div>` element.
- **base-class**: Component MUST apply the `lp-cards` class to the rendered element.
- **pass-children**: Component MUST render all provided children within the container.
- **pair-layout**: When `pair` prop is `true`, component MUST apply the `lp-cards--pair` class to enable two-column layout.
- **trio-layout**: When `trio` prop is `true`, component MUST apply the `lp-cards--trio` class to enable three-column layout.
- **reject-conflicting-props**: Component MUST throw an error with message `"Cards: \`pair\` and \`trio\` set the same column track — pass at most one"` when both `pair` and `trio` are `true`.
- **classname-prop**: Component MUST accept an optional `className` prop and include it in the rendered element's class list.
- **combine-classes**: Component MUST combine all applicable classes with single space separators and filter out empty strings.

## Appearance

- **Container element**: `<div>`
- **Base class**: `lp-cards` — `lp-` is the fixed class-prefix namespace of `@adh-sdk/landing`, not a per-consumer template variable.
- **Variant classes**: `lp-cards--pair`, `lp-cards--trio`
- **Layout basis**: CSS Grid. Base track (no `pair`/`trio`): `grid-template-columns: repeat(auto-fit, minmax(16.5rem, 1fr))` (a 231px floor at this package's 87.5% root font size), with `gap: 1rem` (14px).
- **Default behavior**: The base auto-fit track above; no breakpoint applies.
- **Pair behavior**: `pair={true}` renders a single `minmax(0, 1fr)` column below a 48rem (768px) viewport width, and switches to an explicit two-column track (`repeat(2, minmax(0, 1fr))`) at 48rem and above.
- **Trio behavior**: `trio={true}` renders a single `minmax(0, 1fr)` column below a 56rem (896px) viewport width, and switches to an explicit three-column track (`repeat(3, minmax(0, 1fr))`) at 56rem and above.
- **Styling**: Controlled entirely through CSS classes; no inline styles applied by component

## States

Not applicable: Cards is a pure layout container with no interactive states.

## Accessibility

- Role: Generic container (`<div>` has no semantic role unless children are interactive)
- Semantics: Responsibility for meaningful content structure falls to children rendered within the container
- Keyboard navigation: Not applicable; component is not interactive
- Screen reader: Announcements depend entirely on children; container itself is transparent to assistive technology

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cards-001 | render-as-div | No props | Renders `<div>` element |
| cards-002 | base-class | No props | Element has class `lp-cards` |
| cards-003 | pass-children | `children: <span>Item</span>` | Span element is rendered within container |
| cards-004 | pair-layout | `pair={true}` | Element has classes `lp-cards lp-cards--pair` |
| cards-005 | trio-layout | `trio={true}` | Element has classes `lp-cards lp-cards--trio` |
| cards-006 | reject-conflicting-props | `pair={true} trio={true}` | Throws error: `"Cards: \`pair\` and \`trio\` set the same column track — pass at most one"` |
| cards-007 | classname-prop | `className="custom"` | Element has classes `lp-cards custom` |
| cards-008 | combine-classes | `pair={true} className="custom"` | Element has classes `lp-cards lp-cards--pair custom` in output |
| cards-009 | pass-children | No `children` prop (omitted) | Renders `<div>` with no child nodes |
| cards-010 | pass-children | `children={null}` | Renders `<div>` with no child nodes |
| cards-011 | classname-prop, combine-classes | `className=""` | Element's class attribute is exactly `lp-cards`; no trailing or double space |
| cards-012 | pair-layout | `pair={false}` | Element has class `lp-cards` only; no `lp-cards--pair` class |
| cards-013 | pair-layout | `pair={1}` (truthy, not the literal `true`) | Element has class `lp-cards` only; `lp-cards--pair` is NOT applied |
| cards-014 | trio-layout, classname-prop | `trio={true} className="custom"` | Element has classes `lp-cards lp-cards--trio custom` |

## Edge Cases

- **Conflicting props**: When both `pair` and `trio` are true, an error MUST be thrown synchronously before rendering. This is a caller error, not a silent resolution.
- **Null or undefined children**: Component MUST render successfully with no children or `null` as children; the container remains empty.
- **Empty className**: When `className` is an empty string, it MUST be filtered out and not produce double spaces in the class attribute.
- **Falsy pair/trio**: When `pair` or `trio` are `false`, `undefined`, or not provided, the corresponding class MUST NOT be applied.
- **Boolean prop identity**: Both the conflicting-props check and each variant's class application use strict equality (`=== true`). A falsy value (`0`, `''`, `null`, `undefined`) MUST NOT trigger the conflict error or apply a variant class; a truthy non-boolean value (e.g. `pair={1}`) MUST NOT apply the variant class either — only a literal `true` does.

## Configuration

Not applicable: Cards accepts only presentation-layer props (`children`, `pair`, `trio`, `className`) and has no configurable behavior or options.

## Deep Linking

Not applicable: Cards is a layout container with no user-facing interaction or navigation targets.

## Localization

Not applicable: Cards renders no user-facing text; all content is provided by children.

## Accessibility Options

Not applicable: Cards responds to no platform accessibility options. Accessibility concerns are delegated to children and CSS styling rules (`lp-cards`, `lp-cards--pair`, `lp-cards--trio`).

## Feature Flags

Not applicable: Cards has no conditional behavior subject to feature flags.

## Analytics

Not applicable: Cards is a pure layout container and does not emit user interaction events.

## Privacy

Not applicable: Cards does not collect, store, or transmit data.

## Logging

Not applicable: Cards performs no operations requiring diagnostic logging beyond native browser DevTools inspection.

## Platform Notes

- **TypeScript/Web**: Component defined in `packages/web/packages/landing/src/blocks/Cards.tsx` (`@adh-sdk/landing`). Renders a plain `<div>` with CSS class composition — no ARIA role or semantics are added by the component itself. Grid behavior controlled by three CSS rules: `lp-cards` (base auto-fit track, 231px floor, 14px gap), `lp-cards--pair` (single column below 768px, explicit two-column track at 768px and above), and `lp-cards--trio` (single column below 896px, explicit three-column track at 896px and above). See `css/blocks.css` for the full rules.
- **SwiftUI**: Use `LazyVGrid` with `GridItem(.adaptive(minimum: 231))` and `spacing: 14` for the default auto-fit floor. Accept a `@ViewBuilder` for children. When `pair` is `true`, use a single `GridItem(.flexible())` column below a 768pt container width and two `GridItem(.flexible())` columns at 768pt and above; when `trio` is `true`, use one column below 896pt and three columns at 896pt and above. Compute the column count and breakpoint check as plain properties, not `@Binding` values — `pair`/`trio` are fixed booleans passed in by the caller, not two-way state.
- **Compose**: Use `LazyVerticalGrid` with `GridCells.Adaptive(minSize = 231.dp)` and `Arrangement.spacedBy(14.dp)` for the default floor. Accept a `@Composable` lambda for children. When `pair` is `true`, use `GridCells.Fixed(1)` below 768.dp of available width and `GridCells.Fixed(2)` at 768.dp and above (measure with `BoxWithConstraints`); when `trio` is `true`, use `GridCells.Fixed(1)` below 896.dp and `GridCells.Fixed(3)` at 896.dp and above.
- **AppKit / UIKit**: On macOS and iOS, use `NSCollectionView` / `UICollectionView` with a compositional layout: an adaptive item group with a 231pt minimum item width and 14pt inter-item/inter-group spacing for the default floor. When `pair` is `true`, use a single-column group below a 768pt content width and a fixed two-column group at 768pt and above; when `trio` is `true`, use a single column below 896pt and a fixed three-column group at 896pt and above. Compute the column count from the current bounds width; do not use `NSStackView` or `UIStackView`, neither of which can express the auto-fit floor.
- **WinUI 3**: Use `ItemsRepeater` with a `UniformGridLayout` (`MinItemWidth="231"`, `MinRowSpacing="14"`, `MinColumnSpacing="14"`, `ItemsStretch="Fill"`) for the default auto-fit floor. When `pair` is `true`, set `MaximumRowsOrColumns="1"` below a 768px panel width and `MaximumRowsOrColumns="2"` at 768px and above; when `trio` is `true`, use `1` below 896px and `3` at 896px and above. Bind `ItemsRepeater.ItemsSource` to the children collection.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Cards.tsx` | unverified |

## Design Decisions

**Decision**: Apply an explicit two-column grid track (`lp-cards--pair`) when the caller flags a four-item set as `pair`.
**Rationale**: CSS Grid's shared `auto-fit` track lays four cards out as 3 + 1 at typical card widths, creating a visually incomplete trailing row; forcing two columns keeps four items balanced as 2×2.
**Approved**: pending

**Decision**: Apply an explicit three-column grid track (`lp-cards--trio`) when the caller flags a nine-item set as `trio`.
**Rationale**: The same shared `auto-fit` track lays nine cards out as 4 + 4 + 1; forcing three columns keeps nine items visually balanced instead of leaving a lone trailing item.
**Approved**: pending

**Decision**: Throw synchronously when both `pair` and `trio` are `true`, rather than resolving the conflict silently.
**Rationale**: Both props set the same CSS grid track; permitting both to be `true` would produce a result that depends on stylesheet cascade order, an ambiguity the component prevents by treating it as a caller error.
**Approved**: pending

**Decision**: Native ports SHOULD model `pair`/`trio` as a single `columns?: 'pair' | 'trio'` enum (or the platform equivalent), rather than as two independent booleans.
**Rationale**: The web source exposes `pair` and `trio` as independent optional booleans and only rejects the conflicting-props state by throwing at render time (see **reject-conflicting-props**); an enum-shaped prop makes that invalid state unrepresentable instead of merely caught at runtime.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Status rests on the source (`Cards.tsx`), which renders a plain `<div>` with only class-name composition — no ARIA role or attributes are added, which is correct for a non-interactive layout container that delegates all semantics to its children. Best-practices statuses rest on `Cards` being pure presentation over its `pair`/`trio`/`children` props, with only a caller-error guard and no business logic (separation-of-concerns: passed), and on `blocks-frame.test.tsx` directly rendering `Cards` and asserting its modifier-class and caller-error behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected pair (four-item) and trio (nine-item) item counts and documented their breakpoint/fallback behavior, dropped `must-` prefixes from requirement names and their citations, reformatted Design Decisions into Decision/Rationale/Approved entries and added an enum recommendation for native ports, added missing edge-case test vectors and corrected the boolean-prop-identity edge case, rewrote Platform Notes with concrete measurements and a real WinUI 3 API, replaced the Compliance section with a table, and clarified the `lp-` namespace and the TypeScript platform note |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
