
Vectors 1 to 4 are the assertions of `telemetry-errors-summary.test.ts`; 5 to 10 are read from the
source. Rows are written id/count/active.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| errors-summary-001 | active-count, backlog-count, events-total (test: "splits active issues from the backlog and totals every event") | a/3/true, b/10/false, c/2/true | `active` 2, `backlog` 1, `events` 15 |
| errors-summary-002 | top-active-only, top-order, top-cap (test: "lists only active issues, loudest first, capped") | quiet/1/true, old-loud/99/false, x0 to x5 with counts 10 to 15, all active | `top` ids are x5, x4, x3, x2, x1; length 5; `old-loud` and `quiet` absent |
| errors-summary-003 | unjudged-is-backlog (test: "never counts an unjudged row as an incident") | one row u/4 with no `active` field | `active` 0, `backlog` 1, `top` empty |
| errors-summary-004 | empty-input (test: "is all zeros for no errors") | empty array | `active` 0, `backlog` 0, `events` 0, `top` empty |
| errors-summary-005 | unjudged-is-backlog | one row with `active: false`, count 7 | `active` 0, `backlog` 1, `events` 7, `top` empty |
| errors-summary-006 | top-tie-order | p/5/true then q/5/true | `top` ids are p, q |
| errors-summary-007 | top-cap | exactly five active rows | `top` has five rows, none dropped |
| errors-summary-008 | purity | Rows a/3/true, b/1/false, c/2/true; a deep copy of the array is taken before the call | After the call the array equals the copy: same order, same field values |
| errors-summary-009 | events-total | an active row with `count` `NaN` and one with count 4 | `events` 4 |
| errors-summary-010 | top-rows-unchanged | one active row | `top[0]` is the same object as the input row |
| errors-summary-011 | top-tie-order, top-cap, edge case equal counts at the cap boundary | Six active rows r1 to r6, all with count 5 | `top` ids are r1, r2, r3, r4, r5; `r6` is absent; `active` 6 |

