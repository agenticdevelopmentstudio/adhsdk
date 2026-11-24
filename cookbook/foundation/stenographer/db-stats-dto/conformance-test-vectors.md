
`DBStatsDTOConformanceTests` (Core test target) covers every vector, derived from the declarations.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| db-stats-dto-001 | pool-memberwise-init, pool-fields | `Pool(pool: "write", inFlight: 1, completed: 10, evicted: 2, p50Ms: 1.5, p99Ms: 9.0)` | each field reads back as given |
| db-stats-dto-002 | stats-memberwise-init, stats-fields | `DBStatsDTO(write: [a], read: [b, c])` | `write` has one pool and `read` has two, in order |
| db-stats-dto-003 | wire-keys | encode a stats value with one write pool | JSON has `write` and `read` arrays whose pool objects have keys `pool`, `inFlight`, `completed`, `evicted`, `p50Ms`, `p99Ms` |
| db-stats-dto-004 | wire-keys, conformance-protocols | decode the JSON from vector 003 | an equal field-for-field value |
| db-stats-dto-005 | stats-fields, empty-arrays-encoded | `DBStatsDTO(write: [], read: [])` | both arrays empty; encode and decode succeed, and the encoded JSON contains both keys as empty arrays |
| db-stats-dto-006 | no-validation | `Pool(pool: "", inFlight: -1, completed: 0, evicted: 0, p50Ms: 5, p99Ms: 1)` | constructs without error and keeps the values |
| db-stats-dto-007 | stats-fields | decode JSON that lacks the `read` key | decoding fails; both lists are required |

