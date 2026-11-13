---
id: b0ce8cbb-31ac-425a-889c-68e699d24578
title: "Table"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A semantic table for displaying rows of data under labeled columns, with a required caption identifying the data and optional visual caption display."
platforms:
  - typescript
  - web
tags:
  - table
  - data-display
  - accessibility
depends-on: []
related:
  - d04eef56-2dbf-4148-964b-c095f242227f
references:
  - https://www.w3.org/WAI/tutorials/tables/
  - https://html.spec.whatwg.org/multipage/tables.html#the-caption-element
  - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/th#attr-scope
approved-by: ""
approved-date: ""
---

# Table

## Overview

A data-presentation component that renders HTML semantic table structure with labeled columns, data rows, and a required caption. The caption is always provided but visually hidden by default to avoid redundancy with surrounding prose while remaining available to screen readers. Rows are validated at render time to ensure they match the column count, preventing silent misalignment of cells into wrong columns.

## Behavioral Requirements

- **caption-required**: Component MUST accept a required `caption` prop (ReactNode) that identifies the data population represented by the table rows.
- **row-width-validation**: Component MUST throw an error if any row has a length that does not match the `columns` array length, reporting the offending row index and cell counts.
- **caption-hidden-by-default**: Component MUST render the caption element and hide it from visual display by default (via `lp-sr-only` class), ensuring screen reader access to the caption.
- **visible-caption-option**: Component MUST accept an optional `showCaption` boolean prop that, when true, renders the caption visibly on the page (removing the `lp-sr-only` class).
- **column-headers-scoped**: Component MUST render a `<thead>` containing a single row of column headers, each wrapped in a `<th>` element with `scope="col"` attribute.
- **tbody-rows**: Component MUST render a `<tbody>` containing one row per entry in the `rows` prop, with each cell rendered as a `<td>` element.
- **columns-prop**: Component MUST accept a required `columns` array prop (ReactNode[]) that defines the header labels and establishes the table width.
- **rows-prop**: Component MUST accept a required `rows` array prop (ReactNode[][]) that defines the data cells, organized as rows.
- **scroll-container**: Component MUST wrap the table in a div element with class `lp-table-scroll` to enable horizontal scrolling on narrow viewports.
- **table-class**: Component MUST apply the `lp-table` class to the `<table>` element.

## Appearance

- **Container**: Div wrapper with class `lp-table-scroll` provides horizontal scroll context.
- **Table**: `<table>` element with class `lp-table`.
- **Headers**: `<th>` elements within `<thead>` render column labels (ReactNode content).
- **Cells**: `<td>` elements within `<tbody>` render row data (ReactNode content).
- **Caption**: `<caption>` element; visually hidden via `lp-sr-only` class unless `showCaption` is true.

Not applicable: Styling (font, color, spacing, shadows) is defined via CSS classes and is not specified by the component.

## States

Not applicable: This component is a static data container with no interactive or loading states. It either renders successfully or throws a validation error at render time.

## Accessibility

- **Semantic table structure**: Component uses native `<table>`, `<thead>`, `<tbody>`, `<th>`, `<td>`, and `<caption>` elements, providing structural semantics to assistive technology.
- **Column headers**: Each column header in `<th>` has `scope="col"` attribute, associating cells with their column.
- **Caption requirement**: The caption prop is required and always rendered, ensuring screen readers announce what data the table represents.
- **Caption visibility toggle**: The `showCaption` prop allows the caption to be displayed visually when the surrounding context does not already identify the table's purpose.
- **Screen reader only class**: The `lp-sr-only` class hides the caption from sighted users by default while preserving it for screen readers.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| table-001 | caption-required, columns-prop, rows-prop | `caption="Run Results"`, `columns=["Date", "Status"]`, `rows=[["2026-09-22", "Pass"], ["2026-09-21", "Fail"]]` | Table renders with caption "Run Results" hidden from visual display and two rows of data |
| table-002 | column-headers-scoped | `columns=["Name", "Role"]` | `<thead>` contains `<tr>` with two `<th scope="col">` elements containing "Name" and "Role" respectively |
| table-003 | tbody-rows | `rows=[["Alice", "Engineer"], ["Bob", "Designer"]]` | `<tbody>` contains two `<tr>` elements, each with two `<td>` elements containing the correct data |
| table-004 | row-width-validation | `columns=["A", "B"]`, `rows=[["1", "2"], ["3"]]` (second row has 1 cell, columns has 2) | Component throws an `Error` whose message includes the row index `1`, the row's cell count `1`, and the column count `2` (the reference implementation's exact text is `Table: row 1 has 1 cells but there are 2 columns`) |
| table-005 | caption-hidden-by-default | `caption="Revenue"`, `showCaption` not provided or false | Caption element renders with `class="lp-sr-only"` |
| table-006 | visible-caption-option | `caption="Revenue"`, `showCaption={true}` | Caption element renders without `lp-sr-only` class and is visible on page |
| table-007 | scroll-container, table-class | Any valid input | Outermost div has `class="lp-table-scroll"`, inner table has `class="lp-table"` |
| table-008 | row-width-validation | `columns=["X", "Y", "Z"]`, `rows=[["1", "2", "3"]]` (row length matches) | No error is thrown; row renders correctly |
| table-009 | rows-prop | `columns=["Name", "Role"]`, `rows=[]` | `<tbody>` renders with zero `<tr>` elements; `<thead>` still renders two `<th scope="col">` headers; no error is thrown |
| table-010 | columns-prop, row-width-validation | `columns=[]`, `rows=[]` | `<thead>` renders a `<tr>` with zero `<th>` elements; `<tbody>` renders zero `<tr>` elements; no error is thrown |
| table-011 | tbody-rows | `columns=["A", "B"]`, `rows=[[null, "x"]]` | Both `<td>` elements render; the first is empty (`null` renders as no visible content), the second contains "x"; no error is thrown |
| table-012 | tbody-rows, columns-prop | `columns=["Name", <strong>Status</strong>]`, `rows=[["Alice", <span>Active</span>]]` | The header and cell render the ReactNode content as given (the `<strong>` and `<span>` elements appear in the DOM); no error is thrown |

## Edge Cases

- **Empty columns array**: If `columns` is an empty array, the table renders with no header cells and no validation error on rows (rows must also be empty or each row must have zero cells). MUST render without error if rows are also empty; throws error if rows contain non-empty sub-arrays. See Design Decisions.
- **Empty rows array**: If `rows` is an empty array, the table renders with headers but no body rows. MUST render without error.
- **Null or undefined cells**: If a cell value is `null`, `undefined`, or a falsy ReactNode, it renders as an empty cell. MUST render without error and display the cell visually empty.
- **ReactNode content in cells**: Cells accept ReactNode values (strings, numbers, React elements, fragments). MUST render without error regardless of ReactNode type.
- **reports-first-mismatched-row**: Row-width validation checks every row in order and reports the lowest index at which a mismatch occurs; it does not assume only the first row can be invalid. MUST report the index of the first row found to be incorrect.

## Configuration

Not applicable: This component takes only required props (`caption`, `columns`, `rows`) and an optional boolean (`showCaption`). No additional configuration options are provided.

## Deep Linking

Not applicable: This component is a data presentation element used within a page and does not define its own deep linking behavior.

## Localization

Not applicable: The component itself does not emit any static strings; all text content (column headers, cell values, caption) is provided by the caller via props. Localization is the caller's responsibility.

## Accessibility Options

- **Reduce Motion**: Not applicable. This component does not animate; static layout requires no motion reduction.
- **Increase Contrast**: Not applicable. Text and background contrast is controlled by the CSS classes (`lp-table`, `lp-sr-only`) and is not a component responsibility.
- **Differentiate Without Color**: Not applicable. The component does not use color as the sole means of distinction; it relies on semantic HTML structure and cell content.

## Feature Flags

Not applicable: This component provides no feature flags or conditional behavior based on feature toggles.

## Analytics

Not applicable: This component is a static data container and does not emit events or analytics data.

## Privacy

Not applicable: The component does not collect, store, or transmit data. It renders data provided by the caller.

## Logging

Not applicable: The component does not log anything. A row-width mismatch (**row-width-validation**) throws synchronously, and the error propagates to the nearest error boundary (or aborts the render if none exists) rather than being written to a log.

## Platform Notes

- **React/Web**: Defined in `packages/web/packages/landing/src/blocks/Table.tsx`. Uses native HTML `<table>`, `<thead>`, `<tbody>`, `<th>`, `<td>`, `<caption>` elements with CSS classes `lp-table`, `lp-table-scroll`, and `lp-sr-only` for styling and screen-reader-only visibility. Row width validation occurs at render time and throws an error if mismatched.
- **SwiftUI**: Start with a SwiftUI `Table` (iOS 16.0+, macOS 12.0+) or a custom list-based layout using `List` and `HStack` to simulate columns. Render column headers via a custom header row view. Validate row width synchronously — during model initialization or with a `precondition`/`fatalError` before the view is built, not inside `.onAppear` or another later effect — so a misaligned row never renders, matching **row-width-validation**. Apply `.accessibilityLabel(_:)` to the table's container to expose the required caption to VoiceOver, and use `.accessibilityElement(children: .combine)` to associate a row's cells with its column headers. When `showCaption` is true, also render the caption as a visible `Text` above the table.
- **Compose**: Use `LazyColumn` to render rows and `Row` for each row's cells, applying `Modifier.horizontalScroll(rememberScrollState())` to enable horizontal scrolling on narrow viewports. Define column widths using `Modifier.weight()` or fixed widths. Render column headers as a sticky header row at the top. Validate row width synchronously during data/model construction with a `require()` check before composition, not in a `LaunchedEffect`, so a misaligned row never composes, matching **row-width-validation**. Set `contentDescription` on the container to expose the required caption to TalkBack, and use `Modifier.semantics { }` on cells to associate them with columns. When `showCaption` is true, also render the caption as a visible `Text` above the table.
- **AppKit / UIKit**: AppKit's `NSTableView` offers native column-header support via `NSTableColumn` objects — implement `NSTableViewDataSource`/`NSTableViewDelegate` to provide column headers and row data, validating row widths in the data source's initializer and throwing or calling `precondition` on mismatch. UIKit's `UITableView` has no column-header concept, so use `UICollectionView` with a compositional layout (one section per row, a header supplementary view for column labels) instead. On both platforms, set an accessibility label on the table's container (`NSAccessibility.Element` / `UIAccessibilityElement`) to expose the required caption, and set `accessibilityLabel` on cells to associate them with their column header where needed. When `showCaption` is true, also render the caption in a visible label above the table.
- **WinUI 3**: Use the CommunityToolkit `DataGrid` (`CommunityToolkit.WinUI.UI.Controls.DataGrid`) or construct a custom table using `Grid` with `ColumnDefinition` elements for column headers and rows of `TextBlock` elements for cells. Bind column count to the grid's column definitions and validate row counts synchronously in the view model's constructor, throwing before the view binds, matching **row-width-validation**. Set `AutomationProperties.Name` on the table's container to expose the required caption to Narrator, and set `AutomationProperties.Name` on each column header to associate it with its cells. For narrow viewports, wrap the table in a `ScrollViewer` with `HorizontalScrollBarVisibility="Auto"`. When `showCaption` is true, also render the caption as a visible `TextBlock` above the table.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Table.tsx` | unverified |

## Design Decisions

**Decision**: The `caption` prop is required and always rendered; it is visually hidden via `lp-sr-only` unless the caller passes `showCaption={true}`, which defaults to `false`.
**Rationale**: The caption is the only element that identifies the data population the table represents — omitting it silently risks presenting a partial sample (e.g., three of ten runs) as complete, misleading readers. The default visual hiding preserves the caption's accessibility benefit while avoiding redundancy with surrounding prose that already states the table's purpose. A caller passes `showCaption={true}` only when the surrounding context does not already identify the table's purpose and the caption's text needs to be visible on the page.
**Approved**: pending

**Decision**: Row width validation (**row-width-validation**) occurs synchronously at render time and throws a synchronous error on mismatch, rather than returning a validation result.
**Rationale**: This fail-fast behavior prevents silent data misalignment — the kind of defect that reads as a typo in the content rather than as a bug — and makes the error obvious during development. A validation framework could instead return a validation result prop; this implementation prioritizes immediate visibility over graceful error recovery.
**Approved**: pending

**Decision**: The component uses semantic HTML (`<table>`, `<th scope="col">`, `<caption>`) to delegate accessibility responsibility to browser defaults rather than requiring custom ARIA roles.
**Rationale**: This approach reduces implementation burden and follows the practice of preferring native semantics over custom ARIA roles when a native element already provides the needed behavior, per the W3C WAI tables tutorial and the HTML `caption`/`th[scope]` specification listed in `references`.
**Approved**: pending

**Decision**: An empty `columns` array is allowed. It produces a table with no header cells, and is valid only when every row also has zero cells (an empty `rows` array satisfies this trivially); **row-width-validation** still throws if any row has a non-zero length in that case.
**Rationale**: Zero columns is a degenerate input but not inherently invalid — the same width check that guards against misaligned cells already rejects any row that doesn't match it, so no separate rule against empty `columns` is needed. Banning zero columns outright would reject legitimate callers, such as a table rendered before its columns are known, without preventing any misalignment the existing check doesn't already catch.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: it uses semantic `<table>`/`<th scope="col">`/`<caption>` markup (semantic-markup) and contains no hardcoded strings, since every string comes from the caller via props (no-hardcoded-strings, string-externalization); font size and color are delegated entirely to the `lp-table`/`lp-sr-only` CSS classes, which the source does not define, so dynamic type and contrast ratio cannot be confirmed from the source alone (dynamic-type-support, contrast-ratio); the row-width validation (`rows.find`/`throw`) runs inline in the render function rather than as a separate helper (separation-of-concerns partial), and `blocks-frame.test.tsx`'s `Table` suite covers the header/row layout, the caption visibility toggle, and the mismatched-row-width throw (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case and update all citations, reformat Design Decisions into Decision/Rationale/Approved triples and add a decision for the empty-columns edge case, replace Compliance's "Not applicable" with an evaluated check table, add references for the semantic-HTML decision, fix the Logging section's log-vs-throw claim, clarify the showCaption default, rename and clarify the first-mismatched-row edge case, add test vectors table-009 through table-012, loosen the row-width error-message vector to assert index and counts rather than exact text, correct invented/wrong Platform Notes APIs and add caption handling per platform, make Compose/SwiftUI validation synchronous and explicit, add tags and a related link to data-table |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
