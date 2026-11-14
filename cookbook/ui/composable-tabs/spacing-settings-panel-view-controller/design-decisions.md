
**Decision**: Spacing is split into three groups, each with its own control, instead of one diagram carrying all ten numbers.
**Rationale**: Per the source comment, the groups answer separate questions (room around the panes, between them, inside them), and one diagram carrying all of them made the reader work out which numbers were which.
**Approved**: pending

**Decision**: The panel offers no per-window or per-pane spacing; every window reads the one set of app-wide keys.
**Rationale**: Per the source comment (`dry`), there is exactly one answer to why a pane is spaced as it is, which no per-window control could keep true.
**Approved**: pending

**Decision**: The panel joins the Tab order of the three controls explicitly with next-key-view links.
**Rationale**: Per the source comment, each control answers Tab within itself and hands the key back at either end, and the platform works its key view loop out from where subviews are; these are placed by frame, so left alone Tab out of the bottom number went somewhere that looked like nowhere. Which control follows which is the panel's knowledge.
**Approved**: pending

**Decision**: The panel overrides the search keywords with a fixed list.
**Rationale**: Per the source comment, the sidebar's search only reads the controls of a panel that has been opened, so the panel names what it is about for searches made before anyone opens it.
**Approved**: pending

**Decision**: The panel's English strings are literals without localization lookup.
**Rationale**: No lookup exists in the source; this is recorded as the open question on `string-externalization` pending a localization policy for settings panels.
**Approved**: pending

