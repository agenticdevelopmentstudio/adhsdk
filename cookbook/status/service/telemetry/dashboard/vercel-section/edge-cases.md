
- **No projects**: See `#requirements/no-projects`.
- **No enabled project**: See `#requirements/count-none-enabled`. The all-failed check needs at least one enabled project.
- **Project with count 0**: Counted and shown in the roster with 0, but no breakdowns are requested for it.
- **Some counts fail**: Those projects are counted in `failed` and show `null` in the roster. Totals and series are then short, and the sectioned-dashboard cache retries the section after its short delay.
- **All counts fail**: The section rejects, so the dashboard keeps its last good data and shows the error.
- **A breakdown call fails**: The project stays in the totals, its `incomplete` is true, and the lists for the failed calls are empty (see `#requirements/breakdown-short`).
- **Rate limit (429)**: Ends the whole load in any phase. Workers that already started may finish, but later calls throw at the cooldown check.
- **Rate limit during domain lookup**: `fetchProjectPrimaryDomain` records the cooldown but returns a domain or null instead of throwing, so the load continues until the next Vercel call throws at the cooldown check. In the test "stays off a token that is cooling down" the cooldown is already set before the load, so the project list call throws first.
- **Project list failure**: An error from `listProjects` (HTTP error, timeout, rate limit) is not caught here and rejects the section.
- **Aggregate limit**: With 100 rows per call, a project with more than 100 distinct values in a dimension gets the remainder folded into `"Others"`, which is dropped from the list. For the series the limit of 100 covers the 30 daily or 25 hourly buckets.
- **Timestamps off the axis**: Series rows whose `timestamp` does not match a bucket start are dropped by `alignToBuckets`, in both a project's series and the summed series.
- **Domain differs between listings**: A project whose API alias is `*.vercel.app` mid-deployment still gets its custom domain from the domains API, so the roster domain does not depend on whether a deploy is in progress.
- **Missing name or id**: A listed project without an `id` or `name` is not a candidate and does not appear anywhere.
- **Non-numeric counts**: A count answer with no `data` yields 0 pageviews and 0 visitors. Aggregate values are coerced with `Number(...) || 0`.
- **Concurrent access**: The loader uses a counter (`failed`, `incomplete`) that parallel workers increment. JavaScript runs those increments one at a time, so no lock is needed. Two loads at once (for different ranges) share the cooldown and the domain cache and make independent calls.
- **Offline or unreachable API**: Each call fails with a network error. Counts then fail and, if every enabled project failed, the section throws; the cache keeps stale data.
- **Retry**: None here; see `#requirements/no-retry`.

