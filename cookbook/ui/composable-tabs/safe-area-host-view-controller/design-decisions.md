
**Decision**: The leading and trailing pins are below required priority, while the top and bottom pins are required.
**Rationale**: Per the source comment, the Conversations shelf does the same: a collapsing pane animates to zero width, and a required side edge is one the layout system has to break, loudly, to get there.
**Approved**: pending

**Decision**: The container clips to its bounds.
**Rationale**: Per the source comment, a shelf sliding in is narrower than its contents, and showing the part that fits is better than letting the rest spill over the panes.
**Approved**: pending

**Decision**: The backdrop is applied as a resolved color value and is not kept in step with appearance changes.
**Rationale**: The source writes the color's resolved value to the layer once; the component's owners re-apply it from the theme palette when the theme changes. A port that uses a theme-aware brush gets the same result without the re-apply.
**Approved**: pending

**Decision**: The host pins to the safe area per instance, not per window.
**Rationale**: Per the source comment (the `pinsToSafeArea` parameter), the child either starts below the titlebar or is given the whole height to place things itself, and that choice differs between panes of one window.
**Approved**: pending

