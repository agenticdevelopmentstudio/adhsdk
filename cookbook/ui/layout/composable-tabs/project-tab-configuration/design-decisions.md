
**Decision**: The shared configuration carries the pane arrangement only and never the enabled tab edges.
**Rationale**: A project's edges are its own explicit Tab Bars choice, or the app-wide tab positions when it has made none. Carrying edges from the last-active window would write that window's edges into every project the user switches to, turning the app-wide default into a per-project choice nobody made (`principle-of-least-astonishment`).
**Approved**: pending

**Decision**: A value type passed by the window manager rather than one window reading another directly.
**Rationale**: Neither window needs to know the other exists; the manager reads the value out of one and hands it to the next (`dependency-injection`).
**Approved**: pending
