
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

