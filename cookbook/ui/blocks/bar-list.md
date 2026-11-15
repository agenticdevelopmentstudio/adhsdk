---
id: d2534210-3131-48d5-a6f2-d5fa85bb5347
title: "BarList"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Ranked breakdown: each row shows a name and value over a thin proportional bar, long names wrap, rows past a limit expand in place, rows optionally selectable."
platforms:
  - typescript
  - web
tags:
  - chart
  - list
  - ranking
  - selection
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# BarList

## Overview

BarList is a ranked breakdown: a vertical list in which each row carries an item's name and its value together on one line, with a thin horizontal bar under them whose length is the value relative to the largest value in the list. It is built for long names (the source comment lists paths, referrers and hostnames): a label column beside the bar would leave such names truncated to nothing or crowding the bars out at phone width, so the name and value sit together from the left and the bar sits below. Nothing is hidden for good: a long name wraps, and rows past a limit open in place behind a "Show all N" button.

The list is plain text by default. When the host passes `onSelect`, every row becomes a button that reports the row's name and shows a pressed state against the host-supplied `selected` name, dimming the other rows. The host owns the data, the ordering, the selection and the value formatting; the component owns only the expanded or collapsed state of the overflow.

## Behavioral Requirements

- **row-order**: The component MUST render one row per shown item in the order of `items`, and MUST NOT sort or reorder them.
- **list-accessible-name**: The component MUST expose `ariaLabel` as the accessible name of the list of rows.
- **row-name**: Each row MUST show the item's `name`, left-aligned, on the same line as the value.
- **row-value-text**: Each row MUST show the value as text to the right of the name, formatted with `formatValue` applied to the item's `value`.
- **detail-replaces-value**: When an item has a `detail` string (any non-nullish string, including an empty one), the row MUST show `detail` in place of the formatted value, and MUST NOT call `formatValue` for that row.
- **default-value-format**: When `formatValue` is not given, the component MUST format a value with the count formatter exported by the trend chart block: an English-locale whole number with digit grouping when the absolute value is below 10,000, and English compact notation with at most one fraction digit from 10,000 upward.
- **name-wraps**: A name too long for the row MUST wrap onto further lines, breaking inside a word when necessary, and MUST NOT be truncated, ellipsized or clipped.
- **value-keeps-width**: The value text MUST NOT shrink or wrap while a long name wraps beside it.
- **bar-below-row**: Each row MUST draw its bar beneath the name and value line, 6px (0.375rem) tall, with a 4px (0.25rem) gap above it.
- **bar-length-proportional**: The bar's width MUST equal the item's value divided by the largest value among ALL items, as a percentage, so a row hidden by the limit still counts toward the maximum.
- **bar-zero-maximum**: When the largest value among all items is zero or less, every bar MUST have width 0%.
- **bar-minimum-width**: A bar for an item whose value is greater than zero MUST be at least 2px wide; a bar for an item whose value is zero or less MUST have no minimum width.
- **bar-color**: Every bar MUST be filled with the `color` prop, which defaults to the theme token `--color-apt-cat-blue`.
- **bar-decorative**: The bar MUST be hidden from assistive technology, because the value text beside the name carries the same information.
- **initial-row-limit**: The component MUST show only the first `maxItems` items until the overflow is opened; `maxItems` defaults to 8.
- **expand-control-presence**: The component MUST render the expand button only when the number of items is greater than `maxItems`, and MUST render no button of any kind for an unselectable list whose rows all fit.
- **expand-opens-in-place**: Activating the expand button MUST show every item in the same list, below the rows already shown, without navigation.
- **expand-label**: While collapsed the expand button MUST read "Show all N", where N is the total number of items; while expanded it MUST read "Show fewer".
- **expand-collapse**: Activating the button while expanded MUST return the list to its first `maxItems` items.
- **expand-state-exposed**: The expand button MUST expose whether the overflow is open (false when collapsed, true when expanded) to assistive technology.
- **empty-state**: When `items` is empty the component MUST render only the `emptyLabel` text, defaulting to "Nothing to show.", and MUST render no list and no button.
- **rows-plain-without-select**: When `onSelect` is not given, rows MUST be non-interactive text: no row button and no focus stop.
- **rows-are-buttons-with-select**: When `onSelect` is given, every shown row MUST be a button, full width of the list, with left-aligned content.
- **select-reports-name**: Activating a row button MUST call `onSelect` once with that item's `name`, including when that row is already the selected one.
- **pressed-state-exposed**: Each row button MUST expose a pressed state that is true exactly when `selected` equals the item's `name`.
- **dim-unselected-rows**: While `selected` is not null, every row button whose name differs from `selected` MUST render at 55% opacity; while `selected` is null no row MUST be dimmed.
- **focus-ring**: A row button or the expand button that receives keyboard focus MUST show a 2px ring in the gold accent at 40% opacity, with the browser's default outline removed.
- **expand-state-local**: The component MUST keep the expanded or collapsed state itself, starting collapsed, and MUST NOT reset it when `items` changes.
- **class-name-target**: `className` MUST be applied to the component's outermost element, and to the empty-state element when `items` is empty.

## Appearance

- **Layout**: A vertical stack with 8px (`gap-2`) between rows; the root and each row can shrink below content width (`min-w-0`) so long names wrap instead of widening the list.
- **Name**: Monospace, 11px, muted text color (`text-apt-text-muted`), wraps with `overflow-wrap: anywhere`.
- **Value**: Monospace, 11px, semibold, full text color (`text-apt-text`), does not shrink; aligned to the first baseline of the name (`items-baseline`) with an 8px gap from it.
- **Bar**: 6px tall track (`h-1.5`) with a 4px top margin; the fill is the full track height, rounded on its right corners only (`rounded-r`), coloured by `color`, 2px minimum width when the value is greater than zero.
- **Selectable row**: Block-level button, full width, small corner radius (`rounded-sm`), pointer cursor, no default outline; a 2px gold ring at 40% opacity on keyboard focus.
- **Dimmed row**: 55% opacity on every row except the selected one while a selection exists.
- **Expand button**: Monospace, 10px, muted text color, underlined with a 2px underline offset, no padding, 8px top margin, text becomes full text color on hover, same focus ring as a row.
- **Empty state**: Monospace, 12px (`text-xs`), dim text color (`text-apt-text-dim`).
- **Min/Max size**: None. The width is whatever the parent gives it.

## States

| State | Appearance change |
|-------|------------------|
| Default (no `onSelect`) | Plain text rows with bars; no row is interactive |
| Selectable | Each row is a button; cursor is a pointer; no row dimmed while `selected` is null |
| Selected | The row whose name equals `selected` is pressed and full opacity; all other rows are at 55% opacity |
| Hover | Not applicable for rows: the source defines no hover style on a row button. The expand button's text moves from muted to full text color |
| Focused (keyboard) | 2px gold ring at 40% opacity around the row button or the expand button |
| Pressed (active) | Not applicable: the source defines no `:active` style for any element |
| Disabled | Not applicable: neither a row button nor the expand button has a disabled state in source |
| Loading | Not applicable: the component receives all data as props and has no loading state |
| Collapsed overflow | The first `maxItems` rows; expand button reads "Show all N" and reports not expanded |
| Expanded overflow | All rows; expand button reads "Show fewer" and reports expanded |
| Empty | Only the `emptyLabel` text; no list and no button |

## Accessibility

- **list-semantics**: The rows MUST sit in a list whose accessible name is `ariaLabel`, which the source documents as saying what is being ranked.
- **value-in-text**: The value MUST be available as text in the row because the bar is hidden from assistive technology.
- **row-button-name**: A selectable row's accessible name comes from its visible content: the name followed by the value text.
- **pressed-announced**: A selectable row MUST announce its toggle (pressed) state; the expand button MUST announce its expanded state.
- **keyboard-operation**: Row buttons and the expand button are native buttons, so Tab reaches each and Enter or Space activates it; rows are not focusable at all without `onSelect`.
- **focus-ring-visible**: A keyboard-focused button MUST show the focus ring described under **focus-ring**.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. No minimum target is set: a row button's height is its 11px text plus a 4px gap and a 6px bar, and the expand button has 10px text with no padding. Settling it needs the rendered pixel height at the production theme's line height and a decision on whether the platform minimum (44x44 CSS px per the Apple HIG, 24x24 CSS px per WCAG 2.2) applies to a dense data list.
- **contrast-ratio**: NEEDS REVIEW: Not implemented in source. Text and bar colors are theme tokens (`text-apt-text-muted`, `text-apt-text`, `text-apt-text-dim`, `--color-apt-cat-blue`) and the dimmed state lowers a row to 55% opacity; whether any theme meets 4.5:1 for 10px and 11px text, and 3:1 for the bar, needs measured token values per theme.

## Conformance Test Vectors
All 24 vectors are tested in the `BarList` block of `src/__tests__/trendChart.test.tsx`, one `it` per vector with the vector id at the start of its title; the items US 100, SG 50, CN 10 are the shared fixture. jsdom computes no layout or Tailwind styles, so the opacity vectors check the `opacity-55` class and the bar vectors check the inline `width` and `min-width` styles.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| bl-001 | initial-row-limit, expand-control-presence, expand-opens-in-place, expand-label, expand-collapse (test: opens what it leaves out, and closes it again) | The three items, `maxItems=2`; read; click "Show all 3"; click "Show fewer" | CN is absent; after "Show all 3" CN is present; after "Show fewer" CN is absent again |
| bl-002 | expand-control-presence (test: offers nothing to open when every row fits) | The three items, `maxItems=Infinity`, no `onSelect` | CN is present; the document has no button |
| bl-003 | name-wraps (test: lets a long name wrap rather than cutting it off) | One item named `/a/very/long/path/that/would/not/fit/in/a/narrow/panel`, value 1 | The name element's class list does not contain `truncate` |
| bl-004 | rows-plain-without-select (test: is plain text until it can do something) | The three items, default `maxItems`, no `onSelect` | The document has no button |
| bl-005 | rows-are-buttons-with-select, select-reports-name, pressed-state-exposed (test: reports the row chosen, and marks it) | The three items, `selected="SG"`, an `onSelect` that records its argument; click the US row | The SG row button has `aria-pressed` true; `onSelect` was called with "US" |
| bl-006 | row-order | Items [CN 10, US 100, SG 50] | Rows read CN, US, SG, top to bottom |
| bl-007 | list-accessible-name | `ariaLabel="Top countries"`, the three items | The list's accessible name is "Top countries" |
| bl-008 | row-value-text, default-value-format | Items [{A, 9999}, {B, 12500}], no `formatValue` | Value texts read "9,999" and "12.5K" |
| bl-009 | detail-replaces-value | Item {A, 5, detail "12 issues · 340 events"}, a `formatValue` that records calls | The row shows "12 issues · 340 events"; `formatValue` was not called for that row |
| bl-010 | detail-replaces-value (empty string) | Item {A, 5, detail ""} | The value text is empty; the formatted value "5" is not shown |
| bl-011 | bar-length-proportional | Items [US 100, SG 50, CN 10] | Bar widths 100%, 50%, 10% |
| bl-012 | bar-length-proportional (hidden row counts) | Items [US 100, SG 50, CN 10], `maxItems=1` | The one shown row's bar is 100%; after opening, SG is 50% (the maximum was never computed from the shown rows only) |
| bl-013 | bar-zero-maximum | Items [A 0, B 0] | Both bars have width 0% |
| bl-014 | bar-minimum-width | Items [US 100000, CN 1] | The CN bar has a 2px minimum width |
| bl-015 | bar-minimum-width (zero) | Items [US 100, ZZ 0] | The ZZ bar has a minimum width of 0 |
| bl-016 | bar-color | `color` omitted; then `color="red"` | Bars use `var(--color-apt-cat-blue)`; then red |
| bl-017 | bar-decorative | Any non-empty list | Each bar's wrapper has `aria-hidden` true |
| bl-018 | empty-state | `items=[]`, `emptyLabel` omitted; then `emptyLabel="No referrers"` | "Nothing to show." with no list and no button; then "No referrers" |
| bl-019 | dim-unselected-rows | `onSelect` given, `selected="SG"` | US and CN row buttons are at 55% opacity; SG is not |
| bl-020 | dim-unselected-rows (no selection) | `onSelect` given, `selected` omitted | No row button is dimmed; all have `aria-pressed` false |
| bl-021 | expand-state-exposed | Collapsed, then expanded | Expand button `aria-expanded` is false, then true |
| bl-022 | expand-state-local | `maxItems=2`, expand, then rerender with a different `items` array of 3 items | The list still shows every item, and the button still reads "Show fewer" |
| bl-023 | class-name-target | `className="x"`, with items; then with `items=[]` | The outermost element carries "x" in both cases |
| bl-024 | select-reports-name | The SG row is already selected; click the SG row | `onSelect` is called once with "SG" |

## Edge Cases

- **Empty items**: `items=[]` renders only the empty label (default "Nothing to show.") and no list; the component MUST NOT throw on the empty maximum. See bl-018.
- **All values zero or below**: When the largest value is 0 or less, every bar is 0% wide. See bl-013.
- **Negative value**: The source does not clamp or validate values. A negative value gets a negative percentage width string (its value divided by the largest value, times 100) and no minimum width, and its value text shows the formatted negative number; when the largest value is 0 or less every bar is 0% (see `bar-zero-maximum`). The values are counts per the `formatCount` comment in the trend chart block, so a negative value is outside what the component is given.
- **Large and small values**: The 2px floor applies only when the percentage width computes to less than 2px of the track, so where it starts depends on the track width, which the source does not fix (on a 300px track, below about 0.67% of the maximum); a value of exactly zero gets no floor. See bl-014 and bl-015.
- **Duplicate names**: Rows are keyed by `name` and selection is matched by `name`, so two items with the same name share a React key and are both pressed together. The component MUST NOT be given duplicate names; the source does nothing to prevent it.
- **Selected name not in the list**: A non-null `selected` that matches no item leaves every row dimmed at 55% and none pressed. The component does not clear or validate it.
- **`maxItems` boundaries**: Equal to the item count shows every row and no button; `Infinity` never shows a button (see bl-002); 0 shows no rows and a "Show all N" button while items exist; a negative value is passed to a slice from the start, so it hides that many rows from the end and still shows the button.
- **Expanded then shrunk**: If the list is expanded and `items` later shrinks to `maxItems` or fewer, the button disappears but the expanded flag stays true, so a later growth reopens already expanded. See bl-022.
- **Empty detail string**: `detail=""` is shown as an empty value, not replaced by the formatted value, because only null or undefined fall back. See bl-010.
- **Very long name**: Wraps, breaking inside a word if needed; never truncated. See bl-003.
- **Concurrent access**: Not applicable: the component is a synchronous render of props with one local boolean, and holds no shared mutable state.
- **Error states and offline**: Not applicable: the component makes no network or storage calls; data and any failure to obtain it belong to the host.
- **Repeated activation**: Each activation of a row calls `onSelect` once; there is no debounce and the component never toggles the selection off itself, so the host decides what a second activation means. See bl-024.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `readonly BarListItem[]` | (required) | Rows in display order. Each item has `name: string`, `value: number` and optional `detail: string` that replaces the formatted value. |
| `ariaLabel` | `string` | (required) | Says what is being ranked, for a screen reader. |
| `color` | `string` | `var(--color-apt-cat-blue)` | Any CSS color; normally a theme token. Fills every bar. |
| `formatValue` | `(value: number) => string` | the trend chart block's count formatter | Turns a value into the text shown beside the name. |
| `maxItems` | `number` | `8` | Rows shown at first; a button beneath opens the rest. |
| `onSelect` | `(name: string) => void` | `undefined` | When given, each row becomes a button that calls it with the row's name. |
| `selected` | `string \| null` | `null` | The name of the selected row; drives the pressed state and the dimming of other rows. |
| `emptyLabel` | `string` | `"Nothing to show."` | Text shown when `items` is empty. |
| `className` | `string` | `undefined` | Extra classes for the outermost element and the empty-state element. |

## Deep Linking

Not applicable: BarList is an inline display block and reads or writes no URL or route; selection is reported through `onSelect` for the host to use.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `bar_list.show_all` | "Show all {count}" | Expand button while collapsed; `{count}` is the total number of items |
| `bar_list.show_fewer` | "Show fewer" | Expand button while expanded |
| `bar_list.empty` | "Nothing to show." | Default `emptyLabel` (overridable by the host) |

The two button strings are hardcoded English with no override prop. The default value formatter fixes the English locale, so digit grouping and compact suffixes do not follow the user's locale unless the host passes `formatValue`. `ariaLabel`, `name`, `detail` and `emptyLabel` are host-supplied and are the host's to translate. The name's `overflow-wrap: anywhere` and the left-aligned layout use no physical-direction logic beyond `text-left` on a selectable row and `rounded-r` on the bar fill, so a right-to-left layout would still align the row to the left and round the right end of the bar.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source defines no animation or transition on any element. |
| Increase Contrast | Not handled: the component has no contrast-preference branch; contrast depends on the theme tokens named under Accessibility. |
| Differentiate Without Color | Selection is carried by the pressed state and by dimming the other rows, not by hue; the bar's meaning is repeated in the value text. The bar color itself carries no meaning beyond the host's choice of `color`. |

## Feature Flags

Not applicable: the source has no flag lookup; whether BarList appears is the host's concern.

## Analytics

Not applicable: the source emits no events; a host that wants selection or expansion analytics instruments `onSelect` itself, and the expand toggle reports nothing outward.

## Privacy

- **Data collected**: None. The component displays names and values it is given.
- **Storage**: None. The only state is an in-memory expanded flag.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the source performs no logging.

## Platform Notes

- **SwiftUI**: Source platform is web, so this is translation guidance. Build each row as a `VStack(alignment: .leading, spacing: 4)` holding an `HStack(alignment: .firstTextBaseline)` of a `Text(name)` (allow wrapping, `lineLimit(nil)`, `layoutPriority(0)`) and a `Text(value)` with `fixedSize(horizontal: true, vertical: false)` so it never shrinks, then a bar drawn with `GeometryReader` or an `overlay` using `scaleEffect(x:anchor: .leading)`. Mark the bar `accessibilityHidden(true)`. For `onSelect`, wrap the row in a `Button` with `.buttonStyle(.plain)` and add `.accessibilityAddTraits(.isSelected)` for the selected row, because SwiftUI has no pressed-toggle trait on a plain button; use `Toggle` with a custom `ToggleStyle` if a true toggle role is wanted. Swift Charts `BarMark` is an alternative only when the label-above layout is not required.
- **Compose**: Use a `Column` (or `LazyColumn` when the list is long) with one `Column` per row: a `Row` with `Text(name, modifier = Modifier.weight(1f, fill = false))` and `Text(value)`, then a `Box` bar using `Modifier.fillMaxWidth(fraction).height(6.dp).defaultMinSize(minWidth = 2.dp)`. Hide the bar with `Modifier.clearAndSetSemantics {}`. Make selectable rows `Modifier.toggleable(value = selected == name, role = Role.Button, onValueChange = ...)` so TalkBack reads the toggle state, and apply `Modifier.alpha(0.55f)` to unselected rows. Keep the expand control a `TextButton` with `Modifier.semantics { stateDescription }` for expanded state.
- **React/Web**: `packages/web/packages/ui/src/blocks/bar-list.tsx`. A client component (`"use client"`) using `useState` for the expanded flag; classes come from the app's `apt-*` Tailwind tokens and the `cn` helper; the default formatter `formatCount` is imported from `./trend-chart`. Rows are rendered through an internal `Row` component that is shared by the plain and button variants. The list is a `ul` with `list-none`, rows are `li`, and selectable rows use `button` with `aria-pressed`; the expand control uses `aria-expanded`. There is a test block for it in `trendChart.test.tsx`.
- **AppKit / UIKit**: On iOS use a vertical `UIStackView` per row (a horizontal name and value stack over a thin `UIView` bar whose width constraint is a multiplier of the container), set the name label `numberOfLines = 0` and `lineBreakMode = .byCharWrapping` to break inside words, and mark the bar `isAccessibilityElement = false`. For selection use a `UIButton` with `.isSelected` toggled and `accessibilityTraits.insert(.selected)`; the expand control is a `UIButton` configured as a text button. On macOS use an `NSStackView` of `NSTextField` labels (wrapping, `usesSingleLineMode = false`) over an `NSView` bar layer, and `NSButton` with `setButtonType(.pushOnPushOff)` for selection; both platforms need explicit key-view-loop and focus-ring support (`focusRingType`).
- **WinUI 3**: Use an `ItemsRepeater` (or a `ListView` with `SelectionMode="None"`) inside a `StackPanel`; each row's `DataTemplate` is a `Grid` with two auto rows. Row 0 is a two-column `Grid` with a `TextBlock x:Name="Name"` (`TextWrapping="Wrap"`, `IsTextTrimmed` unused so nothing is clipped, `Style` a monospaced `Consolas` at 11px, `Foreground="{ThemeResource TextFillColorSecondaryBrush}"`) in a star column and a `TextBlock` for the value in an `Auto` column (`TextWrapping="NoWrap"`, `FontWeight="SemiBold"`). Row 1 is the bar: a two-column `Grid` whose columns are `{Binding Fraction}*` and `{Binding Remainder}*` star widths with a `Border` (`Height="6"`, `MinWidth="2"`, `CornerRadius="0,2,2,0"`, `Background` bound to the bar `Brush`) in the first, so the length tracks the available width without code behind; set `AutomationProperties.AccessibilityView="Raw"` on it to hide it from UI Automation. For `onSelect`, template the row inside a `ToggleButton` with `Style` re-templated to be borderless (`Background="Transparent"`, `HorizontalContentAlignment="Stretch"`), `IsChecked` bound to selected equality and a `Click` handler raising the selection; `ToggleButton` exposes the UI Automation Toggle pattern, which is the equivalent of `aria-pressed`. Dim unselected rows with `Opacity="0.55"` through a `VisualStateManager` state group (`Selected` and `Unselected`); the default `FocusVisualPrimaryBrush` and `FocusVisualSecondaryBrush` on a `Button` give the keyboard ring, so restyle them to the gold accent at 40% to match. The overflow control is a `HyperlinkButton` ("Show all N" / "Show fewer") whose state is exposed by implementing `IExpandCollapseProvider` in an `AutomationPeer`, or more simply by setting `AutomationProperties.Name` to the current label.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/bar-list.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The name and value sit together on one line from the left, with the bar beneath, instead of a label column beside the bar.
**Rationale**: The source comment explains that long names are the norm (paths, referrers, hostnames), and a label column would leave them truncated to nothing or crowding the bars out at phone width.
**Approved**: pending

**Decision**: Long names wrap, breaking inside a word, and rows past `maxItems` open in place rather than being cut or paged.
**Rationale**: The source comment states that "Nothing is hidden for good: a long name wraps, and the rows past the limit open in place"; the test "lets a long name wrap rather than cutting it off" asserts the name is not truncated.
**Approved**: pending

**Decision**: The bar length uses the maximum over all items, not over the shown items.
**Rationale**: The maximum is computed from `items` before the limit is applied, so expanding the list never rescales the rows already on screen. The source does not state a rationale in a comment; this follows from where the maximum is computed.
**Approved**: pending

**Decision**: A bar for a positive value has a 2px floor.
**Rationale**: The fill carries `minWidth: 2` when the value is greater than zero, so a very small value stays visible; the source gives no comment, and a zero value deliberately gets none.
**Approved**: pending

**Decision**: The component owns the expanded flag but not the selection.
**Rationale**: Selection is passed in (`selected`) and reported out (`onSelect`) so the host controls it, while the overflow toggle is purely local presentation. A consequence worth noting as technical debt: the expanded flag survives a change of `items`, as documented under Edge Cases.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Screen-reader, keyboard and semantic-markup pass because the component uses a labelled list, native buttons, `aria-pressed`, `aria-expanded` and an `aria-hidden` bar. Touch-target-size and contrast-ratio are partial because the source sets no minimum target and the token values live in the theme; the open questions on `touch-target-size` and `contrast-ratio` record what would settle them. The two string checks fail because "Show all N", "Show fewer" and the default empty label are English literals with no override for the buttons, and locale-aware-formatting is partial because the default formatter fixes the English locale though `formatValue` can replace it. Separation-of-concerns passes because data, ordering, selection and formatting all belong to the host. Unit-test-coverage passes: the `BarList` tests in `trendChart.test.tsx` cover all 24 vectors, including bar widths, the `detail` override, the empty state, the dimming and the expand state.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (trendChart.test.tsx, 24 of 24 vectors); unit-test-coverage now passed. |
