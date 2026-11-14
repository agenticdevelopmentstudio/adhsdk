
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-app-spans-001 | span-session-id, session-id-marker | `BillingAppSpanRow` with `id` `X1`; test `testSpanRowSessionIdMatchesActivitySpanSession` | `sessionId` equals `ActivitySpanSession.sessionId(spanId: "X1")` and `ActivitySpanSession.spanId(sessionId:)` of it returns `X1` |
| billing-app-spans-002 | span-session-id | Row with `id` `S` | `sessionId` is `app:S` |
| billing-app-spans-003 | ended-at-open | Row with `endedAt` empty, derived at a time with recent input (`testOpenSpanActiveNowIsRunning`) | The span is treated as open and still running |
| billing-app-spans-004 | idle-until-open | `BillingIdleInterval(idleFrom: t, idleUntil: "")` consumed by derivation (`testOpenSpanWhileIdlePastCutoffEndsAtLastInput`) | With `idleFrom` `2026-10-01T09:20:00Z`, cutoff 900 s and now `2026-10-01T09:40:00Z`, the idle interval is treated as still idle and the open span ends at `idleFrom` (1200 s) |
| billing-app-spans-005 | value-semantics | Two `BillingAppSpanRow` values built from identical arguments | They compare equal; changing any one field makes them unequal |
| billing-app-spans-006 | no-validation | `BillingAppSpanRow` built with `startedAt` `not-a-date` | The initializer returns without error and `startedAt` reads back unchanged; derivation handles it (`testMalformedTimestampIsEmpty`) |
| billing-app-spans-007 | working-path-unresolved, repo-root-definition | Row with empty `workingPath` and empty `repoRoot` | Both fields read back as the empty string |

