
- **arrangement-only**: The configuration MUST hold exactly one field, the pane arrangement: the front tab's split tree, carrying its shape and sizes.
- **arrangement-optional**: The arrangement MUST be optional; an absent arrangement means there is nothing to copy, and a window adopting such a configuration MUST leave its panes as they are.
- **no-edges**: The configuration MUST NOT carry the enabled tab edges or any other per-project choice, so adopting it can never make a Tab Bars choice for the adopting project.
- **immutable-value**: The configuration MUST be an immutable value, safe to pass across concurrency domains, so the window manager can read it from one window and hand it to another without either window referring to the other.
- **memberwise-construction**: The configuration MUST be constructible from an arrangement (present or absent) alone.
