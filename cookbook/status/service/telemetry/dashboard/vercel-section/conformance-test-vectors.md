
Vectors vercel-001 to vercel-017 come from the "Vercel section" block of `telemetry-dashboard-sections.test.ts`, which stubs `fetch` per URL. Vectors vercel-018, vercel-019 and vercel-020 are not yet covered by tests there; they follow from the requirements. `w` is the 7d window at 2026-11-04T15:30:20Z.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vercel-001 | enabled-rule | Test "only a project with analytics on, and not since disabled, counts": `{ webAnalytics: { enabledAt: 1 } }`, `{ enabledAt: 1, disabledAt: 2 }`, `{}` | `true`, `false`, `false` |
| vercel-002 | domain-lookup | Test "the domain is the first alias that isn't a vercel.app one": aliases `["x.vercel.app", "x.com"]`, then `["x.vercel.app"]` | `"x.com"`, then `null` |
| vercel-003 | candidate-filter | Test "a project is production unless its name ends in staging or testing": `site-production`, `site-staging`, `site-testing`, `testing-production`, and `x` with alias `staging.x.com` | `true`, `false`, `false`, `true`, `false` |
| vercel-004 | candidate-filter, projects-total, enabled-rule, roster-membership | Test "staging and testing are neither counted nor queried": four projects, two production (one enabled) | `projectsTotal` 2, `projectsEnabled` 1, roster `["a-production", "b-production"]`; only project `prod` queried |
| vercel-005 | roster-entry, roster-null-cases, roster-sort | Test "the roster lists every production project, busiest first...": `one` (5 pageviews), `quiet` (0), `off` (analytics off) | Roster order `one`, `quiet`, `off`; `off` has `pageviews` and `visitors` null |
| vercel-006 | marginal-others-dropped | Test "shapeMarginal drops Vercel's Others rollup": rows `Others` 9 and `/a` 1 by `requestPath` | `[{ name: "/a", pageviews: 1 }]` |
| vercel-007 | marginal-by-column, marginal-none-name, marginal-sort | Test "shapeMarginal reads the value from the `by` column": rows US 1, FR 2, no country 3 | `(none)` 3, `FR` 2, `US` 1 |
| vercel-008 | domain-lookup | Test "finds the domain of a project whose latest deployment only has vercel.app aliases": domains API returns `deploying.example.com` | Roster domain `deploying.example.com` |
| vercel-009 | domain-lookup-failure | Test "falls back to the alias when the domains API cannot be read": domains API answers 403, alias `aliased.example.com` | Roster domain `aliased.example.com` |
| vercel-010 | listed-filter, projects-total | Test "drops a project whose real domain turns out to be staging": domains API returns `staging.example.com` | Roster `[]`, `projectsTotal` 0 |
| vercel-011 | count-call, breakdown-targets, breakdown-calls, totals-from-traffic, series-sum, project-traffic-shape, team-id | Test "counts every enabled project, breaks down only those with traffic": 3 projects, 2 enabled, only `p1` has 5 pageviews and 2 visitors | `projectsTotal` 3, `projectsEnabled` 2, `failed` 0, totals 5 and 2, last series values 5 and 2, one project; aggregate calls only for `p1`, all with `limit` 100, `by` values `country`, `day`, `deviceType`, `referrerHostname`, `requestPath`; `teamId` is `team` |
| vercel-012 | window-day-dates, window-hour-instants | Test "asks for hourly buckets with instants, whole days with dates": 7d window, then 24h window | Count `since` is `2026-10-29`; then `2026-11-03T15:00:00.000Z` |
| vercel-013 | count-failure | Test "a project whose calls fail is counted, not silently zero": `p2` answers 503 | `failed` is 1 |
| vercel-014 | breakdown-short, breakdown-not-failed | Test "a failed breakdown marks the project incomplete, and keeps its count whole": the `day` aggregate answers 504 | `failed` 0, `incomplete` 1, `totals.pageviews` 5, project `one` has `incomplete` true |
| vercel-015 | count-all-failed | Test "every count failing fails the section": every non-list call answers 503 | Rejects with `every Vercel analytics call failed` |
| vercel-016 | rate-limit-ends-load, rate-limit-recording | Test "stays off a token that is cooling down": `noteRateLimited("vercel", "60")` first | Rejects with a message containing `rate limited`; no calls reach the API |
| vercel-017 | breakdown-rate-limit, rate-limit-ends-load | Test "a 429 in a breakdown fails the section and stops the calls not yet made": 8 busy projects, `b0` answers 429 | Rejects with `rate limited`; no aggregate calls for `b6` or `b7` |
| vercel-018 | count-none-enabled | Projects listed but none with analytics on | Resolves with `failed` 0, `projectsEnabled` 0, totals 0 |
| vercel-019 | roster-sort | Two projects with equal pageviews named `b` and `a` | Roster order `a`, `b` |
| vercel-020 | no-projects | The project list is empty | Empty roster, `projectsTotal` 0, zero totals, no error |

