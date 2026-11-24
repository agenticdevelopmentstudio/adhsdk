
`use-dashboards.dom.test.tsx` covers all 20 vectors, one test per vector id, against stub transports under a shared cache provider with retries disabled; the poll-pace vectors run under fake timers.

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
| dash-014 | shared-cache-entry | two components call the analytics-dashboard read with `"30d"` under one shared cache | one request is sent |
| dash-015 | poll-after-recovery, poll-interval-recomputed | a read whose body has `refreshing: true` (5000 ms), then a refetch returns `502`, then the next refetch returns a success body with `refreshing: true` | the interval is 5000, then 60000 while in the error state, then 5000 again with no action from the caller |
| dash-016 | analytics-focus-refetch | the analytics-dashboard read has settled; the window loses and regains focus | one extra fetch to the same path is issued |
| dash-017 | errors-focus-refetch | the errors-dashboard read has settled; the window loses and regains focus | one extra fetch to `/api/errors/dashboard` is issued |
| dash-018 | errors-no-placeholder | the errors-dashboard read is unmounted and a fresh caller mounts under a cleared cache while the request is pending | `data` is `undefined` and `isPlaceholderData` is false until the response arrives |
| dash-019 | return-value, success-body | either read called against a stub returning `200` and the JSON body `{"refreshing":false}` | the returned object is the full read result with `data` equal to the parsed body and no extra fields |
| dash-020 | enabled-default | either read first called with `{ enabled: false }`, then re-rendered with `{ enabled: true }` | no fetch while disabled; one fetch begins on the switch and polling starts |
