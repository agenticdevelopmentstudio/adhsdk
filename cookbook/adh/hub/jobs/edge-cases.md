
- **Null and empty input**: No jobs, no catalog, no templates and no environments each show their own empty
  text (MUST). A step run with no output shows none, not an empty box (MUST).
- **Boundary values**: An output stored at the 256 KiB cap with `truncated: true` says it was cut short
  (MUST). A step log holds at most 200 lines and is shown whole.
- **Unknown id**: A selected job, run, template or environment that matches no loaded row shows the select
  hint and never a blank pane (MUST).
- **Concurrent access**: A run that ends while its pane is open stops the stream and shows the final state
  (MUST). A cancel of a run whose step is already claimed shows the run cancelled, while that step
  finishes on the node.
- **Switch off**: Every `/jobs` route answers 404 while the feature's switch is off, and the panes read
  that as the feature being unavailable (MUST).
- **Limits**: A create or run refused for a set limit (`jobs.max_jobs`, `jobs.min_interval_minutes`) shows
  the backend's message. A run started over `jobs.monthly_runs` arrives `failed` with `error_code`
  `limit_runs`, and the run pane says why.

