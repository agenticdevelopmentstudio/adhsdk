
**Decision**: The "status unknown" rule lives in one shared concept used by every portfolio-wide sign.
**Rationale**: Sharing the derivation keeps the "when is status unknown" rule in one place so the two signs can never disagree.
**Approved**: pending

**Decision**: Snapshot staleness and board staleness are separate unknown conditions.
**Rationale**: The live transport and the board poll fail independently, and either one alone going stale is real information the other can't stand in for.
**Approved**: pending

**Decision**: Portfolio Indicator trusts a null board and computes no board-staleness term of its own.
**Rationale**: Board staleness was moved into the board state, so a null board already covers both "never arrived" and "gone stale" by construction, the same way every other consumer of the board state now does; a second check here would be a consumer re-deriving a rule its input already applies.
**Approved**: pending

**Decision**: A null snapshot counts as fresh, not unknown.
**Rationale**: No live read yet is not evidence of trouble, so a healthy monitor is unaffected; the board, not the snapshot, is the thing that must have come back before a colour is claimed.
**Approved**: pending

**Decision**: `count` is taken from the board even when `pillKey` is `"unknown"`.
**Rationale**: The board's problem count is independent of the unknown test; callers decide whether to show a count beside an unknown glyph.
**Approved**: pending

**Decision**: Snapshot staleness is the server's verdict, not a client-side judgment.
**Rationale**: The server judges freshness from its own clocks and publishes it as `snapshot.freshness`, so the client is immune to clock skew and throttled timers, and the sign, the banner and every other consumer read one verdict. An earlier version compared two server timestamps on the client with a probe-cadence window; that rule moved to the server and the hook now only reads its answer.
**Approved**: pending

**Decision**: A snapshot with no freshness verdict reads as stale.
**Rationale**: No verdict is not "fresh": a backend older than the verdict cannot back a confident status claim, so the sign says unknown rather than a false green.
**Approved**: pending
