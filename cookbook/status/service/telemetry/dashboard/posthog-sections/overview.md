
The PostHog half of the Analytics and Errors dashboards: one HogQL query per section, each with a pure shaper that turns raw rows into the section's wire type. The loaders are `loadTraffic`, `loadDimensions`, `loadPaths`, `loadVitals`, `loadSiteHealth` and `loadSiteErrorDetail`. Each builds a query, runs it through `hogqlRows`, and passes the rows to a shaper (`shapeTraffic`, `shapeDimensions`, `shapeVitals`, `shapeHealth`, and for the detail `shapeErrorDays`, `shapeSiteErrors` and `shapeFailedRequests`). Two helpers, `bucketStart` and `since`, build the UTC time expressions.

Every value interpolated into a query comes from a closed enum or a `Date`, never from a request string. Queries select named properties only, because `SELECT properties` is what times out. The loaders are handed to the section caches by the dashboard set; they never cache anything themselves.

