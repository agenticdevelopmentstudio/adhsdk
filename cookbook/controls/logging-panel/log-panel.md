---
id: 57e33900-ca06-474e-abb1-d904c27a6336
title: "Log Panel"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A scrollable, column-based display for structured log lines with configurable columns, follow-tail behavior, and interactive cells."
platforms:
  - typescript
  - web
tags:
  - logging
  - display
  - data-table
depends-on: []
related: []
references:
  - https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
  - https://www.w3.org/WAI/WCAG21/Understanding/target-size-enhanced.html
approved-by: ""
approved-date: ""
---

# Log Panel

## Overview

The Log Panel component displays structured log data as rows and columns in a scrollable container. Each row represents a log entry with values in multiple columns. The component supports configurable column definitions, automatic follow-tail scrolling to the bottom when new entries arrive, limiting the visible row count, and optional click handlers on individual cells. It is designed for real-time data inspection, debugging output, and activity logs.

## Behavioral Requirements

- **render-columns**: Component MUST display all columns defined in the `columns` prop, rendering column headers when `showHeader` is true.
- **render-rows**: Component MUST render all visible log lines as rows with cell values keyed by column id from the `lines` prop.
- **show-empty-state**: Component MUST display the `emptyMessage` (default: `"(no events)"`) when `lines` is empty or no rows are visible.
- **enforce-max-lines**: Component MUST limit visible rows to the count specified in `maxLines` by retaining only the most recent entries, discarding older ones. See Edge Cases for behavior when `maxLines` is negative, `NaN`, or fractional.
- **follow-tail-by-default**: Component MUST scroll to the bottom when new lines are added, if `followTail` is true (default).
- **honor-follow-tail-toggle**: Component MUST stop scrolling to the bottom when `followTail` is set to false, and resume scrolling when `followTail` is set back to true.
- **detect-user-scroll**: Component MUST detect when the user has scrolled away from the bottom and stop following the tail until they scroll back to near the bottom (slack of 4 pixels).
- **handle-cell-click**: Component MUST invoke `column.onCellClick` when a cell is clicked, passing the entire `LogLine` object, if the handler is defined.
- **handle-cell-double-click**: Component MUST invoke `column.onCellDoubleClick` when a cell is double-clicked, passing the entire `LogLine` object, if the handler is defined. The click events that precede a double-click gesture still invoke `onCellClick`, if defined, per native browser event order (see Edge Cases).
- **apply-column-widths**: Component MUST apply the width from `column.width` to each column as a CSS grid track size, using the format `${width}px` for numeric values and the string value directly for other formats.
- **apply-default-column-width**: Component MUST use `minmax(120px, 1fr)` as the default grid track size for columns that do not specify a width.
- **apply-cell-text-alignment**: Component MUST align cell text according to `column.align` (e.g., `start`, `center`, `end`), defaulting to `start`.
- **apply-cell-level-color**: Component MUST apply the color for the log level (`cell.level`, falling back to `column.defaultLevel` when `cell.level` is not set) using the Level Colors table (see Appearance), when `cell.color` is not set.
- **apply-cell-custom-color**: Component MUST apply `cell.color` as the CSS color value if provided; it takes precedence over any level-based color.
- **apply-cell-mono-font**: Component MUST apply monospace font (CSS variable `--font-mono` or fallback to system monospace) when the effective mono flag is true. The effective flag is `cell.mono` when it is explicitly set, including an explicit `false`, and `column.defaultMono` otherwise.
- **apply-cell-strong-weight**: Component MUST apply font-weight of 600 if `cell.strong` is true.
- **apply-cell-link-styling**: Component MUST add the CSS class `lp-cell--link` if `cell.link` is true, allowing stylistic differentiation (e.g., underline, color change).
- **show-interactive-indicator**: Component MUST add the CSS class `lp-cell--interactive` to cells if `column.isClickable`, `cell.link`, or `column.onCellClick` is defined.
- **apply-cell-title-attribute**: Component MUST set the HTML `title` attribute on each cell to the cell's text content for tooltip display on hover.
- **support-max-height**: Component MUST apply the `maxHeight` style to the scrollable body container if `maxHeight` is provided.
- **support-custom-class**: Component MUST apply the `className` prop to the root container; the root class is `lp-root`, followed by `className` when provided.
- **apply-grid-layout**: Component MUST use CSS Grid with the grid-template-columns derived from all column widths for both the header and each row.
- **include-aria-roles**: Component MUST include ARIA roles: `row` on header and each row, `columnheader` on header cells, `cell` on body cells, and `rowgroup` on the rows list.
- **stop-event-propagation**: Component MUST call `stopPropagation()` on a cell's click or double-click event only when that cell has a corresponding `onCellClick` or `onCellDoubleClick` handler defined, preventing the event from bubbling to parent elements in that case. No listener is attached, and nothing is stopped, when no handler is defined for that interaction.

## Appearance

- **Container**: Grid-based layout with header and scrollable body sections
- **Column header cells**: Display column title; text alignment per column.align; default is left-aligned (start)
- **Body cells**: Display cell text; font, color, and weight applied per cell and column properties
- **Empty state**: Centered, gray text message when no rows are visible
- **Scrollbar**: Native to the OS; appears when content exceeds maxHeight
- **Cell background**: Transparent by default; cell text inherits color from level or custom color
- **Cell padding**: Not specified in source; stylesheet is expected to define via CSS classes
- **Monospace font**: Applied via CSS variable `--font-mono` or system fallback `ui-monospace, SFMono-Regular, monospace`
- **Level colors**: Text color is determined by mapping the log level (`cell.level`, falling back to `column.defaultLevel`) to a CSS variable with a platform-color fallback:

  | Level | CSS Variable | Fallback |
  |-------|--------------|----------|
  | info | `--lp-color-info` | `var(--color-text-primary, #1a1a24)` |
  | warn | `--lp-color-warn` | `var(--color-warn, #b45309)` |
  | error | `--lp-color-error` | `var(--color-error, #c0392b)` |
  | success | `--lp-color-success` | `var(--color-success, #1f7a4d)` |
  | debug | `--lp-color-debug` | `var(--color-text-secondary, rgba(0,0,0,0.55))` |
  | dim | `--lp-color-dim` | `var(--color-text-dim, rgba(0,0,0,0.45))` |
  | accent | `--lp-color-accent` | `var(--color-accent, #1e3a5f)` |

  `cell.color`, when provided, overrides the level-based color entirely.

## States

| State | Appearance change |
|-------|---|
| Default | Rows display with configured colors and fonts |
| Empty | Empty message text is shown; rows are hidden |
| Interactive cell hovered | CSS class `lp-cell--link` or `lp-cell--interactive` applied for visual feedback |
| User scrolled away from tail | Component stops auto-scrolling; no visual change to rows themselves |
| followTail disabled | Component does not scroll on new content; no visual change |

## Accessibility

- **Role**: The root container is a grid-based table-like structure; ARIA roles are applied: `row` for header and data rows, `columnheader` for header cells, `cell` for body cells, `rowgroup` for the rows list. The root container itself does not carry a `table` or `grid` role, so the ARIA structure implied by these child roles is incomplete (see Compliance: semantic-markup).
- **Labels**: Column headers serve as labels for columns; each header cell has role `columnheader` and displays the column title text.
- **Interactive cells**: Cells with click handlers or the `isClickable` flag receive the CSS class `lp-cell--interactive`. This class is a styling hook only — it carries no ARIA semantics and does not by itself communicate interactivity to assistive technology. See **Keyboard navigation** below.
- **Title attribute**: Each cell sets the HTML `title` attribute to the cell's text content, which shows a hover tooltip in most browsers. Screen reader support for `title` is inconsistent, so it is not a reliable accessible name for interactive cells.
- **Text alternatives**: Text content is displayed directly; no icons or images require alt text in the component itself.
- **Keyboard navigation**: Not implemented in source. Cells have no `tabIndex`, no `onKeyDown` handler, and no focus management; `onClick`/`onDoubleClick` are the only interaction handlers wired to a cell, so interactive cells (marked by `column.isClickable`, `cell.link`, or `column.onCellClick`) are reachable only by mouse.
- **Minimum tap target**: Not applicable: Cell dimensions and tap target sizes are controlled by CSS styling, not by the component; consumers must ensure minimum tap/click targets via stylesheet implementation. WCAG 2.5.8 (Target Size Minimum, Level AA) requires at least 24×24 CSS px; WCAG 2.5.5 (Target Size Enhanced, Level AAA) and platform HIG guidance recommend 44×44pt.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|---|---|---|
| log-panel-001 | render-columns | columns=[{id:'level',title:'Level'},{id:'msg',title:'Message'}], showHeader=true | Header displays two cells with text 'Level' and 'Message' |
| log-panel-002 | render-rows | lines=[{id:'1',values:{level:{text:'info'},msg:{text:'Started'}}}], columns=[...] | One row with two cells displaying 'info' and 'Started' |
| log-panel-003 | show-empty-state | lines=[], emptyMessage='No logs' | Container displays text 'No logs' |
| log-panel-004 | enforce-max-lines | lines=[{id:'1',...},{id:'2',...},{id:'3',...}], maxLines=2 | Only rows with id '2' and '3' are visible; row id '1' is hidden |
| log-panel-005 | follow-tail-by-default | followTail=true (default), lines appended | The scroll container is scrolled to its maximum scrollable position (bottom) after new lines render |
| log-panel-006 | honor-follow-tail-toggle | followTail=true, user appends line, then followTail=false, user appends second line | First append scrolls to bottom; second append does not scroll |
| log-panel-007 | detect-user-scroll | followTail=true, user manually scrolls up so the distance from the bottom exceeds 4px, then a new line is appended | The scroll container does not scroll to the bottom for that append |
| log-panel-008 | handle-cell-click | `column={..., onCellClick: <mock function>}`, click cell | onCellClick is called with the LogLine object |
| log-panel-009 | handle-cell-double-click | `column={..., onCellDoubleClick: <mock function>}`, double-click cell | onCellDoubleClick is called with the LogLine object |
| log-panel-010 | apply-column-widths | columns=[{id:'a', width:200}, {id:'b', width:'1fr'}] | gridTemplateColumns is '200px 1fr' |
| log-panel-011 | apply-default-column-width | columns=[{id:'a'} (no width specified)] | gridTemplateColumns includes 'minmax(120px, 1fr)' for that column |
| log-panel-012 | apply-cell-text-alignment | column={align:'center'}, cell text 'Centered' | CSS textAlign is set to 'center' |
| log-panel-013 | apply-cell-level-color | cell={level:'error'}, column={defaultLevel:'info'} | Cell color matches the 'error' row of the Level Colors table |
| log-panel-014 | apply-cell-custom-color | cell={color:'#ff0000'} | CSS color is '#ff0000' (overrides level color) |
| log-panel-015 | apply-cell-mono-font | cell={mono:true} | fontFamily is 'var(--font-mono, ui-monospace, SFMono-Regular, monospace)' |
| log-panel-016 | apply-cell-strong-weight | cell={strong:true} | fontWeight is 600 |
| log-panel-017 | apply-cell-link-styling | cell={link:true} | CSS class 'lp-cell--link' is present |
| log-panel-018 | show-interactive-indicator | column={onCellClick: () => {}}, cell | CSS class 'lp-cell--interactive' is present |
| log-panel-019 | apply-cell-title-attribute | cell={text:'Error message'} | title attribute on cell div is 'Error message' |
| log-panel-020 | support-max-height | maxHeight='500px' | Body container has CSS maxHeight: '500px' |
| log-panel-021 | support-custom-class | className='custom-log' | Root container has class 'lp-root custom-log' |
| log-panel-022 | apply-grid-layout | columns with widths=[200, '1fr', 100] | gridTemplateColumns is '200px 1fr 100px' on both header and rows |
| log-panel-023 | include-aria-roles | Standard render | Header has role='row', columns have role='columnheader', rows have role='row', cells have role='cell', rows list has role='rowgroup' |
| log-panel-024 | stop-event-propagation | Cell has onCellClick defined and is nested inside a parent element with its own click handler; click the cell | onCellClick is invoked; the parent element's click handler is not invoked (the event does not bubble to it) |
| log-panel-025 | render-columns | columns=[...], showHeader=false | No header row is rendered |
| log-panel-026 | show-empty-state | lines=[], emptyMessage not provided | Container displays text '(no events)' |
| log-panel-027 | enforce-max-lines | lines=[{id:'1',...},{id:'2',...}], maxLines=0 | Zero rows are visible; empty message is shown |
| log-panel-028 | honor-follow-tail-toggle | followTail=false, user scrolled away from the bottom, then followTail=true, line appended | The next append scrolls the container to the bottom |
| log-panel-029 | apply-cell-mono-font | cell={mono: undefined}, column={defaultMono:true} | fontFamily is 'var(--font-mono, ui-monospace, SFMono-Regular, monospace)' |

## Edge Cases

- **Empty columns array**: If `columns` is an empty array, the header (when `showHeader` is true) renders with no header cells, and each row renders with no cells. An empty `columns` array does not by itself trigger the empty state — the empty message is shown only when `lines` is empty (or `maxLines` reduces the visible count to zero).
- **Empty lines array**: Component displays the empty message instead of rows; no error occurs.
- **maxLines less than visible rows**: Component retains only the last `maxLines` entries; older entries are completely removed from the visible set.
- **maxLines equals 0**: Component displays no rows (visible count becomes 0); empty message is shown.
- **maxLines is undefined**: Component displays all lines without truncation.
- **maxLines is NaN**: Comparisons against a `NaN` limit are always false, so the truncation never triggers; behavior matches `maxLines` being unset.
- **maxLines is negative**: The truncation check still triggers (any non-negative line count exceeds a negative limit), but the resulting slice start index exceeds the array length, so zero rows are kept and the empty message is shown.
- **maxLines is fractional**: The slice used to trim rows truncates a fractional start index toward zero rather than rounding it, so the row count kept can differ from the rounded value; pass an integer to get a predictable result.
- **Undefined cell values**: A column value that is `undefined` is treated as empty text (`""`); the column's `defaultLevel`/`defaultMono` still apply per **apply-cell-level-color**/**apply-cell-mono-font** (though with no text to render, this has no visible effect), and no `strong` or `link` styling is applied since those come only from `cell.strong`/`cell.link`, never a column default. No error occurs.
- **String cell values**: A column value that is a plain string is treated as text content (`{text: value}`); the column's `defaultLevel`/`defaultMono` apply to it exactly as they would to an object-form cell (per **apply-cell-level-color**/**apply-cell-mono-font**), but no `strong` or `link` styling is applied, since those come only from `cell.strong`/`cell.link`, which a plain string cannot carry.
- **Column width as string**: A column width given as a string (e.g. `'1fr'`, `'50%'`) is used directly as the grid track size.
- **Column width as number**: A column width given as a number (e.g. `200`) becomes the pixel value (`'200px'`) for the grid track size.
- **Column width undefined**: A column with no width specified uses the default track size `minmax(120px, 1fr)`.
- **followTail flips from false to true**: Resuming follow-tail causes the next appended line to scroll the container to the bottom, even if the user had scrolled away while it was disabled.
- **Scroll container not yet mounted**: All scroll-related logic is skipped when the scrollable element is not available; no errors occur.
- **New lines added while scrolled away from the tail**: The component does not auto-scroll on subsequent appends until the user scrolls back within 4px of the bottom.
- **Very long cell text**: Cell displays full text with a `title` attribute for a hover tooltip; no truncation or overflow behavior is enforced by the component (stylesheet responsibility).
- **Special characters or HTML in cell text**: Cell text is rendered as plain text; no HTML parsing or injection occurs even if the string contains HTML-like characters.
- **Double-click also fires preceding click handling**: The component does not suppress or debounce `onCellClick` when `onCellDoubleClick` is also defined; a double-click gesture invokes `onCellClick` for the click events that precede the `dblclick` event, per native browser event order, in addition to invoking `onCellDoubleClick`.
- **Large maxLines value**: The component renders one DOM node per visible row with no virtualization or windowing; a very large `maxLines` (or unbounded `lines` with `maxLines` unset) renders a proportionally large number of DOM nodes. Consumers SHOULD bound `maxLines` to a count appropriate for the container's `maxHeight`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| columns | LogColumn[] | (required) | Array of column definitions, each with id, title, and optional width, align, defaultLevel, defaultMono, isClickable, onCellClick, onCellDoubleClick |
| lines | LogLine[] | (required) | Array of log line entries, each with id and values object keyed by column id |
| followTail | boolean | true | Automatically scroll to bottom when new lines are added |
| maxLines | number \| undefined | undefined | Maximum number of visible rows; older rows are discarded when limit is exceeded |
| emptyMessage | string | "(no events)" | Message displayed when no rows are visible |
| showHeader | boolean | true | Display column header row |
| className | string | undefined | Additional CSS class(es) to apply to the root container |
| maxHeight | string \| number \| undefined | undefined | CSS max-height value for the scrollable body container |

## Deep Linking

Not applicable: Log Panel is a data display component without URL-based navigation or deep linking support.

## Localization

The component has no UI text of its own other than the default `emptyMessage`; column titles and log content are supplied by the consumer and are outside the component's control.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `emptyMessage` | `(no events)` | Shown in the scrollable body when there are no visible rows |

The default value is hardcoded English. Consumers that support additional locales SHOULD supply a localized `emptyMessage` string rather than rely on the built-in default.

## Accessibility Options

Not applicable: The component does not respond to system accessibility settings like reduced motion or increased contrast. Such behavior, if desired, would be implemented by the consumer via conditional CSS or prop adjustments.

## Feature Flags

Not applicable: The component has no internal feature flags or toggle points.

## Analytics

Not applicable: The component does not emit events or track user interactions; click handlers are delegated to consumers via `onCellClick` and `onCellDoubleClick` callbacks.

## Privacy

Not applicable: The component displays data provided by the consumer; it does not collect, store, or transmit any data independently.

## Logging

Not applicable: The component does not emit logs or diagnostic output.

## Platform Notes

- **SwiftUI**: Implement as a SwiftUI view using `List` or `ScrollView` with `LazyVStack` for rows. Use `@State`/`@StateObject` for scroll offset tracking and pinning logic. Apply `Text` or `HStack` cells with font and color modifiers matching the log level. Use `.onTapGesture` or `Button` for clickable cells. Track whether the view is scrolled to the bottom with `onScrollGeometryChange` (iOS 18+) rather than `ScrollViewReader`, which does not report scroll offset.

- **Compose**: Implement as a Composable using `LazyColumn` for virtualized row rendering. Track scroll position via `rememberLazyListState()` and derive "at the bottom" from its `layoutInfo` (comparing the last visible item's index and offset against the total item count) — `LazyListState` has no built-in `isScrolledToTheEnd()`. Apply `Text` and `Row` composables for cells with color and font styles. Use the `clickable` modifier for interactive cells. Map log levels to the Material 3 color palette.

- **React/Web**: The component is implemented in TypeScript/React using hooks (`useRef`, `useEffect`, `useLayoutEffect`, `useMemo`). It uses CSS Grid for layout and relies on stylesheet rules for visual appearance (colors, spacing, fonts). Key files: `LogPanel.tsx`, `types.ts` (defines `LogPanelProps`, `LogLine`, `LogColumn`, `LogLevel`, `LogCellValue`). Cell values are normalized via a `normalize()` helper (`undefined` → `{text: ''}`, a plain string → `{text: value}`), column track sizes are computed via `trackSize()` (`number` → `'Npx'`, `string` passed through, `undefined` → the default), the visible row slice is memoized (`useMemo`) keyed on `[lines, maxLines]`, and tail-pinning state is tracked in a ref (`pinnedRef`) that is updated on scroll and reset via a `useEffect` when `followTail` flips back to `true`. Styling is applied via CSS class names (`lp-root`, `lp-header`, `lp-body`, `lp-row`, `lp-cell`, `lp-cell--interactive`, `lp-cell--link`, `lp-empty`) and inline styles for layout (`gridTemplateColumns`) and level-based colors. The component communicates interactivity via ARIA roles and data attributes.

- **AppKit / UIKit**: Implement as a `UITableView` (or `NSTableView` on macOS) with dynamic row height. `UITableView` has no native column concept — lay out each row's cells in a horizontal stack (`UIStackView`) or a custom cell class that positions subviews to match the grid columns; `NSTableView` on macOS does have real columns via `NSTableColumn`. Implement scroll tracking via `UIScrollViewDelegate.scrollViewDidScroll(_:)` (or the equivalent bounds-change notification on `NSScrollView`) to detect pinning. Apply `NSAttributedString` or `UIFont` with colors matching the log level. Use tap and double-tap gesture recognizers (or the table view delegate's selection/double-click handling) for cell interactions. For accessibility, set `accessibilityLabel` to the cell text and the appropriate `accessibilityTraits` on interactive cells — `accessibilityRole` is not a UIKit API.

- **WinUI 3**: WinUI 3 has no built-in `DataGrid`; use the `DataGrid` control from the Windows Community Toolkit (`CommunityToolkit.WinUI.Controls.DataGrid`), or a `Grid`/`ListView`-based custom layout, with configurable column width and alignment. Bind `ItemsSource` to the rows collection; use `INotifyCollectionChanged` to trigger follow-tail scrolling via `ScrollViewer.ChangeView()`. Apply `Brush` colors from the log level color mapping. Use `Tapped` and `DoubleTapped` events for cell interactions. Use `AutomationProperties.Name` for accessible labeling. For the monospace font, use `Cascadia Mono` or `Consolas` rather than `SymbolThemeFontFamily`, which is an icon font, not a monospace one.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/logging-panel/LogPanel.tsx` | unverified |

## Design Decisions

- **Decision**: Follow-tail is enabled by default (`followTail: true`).
  **Rationale**: Appropriate for real-time log inspection; consumers who want to preserve the user's scroll position can disable it.
  **Approved**: pending

- **Decision**: Scroll-to-bottom detection uses a 4-pixel slack (`const slack = 4`) instead of strict equality.
  **Rationale**: Accounts for rounding errors and sub-pixel rendering while balancing user intent (scrolled near the bottom) with responsiveness.
  **Approved**: pending

- **Decision**: The visible row set is memoized (`useMemo`) keyed on `[lines, maxLines]`.
  **Rationale**: Avoids recomputing the slice on every render; assumes `lines` and `maxLines` are the only factors affecting visibility.
  **Approved**: pending

- **Decision**: Level-based colors are applied through CSS variables with fallbacks rather than hard-coded color values.
  **Rationale**: Lets consumers override log-level colors at the stylesheet level without modifying the component.
  **Approved**: pending

- **Decision**: Cell tooltips use the native HTML `title` attribute rather than a custom tooltip element.
  **Rationale**: Relies on native browser tooltip behavior and requires no additional markup.
  **Approved**: pending

- **Decision**: The layout uses CSS Grid with ARIA roles (`row`, `columnheader`, `cell`) rather than native `<table>`/`<thead>`/`<tbody>` elements.
  **Rationale**: Lets CSS Grid handle layout while preserving accessibility roles for assistive technology.
  **Approved**: pending

- **Decision**: Click and double-click events are stopped at the cell (`stopPropagation()`) when a cell handler runs, rather than left to bubble.
  **Rationale**: Ensures the cell's own callback is the only handler invoked for that interaction.
  **Approved**: pending

- **Decision**: Undefined cell values are normalized to empty text (`{text: ''}`).
  **Rationale**: Ensures no rendering errors when a row is missing a value for a column.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | failed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: interactive cells have no ARIA label or role beyond the styling-only `lp-cell--interactive` class and the inconsistently-supported `title` attribute, and no keyboard handling exists at all (screen-reader-support, keyboard-navigable); the root container carries `row`/`columnheader`/`cell`/`rowgroup` roles but no enclosing `table`/`grid` role (semantic-markup); text color and tap-target sizing are delegated to consumer-supplied CSS variables and stylesheets, which the source cannot verify (contrast-ratio, touch-target-size, dynamic-type-support); and the default `emptyMessage` string `'(no events)'` is hardcoded in English, though it is overridable via the `emptyMessage` prop (no-hardcoded-strings, string-externalization). `separation-of-concerns` passes because `LogPanel.tsx`'s `cellStyle()` is presentation-only formatting logic (mapping column config to CSS classes) that stays inside the one rendering component, with no data fetching or infrastructure code mixed in. `unit-test-coverage` passes because `__tests__/LogPanel.test.tsx` exercises the component with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | String/undefined cells now correctly show defaultLevel/Mono apply; history reordered; Compliance added. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; clarify cell color/mono precedence and the stop-event-propagation scope; add a Level Colors table; rewrite test vectors and edge cases as observable outcomes and add missing coverage; correct overclaimed Accessibility statements and the WCAG tap-target citation; reformat Design Decisions; add a Compliance table; reorder and correct Platform Notes API references; treat the default emptyMessage as a localizable string. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise accessibility guidance; clarify keyboard navigation gap and tap target responsibility |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
