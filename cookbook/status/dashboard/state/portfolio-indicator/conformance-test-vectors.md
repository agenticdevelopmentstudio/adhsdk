
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| portfolio-001 | mapped-verdict, snapshot-null-not-stale | `snapshot: null`, `offline: false`, `blind: false`, board `{ indicator: "operational", problems: [] }` | `pillKey` is `"ok"`, `count` is `0` |
| portfolio-002 | unknown-when-no-board, count-no-board, board-null-trusted | `snapshot: null`, `offline: false`, `blind: false`, `board: null` | `pillKey` is `"unknown"`, `count` is `0` |
| portfolio-003 | unknown-when-offline, count-from-board | `offline: true`, board `{ indicator: "operational", problems: [p1] }` | `pillKey` is `"unknown"`, `count` is `1` |
| portfolio-004 | unknown-when-blind | `blind: true`, `offline: false`, board `{ indicator: "degraded", problems: [p1, p2] }` | `pillKey` is `"unknown"`, `count` is `2` |
| portfolio-005 | mapped-verdict | fresh snapshot, board `{ indicator: "degraded", problems: [p1, p2] }` | `pillKey` is `"warn"`, `count` is `2` |
| portfolio-006 | mapped-verdict | fresh snapshot, board `{ indicator: "outage", problems: [p1] }` | `pillKey` is `"down"`, `count` is `1` |
| portfolio-007 | unknown-when-snapshot-stale, snapshot-stale-rule | snapshot carrying the server's freshness verdict `{ state: "stale", asOf: T }`, board `{ indicator: "operational", problems: [] }` | `pillKey` is `"unknown"`, `count` is `0` |
| portfolio-008 | unknown-when-snapshot-stale, snapshot-stale-rule | snapshot carrying freshness verdict `{ state: "very-stale", asOf: T }`, board `{ indicator: "operational", problems: [] }` | `pillKey` is `"unknown"` |
| portfolio-009 | snapshot-stale-rule | snapshot carrying freshness verdict `{ state: "fresh", asOf: T }`, board `{ indicator: "operational" }` | `pillKey` is `"ok"` |
| portfolio-010 | snapshot-null-not-stale | snapshot carrying freshness verdict `{ state: "fresh", asOf: null }` (no probe yet), board `{ indicator: "operational" }` | `pillKey` is `"ok"` |
| portfolio-011 | snapshot-stale-rule, freshness-no-verdict | snapshot from a backend older than the freshness verdict (no `freshness` field), board `{ indicator: "operational" }` | No verdict is not fresh: `pillKey` is `"unknown"`, no error |
| portfolio-012 | snapshot-stale-rule, independent-feeds | snapshot carrying freshness verdict `{ state: "stale", asOf: T }`, `offline: false`, `blind: false`, board `{ indicator: "outage", problems: [p1] }` | The stale snapshot alone forces `pillKey` to `"unknown"` (not `"down"`); `count` is `1` |
| portfolio-013 | board-null-trusted, independent-feeds | The board state fed a board `{ indicator: "operational", problems: [] }` whose `freshness.staleAt` deadline passed 5,000 ms ago; Live Snapshot inert (`snapshot: null`, `offline: false`, `blind: false`) | `pillKey` is `"unknown"`, and the global panel sharing the same cache context shows "status unknown" |
| portfolio-014 | no-memoisation | Evaluate with board `{ indicator: "operational" }` (`pillKey` is `"ok"`), then re-evaluate with `board: null` | Second evaluation returns `pillKey` `"unknown"`, not `"ok"` |
| portfolio-015 | hook-signature, no-text-output | Any input | The returned object's own keys are exactly `pillKey` and `count` |

