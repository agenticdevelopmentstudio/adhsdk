
`vercel-section.ts` produces the `vercel` section of the analytics dashboard: Vercel Web Analytics read through the REST API (`https://vercel.com/docs/analytics/web-analytics-api`). It uses the same token as the deploy poll, so it shares that token's quota and honors the shared 429 cooldown.

The API is per project, and only production projects are read at all. Counts run for every project with analytics on; the costlier breakdowns run only for projects that had traffic, because most have none.

The module exports `loadVercelTraffic(env, window)`, `analyticsEnabled(project)` and `shapeMarginal(rows, by)`. It returns a `VercelTrafficSection` (see the dashboard wire types recipe). The sectioned-dashboard cache calls the loader and treats a section as short when `failed > 0` or `incomplete > 0`.

The work happens in phases: list the projects, resolve each candidate's domain, count visits for each enabled project, break down each project that had traffic, then assemble totals, a roster and the summed series.

