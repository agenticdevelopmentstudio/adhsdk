
Tests named below are in the `RouteTable` suite (`RouteTableTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| route-table-001 | first-claim-wins, declined-handlers-fall-through, later-handlers-skipped | Table of [declining handler, handler returning 201, handler returning 202]; `handle` a `GET /a` request. | The response has `status` 201 (test: theFirstNonNilHandlerWins). |
| route-table-002 | none-claims-is-nil | Table of two declining handlers, then an empty table; `handle` a `GET /a` request. | `nil` in both cases (test: aTableThatClaimsNothingReturnsNil). |
| route-table-003 | merging-order | `first` (returns 201) and `second` (returns 202); `first.merging(second).handle` and `second.merging(first).handle`. | 201, then 202 (test: mergingTriesSelfBeforeOther). |
| route-table-004 | declined-handlers-fall-through, merging-order | `first` declines, `second` returns 202; `first.merging(second).handle`. | 202 (test: mergingFallsThroughToOtherWhenSelfDeclines). |
| route-table-005 | exact-handler-claims-method-and-path | Table with `exact("GET", ["a"])` returning 200; request `GET /a`. | `status` 200 (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-006 | exact-handler-declines-otherwise | Same table; request `POST /a`. | `nil` (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-007 | exact-handler-declines-otherwise | Same table; request `GET /a/b`. | `nil` (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-008 | exact-handler-declines-otherwise | Same table; request `GET /`. | `nil` (test: exactClaimsOnlyItsMethodAndPath). |
| route-table-009 | exact-method-case-sensitive | `exact("GET", ["a"])`; request `get /a`. | `nil` (derived from the exact string comparison; no test beside the source). |
| route-table-010 | exact-path-via-components | `exact("GET", ["a"])`; request `GET //a/`. | The handler claims it and `respond` runs (derived from `pathComponents` dropping empty segments, tested in the `RouteRequest` suite; no `RouteTable` test). |
| route-table-011 | merging-non-mutating | `first.merging(second)` evaluated, then `first.handle` of a request only `second` claims. | `nil`: `first` is unchanged (derived; no test beside the source). |
| route-table-012 | later-handlers-skipped | Table of [claiming handler, handler that records a call]; `handle` a request. | The recording handler is never called (derived; no test beside the source). |
| route-table-013 | handle-is-async-sequential | Table of two handlers that each record "start" and "end" around an await; `handle` a request that neither claims. | The record reads first-start, first-end, second-start, second-end (derived; no test beside the source). |

