
Vectors 001–005 and 006 are traced to the module's own test suite and the board-types parity test; the rest to the operations' own bodies. `H` = 3,600,000 ms (one hour). The problems-to-indicator, deploy-counts and real-environment-deploy operations are no longer in the client (the server judges them and ships `scope`, `deployCounts` and the row `environment`), so they have no vectors here. The module's one row-judging helper is the still-unresolved operation.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overview-001 | indicator-map-exhaustive, indicator-map-values | Sorted keys of the wire-indicator translation map; its values | `["degraded","operational","outage"]`; `"warn"`, `"ok"`, `"down"` |
| overview-002 | window-hours, window-hours-label, window-days | The activity-window-caption operation on spans of `24H`, `7×24H` and `47H`, each from time `0` | `"24h"`; `"7d"`; `"47h"` |
| overview-003 | window-min-one-hour | The activity-window-caption operation on a span of `60000` ms, from time `0` | `"1h"` |
| overview-004 | window-days, window-hours-label | The caption operation on spans of `48H`, `72H` and `24H`, each from time `0` | `"2d"`; `"3d"`; `"24h"` (stays hours) |
| overview-005 | window-min-one-hour | The caption operation from time `10H` to time `0` (a negative span) | `"1h"` |
| overview-006 | headline-ok | The headline operation with sign state `"ok"` and count `5` | `"ALL SYSTEMS OPERATIONAL"` |
| overview-007 | headline-warn-singular, headline-warn-plural | The headline operation with sign state `"warn"` and count `1`; then count `3` | `"1 SERVICE NEEDS ATTENTION"`; `"3 SERVICES NEED ATTENTION"` |
| overview-008 | headline-down-singular, headline-down-plural | The headline operation with sign state `"down"` and count `1`; then count `4` | `"1 PROBLEM"`; `"4 PROBLEMS"` |
| overview-009 | unresolved-held-open | The still-unresolved operation on a deploy row with `unresolved: true` and `heldOpenBy: [S]`, with a problem on the row's target whose `since` is `S` | `true` |
| overview-010 | unresolved-held-open | The same row with no problems; with a problem on the same target with a different `since`; with a problem at `since` `S` on another target | `false` for all three |
| overview-011 | unresolved-in-flight, unresolved-no-held-open | A row with `unresolved: true`, tone `"progress"` and `heldOpenBy: []`, and a row with `unresolved: true` and no `heldOpenBy`, each against no problems | `true`, `true` |
| overview-012 | unresolved-server-verdict | A row with `unresolved: false` and `heldOpenBy: []` against a matching problem; a row with `unresolved` absent against a matching problem | `false`, `false` |
| overview-013 | pure-functions, no-throw | Call the headline operation, the caption operation and the still-unresolved operation twice on the same arguments, with the problems list and the row frozen | Same results both times; no exception; inputs unchanged |
