**Decision**: The client no longer derives the indicator; the server ships it.
**Rationale**: The module once held a problems-to-indicator operation that mirrored the server's indicator rule for filtered panes, pinned by a parity test. The server now ships the indicator and its environment-scoped twin (`scope`), so the client keeps only the wire-to-sign translation, and `board-types-parity.test.ts` still pins that map's keys to the server's indicator union.
**Approved**: pending

**Decision**: `INDICATOR_STATE` is the single wire-to-sign translation.
**Rationale**: One typed `Record<BoardIndicator, IndicatorState>` is exhaustive at compile time, and a key test catches a member removed from both union and map together.
**Approved**: pending

**Decision**: Derive the window caption from the board's own bounds instead of hardcoding "24h".
**Rationale**: The server owns `ACTIVITY_WINDOW_MS`; a hardcoded caption would keep stating the old figure after a server change, "a label that lies without anything failing". Days are used only for whole-day windows of 48h or more, so 47h is never rounded to a window nobody configured.
**Approved**: pending

**Decision**: Judge no row-level verdict on the client beyond the held-open lookup.
**Rationale**: Deploy counts were once tallied here; the server now ships `deployCounts`, the row `environment` and the `unresolved` verdict. The one remaining row helper, `stillUnresolved`, only looks up the problems the server named in `heldOpenBy` against the current board, because a paged-in or retained history row outlives the read that judged it.
**Approved**: pending

**Decision**: One `headlineFor` shared by the hero sign and the top-bar pill.
**Rationale**: Sharing the function makes it impossible for the two surfaces to word the same state differently.
**Approved**: pending

**Decision**: The real-environment deploy predicate was removed from the client.
**Rationale**: It excluded Vercel preview builds (which report `environment=null`) from the deploy tally, and had no client caller outside its own test while the server carried its own copy. The server now judges the rule and ships the row `environment`, so the duplicate is gone.
**Approved**: pending
