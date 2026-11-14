
- **Missing token**: `Bearer undefined` is sent and Vercel's 401 surfaces as `VercelHttpError` (see `token-presence`; callers skip the call when there is no token).
- **Empty project list**: a page with no `projects` MUST read as empty and the loop ends when `next` is absent.
- **`pagination.next` of 0**: treated as the end, because 0 is falsy.
- **More than 2,000 projects**: the list MUST stop at 20 pages with no error and no marker.
- **Unreadable error body**: `VercelHttpError.body` MUST be the empty string.
- **429 with a missing or unparseable `retry-after`**: handled by the cooldown module (default 60 seconds; its own cap is 15 minutes); this client passes the header text or null.
- **Cooldown already active**: MUST throw before any network call, even for a call that is not the first of a read.
- **Timeout**: a call longer than 20 seconds MUST abort with the timeout error; there is no retry.
- **Caller abort**: MUST abort the call; the per-call timeout still applies.
- **Absolute `path`**: `new URL(path, VERCEL_API)` resolves an absolute URL in `path` over the base; callers pass paths only, and nothing here rejects a full URL.
- **Project with no name or alias**: `isProductionProject` MUST treat it as production unless a host or name rule excludes it.
- **Concurrent calls**: calls share no state in this module; the cooldown is shared across threads through the shared module, and its writes keep the furthest expiry.
- **Offline**: `fetch` rejects with a network error and it propagates; no fallback.

