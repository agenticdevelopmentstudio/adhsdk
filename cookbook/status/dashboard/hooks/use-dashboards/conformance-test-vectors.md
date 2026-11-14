
No test file exists for this module: `ErrorsView.dom.test.tsx` replaces the errors-dashboard read with a stub, and `client.test.ts` covers only the message-extraction helper this module calls. Vectors 001–008 are derived from the source; vectors 009–011 reuse the `errorMessage` assertions in `client.test.ts`. Run the reads under a shared cache provider with retries disabled and an overriding client with a stubbed transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dash-001 | poll-filling | the poll-interval function called with a body whose `refreshing` is `true` | `5000` |
| dash-002 | poll-settled | the poll-interval function called with a body whose `refreshing` is `false` | `60000` |
| dash-003 | poll-no-data | the poll-interval function called with `undefined` | `60000` |
| dash-004 | poll-error-state, stale-data-kept-on-error | a read whose last body had `refreshing: true`, then a refetch returns `502` | the read is in its error state, `data` still holds the old body, and the next poll is scheduled 60000 ms out, not 5000 |
| dash-005 | analytics-request-path, enabled-default, request-init, client-source | the analytics-dashboard read called with `"7d"` and no options, default client; stub returns `200` and a valid body | exactly one fetch to `/api/analytics/dashboard?range=7d` with no request options; `data` holds the body |
| dash-006 | errors-request-path, errors-query-key | the errors-dashboard read called with no options; stub returns `200` and a valid body | exactly one fetch to `/api/errors/dashboard`, cached under `"errors-dashboard"` |
| dash-007 | enabled-default, no-polling-when-disabled | either read called with `{ enabled: false }` | no fetch is issued, and none after 60 seconds |
| dash-008 | analytics-keep-previous, analytics-query-key | the analytics-dashboard read first called with `"24h"` (resolved), then re-rendered with `"7d"` whose request is still pending | `data` still holds the `"24h"` body and `isPlaceholderData` is true until the `"7d"` response arrives |
| dash-009 | non-ok-error, non-ok-message-detail | stub returns `500` with body `{"error":{"message":"Unauthorized"}}` | the read's `error.message` is `Unauthorized` |
| dash-010 | non-ok-message-detail | stub returns `500` with body `{"error":"invalid range"}` | the read's `error.message` is `invalid range` |
| dash-011 | non-ok-message-fallback | stub returns `502` with body `<html>Bad Gateway</html>`, and separately `500` with body `{"error":{}}` | the read's `error.message` is `status 502`, and `status 500` |
| dash-012 | parse-failure | stub returns `200` with body `not json` | the read enters its error state with the JSON parse rejection |
| dash-013 | network-failure | stub transport rejects with `TypeError("Failed to fetch")` | the read's `error` is that `TypeError`, unchanged |
| dash-014 | single-threaded-ordering | two components call the analytics-dashboard read with `"30d"` under one shared cache | one request is sent |

