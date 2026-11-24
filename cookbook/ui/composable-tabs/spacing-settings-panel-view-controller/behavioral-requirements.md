
### Identity

- **panel-title**: The panel MUST present itself with the title "Spacing".
- **panel-icon**: The panel MUST present itself with the rectangle-split-three-columns system symbol and no accessibility description on that symbol.
- **search-keywords**: The panel MUST offer exactly these keywords to the settings search, in this order: spacing, frame, divider, gutter, pane, padding, margin, terminal, project, partner.
- **search-before-open**: The keywords MUST be available before the panel has ever been opened, because the sidebar search only reads the controls of a panel that has been opened.

### Groups

- **three-groups**: The panel MUST contain exactly three groups, in this order: "Frame Spacing", "Pane Divider Spacing", "Pane Content Spacing".
- **one-control-per-group**: Each group MUST contain exactly one spacing control.
- **frame-bound**: The Frame Spacing control MUST be a frame-style control bound to the four app-wide frame edge settings (top, leading, bottom, trailing).
- **divider-bound**: The Pane Divider Spacing control MUST be a pane-divider-style control bound to the two app-wide gutter settings (between columns, between rows).
- **content-bound**: The Pane Content Spacing control MUST be a frame-style control bound to the four app-wide pane content edge settings (top, leading, bottom, trailing).
- **groups-build-on-load**: The panel MUST build its groups when its view loads, not at construction.
- **live-apply**: A change made in any of the controls MUST apply to every window as the reader makes it, with no confirm step.
- **no-local-store**: The panel MUST NOT hold spacing values of its own; the controls read and write the app-wide settings through their bindings.

### Accessibility identifiers

- **frame-identifier**: The Frame Spacing control MUST carry the accessibility identifier `settings.spacing.frame`.
- **divider-identifier**: The Pane Divider Spacing control MUST carry the accessibility identifier `settings.spacing.dividers`.
- **content-identifier**: The Pane Content Spacing control MUST carry the accessibility identifier `settings.spacing.content`.

### Keyboard order

- **tab-frame-to-dividers**: Tab out of the last number field of the Frame Spacing control MUST move to the first number field of the Pane Divider Spacing control.
- **tab-dividers-to-content**: Tab out of the last number field of the Pane Divider Spacing control MUST move to the first number field of the Pane Content Spacing control.
- **shift-tab-reverse**: Shift-Tab MUST walk the same chain in the other direction, because linking the next key view sets the back link too.
- **tab-join-after-build**: The panel MUST join the Tab order after all three groups are built.
- **tab-ends-unjoined**: The panel MUST NOT link a key view out of the last number field of the Pane Content Spacing control, nor into the first number field of the Frame Spacing control; those hand-offs are the platform's.

### Help

- **help-topics**: The panel MUST offer exactly four help topics, titled "Frame Spacing", "Pane Divider Spacing", "Pane Content Spacing" and "Everywhere", in that order.
- **help-frame-body**: The Frame Spacing topic MUST say that the spacing is the room between the panes and the tab bars framing them, in points, set per side, and that an arrow pointing into the view adds space.
- **help-divider-body**: The Pane Divider Spacing topic MUST say that each number is the whole gap and not each pane's half, and that a gap of zero still drags because the divider keeps a few points of grab area.
- **help-content-body**: The Pane Content Spacing topic MUST say that a theme's own terminal padding wins for terminals when the theme carries one.
- **help-everywhere-body**: The Everywhere topic MUST say that spacing belongs to the app, not to a window, and that changes apply to all windows as they are made.

### Lifetime and isolation

- **no-archive-init**: The panel MUST NOT support construction from an archive.
- **ui-thread-confined**: The panel MUST be used on the UI thread only.

