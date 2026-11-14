
Vectors 1 to 3 are assertions of `telemetry-dashboard-sections.test.ts` (test names in brackets); 4 to 6 come from `runtime-errors.test.ts`, which exercises `vercelRequest` through `vercelRuntimeFetcher`; 7 to 19 are read from the source. There is no test file for `vercel-api.ts` alone.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vercel-api-001 | production-domain ("the domain is the first alias that isn't a vercel.app one") | aliases `x.vercel.app`, `x.com`; and aliases `x.vercel.app` only | `x.com`; null |
| vercel-api-002 | production-project ("a project is production unless its name ends in staging or testing") | names `site-production`, `site-staging`, `site-testing`, `testing-production` | true, false, false, true |
| vercel-api-003 | production-project, non-production-host | name `x`, alias `staging.x.com` | false |
| vercel-api-004 | rate-limit-429, cooldown-first ("fails on a 429, records the shared cooldown, and then asks nothing while it lasts") | first call answered 429; then a second read | the first read fails and `rateLimitedUntil("vercel")` is not null; the second makes no `fetch` call |
| vercel-api-005 | caller-signal ("fails at the overall deadline, the project list included") | `fetch` that never resolves, abort by caller deadline of 50 ms | the read fails in under 5 seconds |
| vercel-api-006 | http-error (test "fails on any other error, so the store keeps what it had") | a non-429 error status | the read fails; nothing saved |
| vercel-api-007 | list-continuation | page 1 with `pagination.next` 1700, page 2 with next null | two requests; the second has `until=1700`; both pages' projects returned |
| vercel-api-008 | list-page-cap | every page returns a `next` | exactly 20 requests, then the collected projects are returned with no error |
| vercel-api-009 | method-selection, post-body | `init.json` `{a:1}` | POST, body `{"a":1}`, `Content-Type: application/json` |
| vercel-api-010 | team-scope, query-params | `VERCEL_TEAM_ID` `team_1`, params `{limit:"5"}` | URL carries `teamId=team_1` and `limit=5` |
| vercel-api-011 | http-error | status 500, body `oops` | `VercelHttpError` with `status` 500, `body` `oops`, message `Vercel <path> HTTP 500` |
| vercel-api-012 | non-production-host | `STAGING.x.com`; `x.com`; null | true; false; false |
| vercel-api-013 | production-project | name `Site-STAGING` | false |
| vercel-api-014 | json-get | 200 response with body `not json` | rejects |
| vercel-api-015 | call-timeout, caller-signal | `fetch` that never resolves, a fake timer, no caller `signal`; then the same with a caller `signal` that never aborts | the call aborts with the timeout error once `CALL_TIMEOUT_MS` (20,000 ms) has passed, in both cases; the caller signal does not lengthen it |
| vercel-api-016 | extra-headers | `init.headers` `{Authorization: "Bearer other"}` | the request carries `Authorization: Bearer other`, not the one built from `env` |
| vercel-api-017 | query-params | `VERCEL_TEAM_ID` `team_1`, params `{teamId: "team_2"}` | URL carries `teamId=team_2` once |
| vercel-api-018 | cooldown-first | `rateLimitedUntil("vercel")` returns a time | `VercelRateLimited` with message `Vercel rate limited until <ISO time>`, and `fetch` is not called |
| vercel-api-019 | list-errors | page 1 returns projects with a `next`; page 2 answers 500 | `listProjects` rejects with `VercelHttpError`; page 1's projects are not returned |
