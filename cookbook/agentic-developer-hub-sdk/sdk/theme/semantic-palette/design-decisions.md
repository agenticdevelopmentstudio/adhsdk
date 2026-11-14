
**Decision**: Every role is resolved once at construction and kept in a dictionary.
**Rationale**: The source comment says the dimmed-text roles run an iterative, pow-heavy contrast loop, and paying that on each draw or theme-apply call is wasteful. Because the map derives only from `theme`, equality is unaffected.
**Approved**: pending

**Decision**: Derived roles that depend on another role use that role's derived value, not its overridden value.
**Rationale**: The source calls `derive` on the parent role directly. The effect is that overriding `accent` or `elevatedSurface` does not move `onAccentText`, `personaName`, `userBubble`, `sendButton` or `card`. The source does not state why; it may be an accident of the recursion, so a port that wants overrides to flow through would be a deliberate change.
**Approved**: pending

**Decision**: `card` is its own role though it derives to `elevatedSurface`.
**Rationale**: The source comment says a theme can then set cards apart from pane title bars and footers without changing the tone they always had.
**Approved**: pending

**Decision**: `declares(_:)` reads the overrides rather than checking whether the color is visible.
**Rationale**: The source comment says every role derives to some opaque color, so the presence of an element such as a bubble outline must be the theme's explicit decision, as in web where a missing stylesheet variable means no border rule.
**Approved**: pending

**Decision**: `thinkingDoneText` and `thinkingIdleText` are derived from a desaturated foreground and are separate roles from `timestampText`.
**Rationale**: The source comments say the grey carries the meaning of a settled turn, a fixed `#8a8a8a` fails on light themes, a monochrome terminal palette has no grey to borrow, and a phosphor-green idle line would look like a turn that never ends. The done line is dimmer than the idle line on purpose, matching web's extra `opacity: 0.75`.
**Approved**: pending

**Decision**: `identitySeriesColors` removes state colors outright instead of ranking them last.
**Rationale**: The source comment says a view that also colors by state spends accent, success, warning and danger on meaning, so reusing one for identity would misreport health.
**Approved**: pending

**Decision**: The reader's text scale is held beside the theme and multiplied at read time, and `scaled(by:)` clamps its factor.
**Rationale**: The source comment separates the designer's `sizeScale` (a property of the typeface) from the reader's preference, which must survive a theme change. Clamping stops a slider from producing zero-height layout. The product of repeated calls is not capped, which is a documented edge case.
**Approved**: pending

**Decision**: A theme's project colors are optional, and the active-pane outline has no override.
**Rationale**: The source comment says a theme that recolors `paneOutline` restyles the frame while the front pane must still stand out, so the active outline is always `accent`.
**Approved**: pending

