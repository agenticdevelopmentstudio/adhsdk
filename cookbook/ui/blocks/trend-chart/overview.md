
TrendChart draws a count over time: one value axis, a crosshair and tooltip that follow the pointer, a legend when more than one series is shown, and a "View as table" disclosure for anyone who cannot read the marks. It takes series colors as CSS values so a caller's series keep their hue when a filter changes which of them are shown.

It is dependency-free by design. The plot is an SVG stretched over its box (`preserveAspectRatio="none"` with non-scaling strokes), and everything that must not stretch (tick labels, dots, the tooltip) is HTML positioned by percent over it. That keeps the chart fluid without measuring anything, so it needs no ResizeObserver and renders the same on the server.

The module also exports three pure helpers, `formatCount`, `niceTicks` and `axisLabelIndexes`, which carry the numeric rules below.

