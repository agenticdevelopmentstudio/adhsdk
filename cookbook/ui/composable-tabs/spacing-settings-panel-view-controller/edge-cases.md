
- **Null/empty input** (MUST): the panel takes no input; the groups bind to settings that always have defaults, and a bound control refuses to build with an empty settings map (the control's own precondition), so a panel cannot show controls that edit nothing.
- **Boundary values** (MUST): the panel imposes none; each control's range of 0 through 40 points applies. A gap of zero still drags, per the help text.
- **Panel not yet opened** (MUST): the sidebar search sees only the panel's keywords until the view loads (see `search-before-open`).
- **Tab out of the last field** (MUST): control passes to the platform's own key view loop, which is not guaranteed to be meaningful for frame-placed views (see Design Decisions).
- **Theme padding for terminals** (MUST): a theme that carries its own terminal padding overrides the Pane Content Spacing values for terminals only (see `help-content-body`); the panel does not show that override.
- **Concurrent access** (MUST): confined to the UI thread.
- **Error states**: Not applicable: no I/O or throwing operation beyond the controls' own bindings.
- **Offline/disconnected state**: Not applicable: no networking.

