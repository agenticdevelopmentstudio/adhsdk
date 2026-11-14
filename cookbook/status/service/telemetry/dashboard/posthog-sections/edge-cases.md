
- An empty result set gives an empty `sites`, zero totals and series of zeros; it is a valid answer, distinct from a failed query, which throws.
- PostHog not configured makes the query fail with `PostHog: PostHog is not configured`; the dashboard set avoids this by not calling the loaders for an unconfigured provider.
- A response with no `results` array fails the query with `response had no results`.
- A query that outlasts 45 seconds is aborted and fails with the abort message; the timeout starts when the query starts, not while it waits its turn.
- A host with a null or empty `$host` is grouped under `(unknown)`.
- Timestamps that are not exactly on a bucket boundary in UTC are dropped from the series and from `totals`, which sum the aligned series; the UTC bucket expressions are what keep rows on the axis.
- A busy site can have hundreds of distinct failing paths, so the detail cap is high and hitting it is reported through `truncated`.
- `loadTraffic` has no truncation flag; it silently returns at most 5,000 host-and-bucket rows, so a very busy window loses its latest rows' totals without notice.
- `loadPaths` has no truncation flag; it silently returns at most 5,000 rows, ordered by pageviews.
- `loadSiteHealth` and `loadVitals` return at most 200 hosts with no truncation flag.
- Both the API thread and the monitor's worker thread query PostHog; the lease that orders them is in the fetcher and is part of `one-at-a-time`.

