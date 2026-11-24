
### Request

- **api-base**: `VERCEL_API` MUST be `https://api.vercel.com`, and every request URL MUST be built with `new URL(path, VERCEL_API)`.
- **cooldown-first**: `vercelRequest` MUST check `rateLimitedUntil("vercel")` before every call, not only a load's first call, and when a cooldown is active MUST throw `VercelRateLimited` with the message `Vercel rate limited until <ISO time>` without calling `fetch`.
- **team-scope**: When `env.VERCEL_TEAM_ID` is non-empty the request MUST carry it as the `teamId` query parameter.
- **query-params**: Every entry of `params` MUST be set as a query parameter after `teamId`, so a `teamId` in `params` replaces the one from `env`.
- **auth-header**: The request MUST send `Authorization: Bearer <env.VERCEL_API_TOKEN>`.
- **method-selection**: The method MUST be POST when `init.json` is not `undefined`, otherwise GET.
- **post-body**: A POST MUST send `JSON.stringify(init.json)` as the body with `Content-Type: application/json`; a GET MUST send no body and no `Content-Type`.
- **extra-headers**: `init.headers` MUST be merged last, so a caller header replaces `Authorization` or `Content-Type` of the same name.
- **call-timeout**: Every call MUST be aborted after `CALL_TIMEOUT_MS` (20,000 ms) by `AbortSignal.timeout`.
- **caller-signal**: A caller `signal` MUST add to the per-call timeout through `AbortSignal.any`, never replace it.
- **raw-response**: On success `vercelRequest` MUST return the unconsumed `Response`, so a caller can stream its body.

### Failure

- **rate-limit-429**: A 429 response MUST call `noteRateLimited("vercel", <retry-after header or null>)` and then throw `VercelRateLimited("Vercel rate limited")`. `VercelRateLimited` ends a whole read: every further call would 429 too.
- **http-error**: Any other non-2xx response MUST throw `VercelHttpError` carrying `path`, `status` and `body` (the response text, or the empty string when reading it fails), with the message `Vercel <path> HTTP <status>`.
- **network-errors-propagate**: A network failure, timeout abort or caller abort MUST reject with the underlying error, unchanged and unretried.
- **no-retry**: `vercelRequest` MUST NOT retry or back off by itself; the only back-pressure is the shared cooldown.
- **token-presence**: `vercelRequest` MUST NOT check `env.VERCEL_API_TOKEN` itself: when it is `undefined` the header reads `Bearer undefined` and Vercel's 401 MUST surface as a `VercelHttpError` like any other error status. The callers MUST own the missing-token check: `vercelRuntimeFetcher` returns an empty successful read without a token, and the monitor's Vercel fetchers do the same.

### JSON and listing

- **json-get**: `vercelGet` MUST call `vercelRequest` (GET) and return the parsed JSON body typed `unknown`; invalid JSON MUST reject.
- **list-projects**: `listProjects` MUST request `/v9/projects` with `limit` `100`, append each page's `projects` to the result (a missing `projects` reads empty), and pass the caller's `signal` on.
- **list-continuation**: `listProjects` MUST continue while `pagination.next` is truthy, sending it as the `until` parameter converted with `String`, and MUST stop when it is null, absent or 0.
- **list-page-cap**: `listProjects` MUST read at most `MAX_PROJECT_PAGES` (20) pages, so at most 2,000 projects; a longer list is truncated, and the result carries no flag or log that says so.
- **list-errors**: An error on any page (rate limit, HTTP error, abort) MUST reject the whole call; the pages already read are discarded.

### Production rules

- **production-domain**: `productionDomain` MUST return the first alias in `targets.production.alias` that does not end in `.vercel.app`, or null when there is none or the structure is missing.
- **production-project**: `isProductionProject` MUST return false when the project name ends in `-staging` or `-testing` (case-insensitive), or when its `productionDomain` is a non-production host; otherwise true. A missing name passes the name test. Only the end of the name counts: `testing-production` is a production site.
- **non-production-host**: `isNonProductionHost` MUST return true when the domain starts with `staging.` or `testing.` (case-insensitive), and false for null or any other domain.

