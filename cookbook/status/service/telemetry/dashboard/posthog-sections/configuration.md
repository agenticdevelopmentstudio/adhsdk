
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env` | `PosthogEnv` | required | `POSTHOG_HOST`, `POSTHOG_API_KEY`, `POSTHOG_PROJECT_ID` |
| `window` | `RangeWindow` | required | The window (`since`, `unit`, `buckets`) from `rangeWindow(range, now)` |
| `QUERY_TIMEOUT_MS` | number | 45000 | Per-query timeout; a module constant |
| `TRAFFIC_ROW_LIMIT`, `DIMENSION_ROW_LIMIT`, `PATH_ROW_LIMIT`, `ERROR_DETAIL_ROW_LIMIT` | number | 5000 | Row caps; module constants |
| `SITE_ROW_LIMIT` | number | 200 | Row cap for vitals and site health; a module constant |
| `PRODUCTION_HOSTS` | string | `$host NOT LIKE` each of `testing.%`, `staging.%`, `%localhost%`, `%127.0.0.1%` and `%.vercel.app` | The host filter every query applies; a module constant |
