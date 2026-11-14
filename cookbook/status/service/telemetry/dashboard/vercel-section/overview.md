
`vercel-section.ts` produces the `vercel` section of the analytics dashboard: Vercel Web Analytics read through the REST API (`https://vercel.com/docs/analytics/web-analytics-api`). HTTP, the cooldown and project classification live in [adhsdk.ingredient.status.service.telemetry.vercel-api](cookbook:60ff967b-b041-4723-913e-016fba7bae6d). It uses the same token as the deploy poll, so it shares that token's quota and honors the shared 429 cooldown.

The API is per project, and only production projects are read at all. Counts run for every project with analytics on; the costlier breakdowns run only for projects that had traffic, because most have none.

The module exports `loadVercelTraffic(env, w)`, `analyticsEnabled(project)` and `shapeMarginal(rows, by)`. It returns a `VercelTrafficSection` (see the dashboard wire types recipe, [adhsdk.ingredient.status.service.telemetry.dashboard.types](cookbook:f06a7f7a-1b36-4dfc-a17d-71d20d576155)). The sectioned-dashboard cache ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab)) calls the loader and treats a section as short when `failed > 0` or `incomplete > 0`.

The work happens in phases: list the projects, resolve each candidate's domain, count visits for each enabled project, break down each project that had traffic, then assemble totals, a roster and the summed series.

