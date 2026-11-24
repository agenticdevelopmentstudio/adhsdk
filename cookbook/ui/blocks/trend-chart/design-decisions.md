
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

