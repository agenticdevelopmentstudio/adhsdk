
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-app-spans-001 | span-session-id, session-id-marker | `BillingAppSpanRow` with `id` `X1`; test `testSpanRowSessionIdMatchesActivitySpanSession` | `sessionId` equals `ActivitySpanSession.sessionId(spanId: "X1")` and `ActivitySpanSession.spanId(sessionId:)` of it returns `X1` |
| billing-app-spans-002 | span-session-id | Row with `id` `S` | `sessionId` is `app:S` |
| billing-app-spans-003 | ended-at-open | Row with `endedAt` empty | `endedAt` reads back as the empty string; reading it as open is the consumer's job and is tested in `adhsdk.ingredient.foundation.billing.billing-derivation` |
| billing-app-spans-004 | idle-until-open, idle-from-meaning | `BillingIdleInterval(idleFrom: "2026-10-01T09:20:00Z", idleUntil: "")` | `idleFrom` reads back as `2026-10-01T09:20:00Z` and `idleUntil` as the empty string; how derivation treats the open interval is tested in `adhsdk.ingredient.foundation.billing.billing-derivation` |
| billing-app-spans-005 | value-semantics | Two `BillingAppSpanRow` values built from identical arguments | They compare equal; changing any one field makes them unequal |
| billing-app-spans-006 | no-validation | `BillingAppSpanRow` built with `startedAt` `not-a-date` | The initializer returns without error and `startedAt` reads back unchanged |
| billing-app-spans-007 | working-path-unresolved, repo-root-definition | Row with empty `workingPath` and empty `repoRoot` | Both fields read back as the empty string |

