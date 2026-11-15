---
id: 1109f2ef-a36d-4d6d-a57d-83dc08ce7b20
title: "TrendChart"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Dependency-free line or bar chart of a count over time, with crosshair tooltip, legend, gap handling and a table view."
platforms:
  - typescript
  - web
tags:
  - chart
  - data-visualization
  - analytics
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# TrendChart

## Overview

TrendChart draws a count over time: one value axis, a crosshair and tooltip that follow the pointer, a legend when more than one series is shown, and a "View as table" disclosure for anyone who cannot read the marks. It takes series colors as CSS values so a caller's series keep their hue when a filter changes which of them are shown.

It is dependency-free by design. The plot is an SVG stretched over its box (`preserveAspectRatio="none"` with non-scaling strokes), and everything that must not stretch (tick labels, dots, the tooltip) is HTML positioned by percent over it. That keeps the chart fluid without measuring anything, so it needs no ResizeObserver and renders the same on the server.

The module also exports three pure helpers, `formatCount`, `niceTicks` and `axisLabelIndexes`, which carry the numeric rules below.

## Behavioral Requirements

- **empty-state**: The component MUST render only the empty label, in a box of the configured height, when `labels` is empty or when no non-null value exists in the shown series.
- **empty-label-default**: The empty label MUST default to "No data in this range." when `emptyLabel` is not given.
- **all-null-is-empty**: A series whose values are all null MUST be treated as no data, not as a flat zero.
- **single-series-for-bars**: When `variant` is `bars`, the component MUST draw and report only the first series and ignore the rest.
- **default-variant**: `variant` MUST default to `line`.
- **default-height**: The plot height MUST default to 200 pixels and apply to both the tick column and the plot.
- **null-is-gap**: A null value MUST be a gap: the line breaks at it and does not drop to zero.
- **run-segmentation**: Each run of consecutive non-null values MUST be drawn as its own polyline with a 2-unit non-scaling round stroke in the series color.
- **lone-point-dot**: In the line variant, a run containing exactly one point MUST be drawn as a dot, because it has no line to be seen on.
- **single-series-fill**: In the line variant, a run of two or more points MUST get a fill of the series color at 10 percent only when exactly one series is shown.
- **bar-null-height**: In the bars variant, a null value MUST draw a bar of zero height.
- **bar-geometry**: Bars MUST be at most 24 pixels wide, have rounded top corners, and be spread evenly across the plot with a 2-pixel gap.
- **y-ticks**: The value axis MUST show ticks from zero to a value at or above the largest plotted value, labelled with `formatCount` regardless of `formatValue`.
- **tick-step**: Tick steps MUST be on a 1, 2 or 5 times a power of ten and MUST NOT be below 1.
- **tick-lines**: A horizontal gridline MUST be drawn at every tick; the zero line MUST be fully opaque and the others 50 percent opaque.
- **x-position-line**: In the line variant, label `i` of `n` MUST sit at `i / (n - 1)` of the plot width, or at 50 percent when `n` is 1.
- **x-position-bars**: In the bars variant, label `i` of `n` MUST sit at `(i + 0.5) / n` of the plot width.
- **axis-labels**: The category axis MUST show at most five labels, at a constant whole-bucket step counted back from the newest bucket, and every bucket when there are five or fewer.
- **axis-label-anchor**: An axis label positioned below 8 percent MUST anchor at its left edge, one above 92 percent at its right edge, and the rest at their center.
- **axis-label-format**: Axis labels MUST be formatted with `formatLabel`, which MUST default to the identity.
- **detail-format**: Tooltip and table row labels MUST be formatted with `formatDetail`, which MUST default to `formatLabel`.
- **value-format**: Tooltip and table values MUST be formatted with `formatValue`, which MUST default to `formatCount`.
- **format-count**: `formatCount` MUST return the full grouped number below 10,000 in magnitude and a compact form with at most one fraction digit from 10,000 up.
- **pointer-tracking**: The component MUST update the hovered bucket on pointer move and pointer down over the plot, and clear it on pointer leave.
- **pointer-line-resolution**: In the line variant, the pointer MUST resolve to the nearest bucket by rounding the clamped horizontal fraction times `n - 1`.
- **pointer-bar-resolution**: In the bars variant, the pointer MUST resolve to the band containing it, never beyond the last bucket.
- **pointer-zero-width**: A pointer event MUST be ignored when the plot box has zero width.
- **crosshair**: In the line variant with a hovered bucket, the component MUST draw a vertical line and a dot per series at that bucket, skipping series whose value there is null.
- **bar-dimming**: In the bars variant with a hovered bucket, bars other than the hovered one MUST be drawn at 55 percent opacity.
- **tooltip-content**: With a hovered bucket, a tooltip MUST show the detail label and, for every shown series, its color swatch, name and formatted value, with an em dash for null.
- **tooltip-side**: The tooltip MUST sit 10 pixels right of the hovered bucket's horizontal position, and 10 pixels left of it when that position is beyond 55 percent of the plot width.
- **tooltip-no-capture**: The tooltip, crosshair and dots MUST NOT intercept pointer events.
- **legend-threshold**: A legend list MUST be rendered only when more than one series is shown.
- **table-view**: A collapsed "View as table" disclosure MUST list every label as a row header and every shown series as a column, with an em dash for null.
- **table-caption**: The table MUST carry `ariaLabel` as a screen-reader-only caption.
- **figure-label**: The root MUST be a figure labelled with `ariaLabel`.
- **decoration-hidden**: Ticks, gridlines, plot marks, crosshair, dots and axis labels MUST be hidden from assistive technology.
- **touch-scroll**: The plot MUST allow vertical touch panning.
- **class-passthrough**: `className` MUST be merged onto the root, or onto the empty-state box when empty.
- **ssr-safe**: The component MUST be a client component and MUST NOT measure layout during render.

## Appearance

- **Corner radius**: Bars have rounded top corners; the tooltip is `rounded-md`; dots and legend swatches are round.
- **Padding**: Tooltip 6 × 10 pixels; table cells 4 × 8 pixels; the value-axis column is 40 pixels wide with an 8-pixel gap to the plot.
- **Font**: Monospace throughout. Tick and axis labels 10 pixels; tooltip, legend and table 11 pixels; empty label `text-xs`. Tooltip values are semibold.
- **Background**: Transparent plot. Tooltip uses the `apt-surface` token. Series colors come from the caller as CSS values.
- **Foreground/Text**: Ticks, axis labels and tooltip date in `apt-text-dim`; series names in `apt-text-muted`; tooltip values in `apt-text`.
- **Border**: Gridlines use the `apt-border` token, 1 pixel; the tooltip has a 1 pixel `apt-border`.
- **Shadow**: Tooltip uses `shadow-md`. Each dot has a 2-pixel ring in `--color-apt-surface` so it reads where it crosses another line.
- **Min/Max size**: Plot height is the `height` prop (default 200). Tooltip is at most 220 pixels wide. Bars are at most 24 pixels wide. The table region scrolls beyond 14rem (`max-h-56`). The legend and table are indented 48 pixels to align with the plot.

## States

| State | Appearance change |
|-------|------------------|
| Default | Axis, gridlines, series and (for several series) legend; table collapsed |
| Empty | Only the centered empty label |
| Hover or touch | Tooltip; in line variant a crosshair and dots; in bars variant the other bars dim to 55 percent |
| Table open | The table appears under the legend |
| Pressed | Not applicable: pointer down is handled the same as pointer move, so touch shows the same tooltip as hover. |
| Disabled | Not applicable: the component has no disabled prop and is read-only. |
| Focused | Not applicable: the plot is not focusable; only the table disclosure takes focus, with the browser default. |
| Loading | Not applicable: the component takes finished data and has no loading prop. |

## Accessibility

- **role**: The root is a figure labelled by `ariaLabel`; the tooltip has the `status` role; the legend is a list; the table has a caption, column headers and row headers.
- **labels**: `ariaLabel` is required and names what the chart shows; it is also the table caption.
- **non-visual-access**: All visual marks are hidden from assistive technology; the table view carries every value and is the non-visual path.
- **color-independence**: The legend and tooltip pair each color with the series name, and the table is the color-free view.
- **reduced-motion**: Not applicable: the component has no animation or transition.
- **keyboard-hover-access**: NEEDS REVIEW: Not implemented in source. The tooltip and crosshair open only from pointer events, so keyboard users reach the values only through the table disclosure; a keyboard path over the plot, or acceptance that the table suffices, would settle it.
- **contrast**: NEEDS REVIEW: Not implemented in source. Series colors are caller supplied and dim text uses theme tokens at 10 and 11 pixels; contrast measurements of the tokens against the page background would settle whether the ratio is met.
- **touch-target**: The `View as table` summary is a text line 11 pixels tall with no minimum target size set in source; the plot's touch-pan-y lets vertical scroll pass through.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| trend-chart-001 | empty-state, empty-label-default | `labels` empty, `series` empty (test "says so when there is nothing to plot") | The text "No data in this range." is shown |
| trend-chart-002 | all-null-is-empty | One series with values null, null, null over three labels (test "treats an all-null series as no data") | The empty label is shown, no plot |
| trend-chart-003 | legend-threshold | One series, then two series (test "names series in a legend only when there are two to tell apart") | No list for one series; a list containing "two" for two |
| trend-chart-004 | null-is-gap, run-segmentation | Values 1, 2, null, 4 (test "breaks the line at a null") | Two polylines |
| trend-chart-005 | pointer-tracking, pointer-line-resolution, tooltip-content | Values 10, 20, 30; plot 100 wide; pointer at x 100 (test "shows the value under the pointer") | Status tooltip contains "c" and "30" |
| trend-chart-006 | single-series-for-bars, pointer-bar-resolution | Variant bars, values 10, 20, 30; pointer at x 50 (test "resolves the pointer to a band") | Status tooltip contains "20" |
| trend-chart-007 | table-view, null-is-gap | Values 10, null, 30 (test "carries every value in its table view") | Table text contains 10, an em dash and 30 |
| trend-chart-008 | tick-step, y-ticks | `niceTicks(487)`, `niceTicks(100)` (test "starts at zero and reaches past the maximum") | `[0, 200, 400, 600]` and `[0, 50, 100]` |
| trend-chart-009 | tick-step | `niceTicks(2)`, `niceTicks(1)`, `niceTicks(0)` (tests "never steps by a fraction", "gives a flat series an axis") | `[0, 1, 2]`, `[0, 1]`, `[0, 1]` |
| trend-chart-010 | axis-labels | `axisLabelIndexes(3)`, `(5)`, `(7)` (tests "labels every bucket", "keeps the gaps equal") | `[0, 1, 2]`, `[0, 1, 2, 3, 4]`, `[0, 2, 4, 6]` |
| trend-chart-011 | axis-labels | `axisLabelIndexes` for n of 6, 8, 14, 24, 30, 31, 90 | At most five indexes, last is `n - 1`, one constant step |
| trend-chart-012 | format-count | `formatCount(9999)` and `formatCount(26243)` (test "keeps every digit until there are too many to read") | "9,999" and "26.2K" |
| trend-chart-013 | pointer-zero-width | Plot box width 0, pointer move | No tooltip appears (derived from source; no test) |
| trend-chart-014 | tooltip-side | Hover a bucket whose position is beyond 55 percent of the plot width | Tooltip shifted left by its width plus 10 pixels (derived from source; no test) |

## Edge Cases

- **Empty labels or no data**: MUST render the empty label at the configured height (trend-chart-001, trend-chart-002).
- **Single label**: In the line variant the lone point MUST sit at 50 percent and be drawn as a dot, since a run of one has no line.
- **Series shorter than labels**: A missing value MUST be read as null: the tooltip and table show an em dash.
- **Series longer than labels**: Values beyond the last label are positioned past the right edge of the plot by the line variant (`i / (n - 1)` exceeds 100 percent and the SVG has `overflow-visible`), and they still count toward the axis maximum; in the bars variant a bar is drawn for each value with no label. This follows from the bar loop iterating the first series' values.
- **Zero maximum**: A series of zeros MUST get an axis of 0 and 1 (`niceTicks(0)`).
- **Negative values**: Not applicable: the contract is a count over time, tick generation starts at zero, and the source has no negative-value path.
- **Pointer outside the box**: The horizontal fraction MUST be clamped to 0 through 1, so the first or last bucket is chosen.
- **Hover index stale after data shrinks**: A hovered index at or beyond the label count MUST be treated as no hover.
- **Concurrent access**: Not applicable: the only state is the hovered index, owned by one React component instance.
- **Error states and offline**: Not applicable: the component takes data as props and makes no requests; there is no error path to handle.
- **Format callbacks that throw**: Not handled: the callbacks are called in render and a throw propagates.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `labels` | readonly string[] | required | One label per bucket |
| `series` | readonly TrendSeries[] | required | Name, CSS color and one value per label (null is a gap) |
| `ariaLabel` | string | required | Says what the chart shows |
| `variant` | `"line"` or `"bars"` | `"line"` | Bars draw the first series only |
| `height` | number | 200 | Plot height in pixels |
| `formatValue` | (number) => string | `formatCount` | Tooltip and table values |
| `formatLabel` | (string) => string | identity | Axis labels |
| `formatDetail` | (string) => string | `formatLabel` | Tooltip and table labels |
| `emptyLabel` | string | "No data in this range." | Shown when there is nothing to plot |
| `className` | string | none | Merged onto the root |

## Deep Linking

Not applicable: the component is a presentational chart with no routes or URLs.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `emptyLabel` | No data in this range. | Prop with a default |
| table toggle | View as table | Hard-coded, not a prop |
| table header | Period | Hard-coded, not a prop |
| missing value | — | Hard-coded em dash in tooltip and table |

Number formatting uses fixed `en` locale formatters in `formatCount`; callers localize through `formatValue`, `formatLabel` and `formatDetail`.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation or transition exists. |
| Increase Contrast | Not applicable: no media query is read; colors come from theme tokens and caller values. |
| Differentiate Without Color | The legend and tooltip name each series next to its swatch, and the table view shows values without color. |

## Feature Flags

Not applicable: the component reads no flags.

## Analytics

Not applicable: the component emits no events.

## Privacy

- **Data collected**: None.
- **Storage**: None; the hovered index is in-memory component state.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the component writes no logs.

## Platform Notes

- **SwiftUI**: Start from Swift Charts (`Chart` with `LineMark` and `BarMark`, `chartXSelection` for the crosshair, `RuleMark` for the vertical line). Null maps to a missing mark, which breaks the line. Provide `accessibilityChartDescriptor` and an equivalent table, since the source's table view is its non-visual path.
- **Compose**: Draw with `Canvas` in a `Box` sized by `height`, with `pointerInput` and `detectDragGestures` for the crosshair, and a `semantics` description. Break the path at null by starting a new `Path` segment. Tick labels and the tooltip are composables positioned by fraction of the measured size, which the web source avoids measuring.
- **React/Web**: Source is `packages/web/packages/ui/src/blocks/trend-chart.tsx`, a client component using an SVG with `viewBox` 0 0 100 100, `preserveAspectRatio="none"` and `vectorEffect="non-scaling-stroke"`, with HTML overlays for text and dots. Tests are in `packages/web/packages/ui/src/__tests__/trendChart.test.tsx` under jsdom, where the plot box width must be stubbed.
- **AppKit / UIKit**: Start from a custom `NSView` or `UIView` drawing with Core Graphics (or hosting Swift Charts), with `NSTrackingArea` or `UIPanGestureRecognizer` and `UIHoverGestureRecognizer` for the crosshair, and `accessibilityElements` plus an `NSTableView` or `UITableView` for the table view.
- **WinUI 3**: Compose a `Grid` with a `Canvas` hosting `Polyline` and `Polygon` shapes (`StrokeThickness` 2, `StrokeLineJoin` Round, `Stretch` set so the plot fills the cell), `Rectangle` elements for bars with a corner radius on the top edge via a `Path`, and `TextBlock` ticks in a left `ColumnDefinition` of 40. Track `PointerMoved`, `PointerPressed` and `PointerExited` on the plot grid and keep the hovered index in a view-model property; show the tooltip in a `Popup` or `TeachingTip`-style `Border` with `ThemeShadow`. Use `Expander` for "View as table" containing a `ListView` or `DataGrid` with row and column headers. Set `AutomationProperties.Name` to the label, hide marks with `AutomationProperties.AccessibilityView` set to Raw, and mirror the tooltip with a `LiveSetting` of Polite. Use `ThemeResource` brushes for text and borders. A charting library (WinUI Community Toolkit or LiveCharts2) is a heavier alternative; this source is deliberately dependency-free.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/trend-chart.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Draw the plot as a stretched SVG and put all text, dots and the tooltip in HTML positioned by percent.
**Rationale**: The source comment says this keeps the chart fluid with no measuring and no ResizeObserver, and renders the same on the server, while text and dots do not stretch.
**Approved**: pending

**Decision**: Treat null as a gap and an all-null series as no data.
**Rationale**: A null is "not a zero" per the prop comment; dropping to zero would invent data.
**Approved**: pending

**Decision**: Tick steps are never below 1.
**Rationale**: The source comment says these are counts, so a half tick names something that cannot happen.
**Approved**: pending

**Decision**: Axis labels step by a whole number of buckets from the newest, leaving the oldest end unlabelled when buckets do not divide evenly.
**Rationale**: Uneven gaps between dates (Oct 29, 31, Nov 1, 3, 4) read wrongly, per the source comment.
**Approved**: pending

**Decision**: Fill under the line only for a lone series.
**Rationale**: The source comment says two fills would muddy each other.
**Approved**: pending

**Decision**: Provide a table view as the non-visual path, and tooltip is pointer-driven.
**Rationale**: The component header names "a table view for anyone who cannot read the marks"; the source adds no keyboard handler on the plot, recorded as the open question on `keyboard-hover-access`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | internationalization |

The pure helpers and the main behaviors are separated from presentation, and `trendChart.test.tsx` carries one test per conformance vector, trend-chart-001 to trend-chart-014, all passing. The table view and figure label give screen-reader users the values, but the crosshair is pointer-only, so keyboard support is partial. Number formatting is fixed to the `en` locale inside `formatCount`, though callers can override every formatter, so locale-aware formatting is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (trendChart.test.tsx, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
