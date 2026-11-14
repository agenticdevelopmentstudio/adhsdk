
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

