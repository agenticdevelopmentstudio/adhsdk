
- **Null/empty input** (MUST): there is always a child; construction requires one. A zero-sized or never-laid-out pane leaves the child at zero size within the pins; insets of zero are the default.
- **Boundary values** (MUST): nothing in source clamps or validates insets, so insets larger than the pane are handed to the layout system as they are. The side pins sit below required priority so a pane at zero width is legal (see `side-edges-yield`).
- **Set the backdrop before load** (MUST): doing so loads the view (see `backdrop-loads-view`), so the order of backdrop and insets assignment does not matter.
- **Appearance change** (MUST): a backdrop color that is dynamic is resolved when set and not re-resolved on a light or dark switch (see `backdrop-snapshot`).
- **Concurrent access** (MUST): confined to the UI thread; there is no cross-thread path.
- **Error states**: Not applicable: no I/O, no throwing operation; the only failure is the fatal error for archive construction.
- **Offline/disconnected state**: Not applicable: no networking.

