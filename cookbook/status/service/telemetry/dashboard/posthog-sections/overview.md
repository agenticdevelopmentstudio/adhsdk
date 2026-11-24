
The PostHog half of the Analytics and Errors dashboards: one HogQL query per section, each with a pure shaper that turns raw rows into the section's wire type. The loaders are `loadTraffic`, `loadDimensions`, `loadPaths`, `loadVitals`, `loadSiteHealth` and `loadSiteErrorDetail`. Each builds a query, runs it through `hogqlRows` (from the PostHog fetcher, [adhsdk.ingredient.status.service.telemetry.fetchers](cookbook:8648272e-2da3-46fc-b9e8-5148dacdbcff)), and passes the rows to a shaper (`shapeTraffic`, `shapeDimensions`, `shapeVitals`, `shapeHealth`, and for the detail `shapeErrorDays`, `shapeSiteErrors` and `shapeFailedRequests`). Two helpers, `bucketStart` and `since`, build the UTC time expressions.

Every value interpolated into a query comes from a closed enum or a `Date`, never from a request string. Queries select named properties only, because `SELECT properties` is what times out. The loaders are handed to the section caches by the dashboard set ([adhsdk.ingredient.status.service.telemetry.dashboard.dashboard-set](cookbook:f03325ef-f4c6-43ab-9a88-1a0bf3daa002)); they never cache anything themselves.

| Loader | Inputs | Row cap | Shaper | Returns |
|--------|--------|---------|--------|---------|
| `loadTraffic` | `PosthogEnv`, `RangeWindow` | 5,000 | `shapeTraffic` | `TrafficSection` |
| `loadDimensions` | `PosthogEnv`, `RangeWindow` | 5,000 | `shapeDimensions` | `DimensionsSection` |
| `loadPaths` | `PosthogEnv`, `RangeWindow` | 5,000 | none (maps rows inline) | `PathRow[]` |
| `loadVitals` | `PosthogEnv`, `RangeWindow` | 200 | `shapeVitals` | `VitalsRow[]` |
| `loadSiteHealth` | `PosthogEnv`, `RangeWindow` | 200 | `shapeHealth` | `SiteHealthRow[]` |
| `loadSiteErrorDetail` | `PosthogEnv`, `RangeWindow` | 5,000 per query | `shapeErrorDays`, `shapeSiteErrors`, `shapeFailedRequests` | `SiteErrorDetailSection` |

The `RangeWindow` comes from `rangeWindow` ([adhsdk.ingredient.status.service.telemetry.dashboard.ranges](cookbook:d4e7dd53-4771-425f-af0a-0186ba89c3ef)).
