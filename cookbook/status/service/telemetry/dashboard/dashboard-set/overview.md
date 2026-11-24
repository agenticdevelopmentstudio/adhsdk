
`createDashboardSet(config, storage)` builds the Analytics and Errors dashboards as one set of stale-while-revalidate caches per app. It is built once at app creation and handed to every reader (the dashboard routes, `GET /report` and the MCP tools), so a report and an open dashboard tab share one refresh instead of each paying a minute of provider time for the same answer.

The set returns a `DashboardSet` with four operations. `analytics(range)` and `errors(nowMs?)` answer at once with what is known and let a refresh run behind the answer; `settleAnalytics` and `settleErrors` wait for that refresh, for a server-side reader that must hand its own client a finished answer. The caches themselves come from the `sectionedDashboard` function ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab)), and the loaders from the PostHog, GlitchTip and Vercel section modules; this ingredient specifies how the set composes them.

