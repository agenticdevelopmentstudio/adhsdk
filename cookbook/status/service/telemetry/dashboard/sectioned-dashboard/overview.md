
`sectionedDashboard` builds a stale-while-revalidate cache for a dashboard made of independently slow sections. The status server uses it for the PostHog, Vercel and GlitchTip providers and the per-site error health, so a slow provider never holds back the others.

The design follows the source's header comment. PostHog queries run one at a time (its API answers 503 under concurrency) and take 2 to 30 seconds each, so a cold dashboard can take a minute. That is longer than the rewrite proxy in front of the server will wait, and it would hold a request open when most sections could already be on screen. So `read` never waits. It answers at once with what is known and starts a refresh if one is due. Each section publishes as it finishes, and the client polls while `refreshing` is true to watch them fill in.

Refreshes are started by reads, not timers, so an idle dashboard costs no provider quota. Each section keeps its own schedule: a refresh re-runs only the sections that are due, so one failing section is retried on its own, with backoff, while healthy sections wait out their full TTL.

The module exports `sectionedDashboard`, `emptySections` and the types `DashboardSection`, `DashboardSections`, `DashboardLoaders`, `DashboardRead`, `SectionedDashboard` and `SectionedDashboardOptions`. State lives in memory in the closure of one dashboard instance.

