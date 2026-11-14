
**Decision**: Keep the native adjustments in `BuiltInThemes+Native.swift` and apply them over the generated list rather than editing `BuiltInThemes+Web.swift`.
**Rationale**: The generated file is rebuilt from the web CSS and must not be hand-edited, and the web catalogue has no tokens for the native chrome (selection fill, cards, the project window's plane); a separate layer survives a generator re-run, as the file's own comment states.
**Approved**: pending

**Decision**: Dispatch on `theme.id` through a `switch` with a `default` that returns the theme unchanged.
**Rationale**: Ids are stable (persisted selections rely on them) while names and positions are not, and the default keeps every unadjusted theme exactly as generated.
**Approved**: pending

**Decision**: Move the selection to a cool slate with an amber `selectionEdge` line, and set `card` and `paneBackdrop` to `#17130f`.
**Rationale**: The generated chrome put the selection, the cards and the pane title bars on one warm grey-brown; separating them leaves the title bars as the only element on that grey, per the file's doc comment.
**Approved**: pending

**Decision**: Replace `project` wholesale with a `ThemeProjectOptions` carrying only `paneBackdrop`.
**Rationale**: `nil` for `highlightActivePane` and `paneOutline` leaves them to the Projects settings panel and the theme's outline tone, as `ThemeProjectOptions` documents; the side effect is that any value already in those two fields would be discarded. The generated Fishlamp theme sets no `project`, so nothing is lost today.
**Approved**: pending

**Decision**: No unit test asserts the adjusted Fishlamp values; the vectors above are derived from source and from the whole-list tests.
**Rationale**: The existing tests cover `all` as a whole (size, unique ids, ported membership) but none reads `selection`, `card`, `selectionEdge` or `project` of Fishlamp, so a change to those literals would pass the suite.
**Approved**: pending

