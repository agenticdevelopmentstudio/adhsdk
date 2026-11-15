### GlitchTip Fetcher (glitchtip.ts)

- **unconfigured-no-op**: `glitchtipFetcher(env).fetch()` MUST resolve `{ ok: true, items: [] }` without issuing any network request when `env.GLITCHTIP_URL`, `env.GLITCHTIP_API_TOKEN`, or `env.GLITCHTIP_ORG` is missing.
- **issues-request-shape**: When all three are present, the first request of `fetch()` MUST be a `GET` to `${GLITCHTIP_URL with trailing slashes stripped}/api/0/organizations/${GLITCHTIP_ORG}/issues/?query=is:unresolved&limit=${PAGE_LIMIT}` carrying header `Authorization: Bearer ${GLITCHTIP_API_TOKEN}`. Later requests of the same walk add `&cursor=<encoded cursor>`.
- **issues-request-timeout**: The whole walk (every page) MUST be bounded by one `AbortController` whose signal aborts after `TIMEOUT_MS` (12,000ms), driven by `setTimeout`, and the timer MUST be cleared in a `finally` block regardless of outcome.
- **issues-no-retry**: `fetch()` MUST NOT retry a failed or timed-out request; a failure ends the walk.
- **issues-cursor-walk**: When a page's `Link` header carries a `rel="next"` entry with `results="true"`, `fetch()` MUST request the next page using that entry's cursor, and after a walk of more than one page MUST re-read page 1 before reporting `complete: true`, so an issue that moved to page 1 mid-walk is not missed.
- **issues-later-page-failure-incomplete**: When a request after page 1 fails (HTTP error, non-array body, thrown fetch, or a failed re-read of page 1), `fetch()` MUST resolve `ok: true` with the issues already read and `complete: false`.
- **issues-walk-bounds**: A repeated cursor, or reaching `MAX_PAGES` (20) pages, MUST end the walk `ok: true` with `complete: false`.
- **issues-next-url-rebuilt**: The next-page URL MUST be rebuilt from the configured `GLITCHTIP_URL` plus the cursor; the URL inside the `Link` header MUST never be requested.
- **issues-link-header-authoritative**: An explicit `results="false"` on page 1 MUST report `complete: true` even when the page holds exactly `PAGE_LIMIT` issues.
- **issues-interrupted-flag**: `fetchGlitchtipIssues(env, query)` MUST set `interrupted: true` on its result only when the walk is short because a request after page 1 failed, never for a repeated cursor, the page cap or a full page with no usable `Link` header, so a caller can tell a blip from a walk that would stop the same way again.
- **issues-query-parameter**: `fetchGlitchtipIssues` MUST build the first request's `query=` from its `query` argument, and `fetch()` MUST pass `is:unresolved`.
- **http-error-fails-poll**: When page 1's response `ok` is `false`, `fetch()` MUST resolve `{ ok: false, items: [] }` and MUST log a `console.warn` line naming the HTTP status, without throwing.
- **non-array-body-fails-poll**: When page 1's parsed JSON body is not an `Array`, `fetch()` MUST resolve `{ ok: false, items: [] }` (never `ok: true`) and MUST log a `console.warn` line, regardless of whether the body looks like an error envelope, an HTML page, a `{results:[...]}` wrapper, or `null`.
- **thrown-fetch-fails-poll**: When the page 1 `fetch` call itself throws (a network failure or the timeout's abort), `fetch()` MUST catch it and resolve `{ ok: false, items: [] }`, logging a `console.warn` line that names the elapsed timeout when `err.name` is `"AbortError"` or `"TimeoutError"` (per `isTransient`), and the thrown error's message otherwise.
- **complete-flag-by-page-size**: When the response carries no usable `Link` header, `fetch()` MUST set `FetchResult.complete` to `issues.length < PAGE_LIMIT` (100), so a page of exactly 100 issues is reported incomplete even if it happens to be GlitchTip's entire unresolved set.
- **issue-mapping-delegated**: On a successful poll, `fetch()` MUST set `FetchResult.items` to `mapIssues(issues)`, the module's pure, network-free mapping function.
- **issue-project-fallback**: `mapIssues` MUST resolve each item's `project` via `projectSlug`: the input `project`'s `slug`, else its `name`, else the literal string `"unknown"` — including when `project` itself is a string, `null`, or `undefined`.
- **issue-count-coercion**: `mapIssues` MUST coerce `count` to a `number`: pass a `number` through unchanged, `parseInt` a `string` (defaulting to `0` when parsing fails), and default `null`/`undefined` to `0`.
- **issue-timestamp-normalization**: `mapIssues` MUST normalize `firstSeen`/`lastSeen` via `normalizeIso`, returning `null` for a falsy input or a string that does not parse to a valid `Date`, and the `Date`'s own ISO string otherwise.
- **issue-field-defaults**: `mapIssues` MUST default `culprit`, `level`, and `permalink` to `null` and `userCount` to `0` when the corresponding input field is absent, and MUST copy `id`/`title` verbatim, setting `issueKey` to the same value as `id`.

### PostHog Fetcher (posthog.ts)

- **posthog-unconfigured-no-op**: `posthogFetcher(env).fetch()` MUST resolve `{ ok: true, items: [] }` without issuing any network request when `env.POSTHOG_HOST`, `env.POSTHOG_API_KEY`, or `env.POSTHOG_PROJECT_ID` is missing.
- **posthog-single-kpi-query**: When all three are present, `fetch()` MUST answer the four fixed KPIs — `pageviews`/`24h`, `visitors`/`24h`, `pageviews`/`7d`, `visitors`/`7d`, in that column order — from ONE HogQL query, so a poll costs one request.
- **posthog-hogql-request-shape**: Each query MUST `POST` to `${host with trailing slashes stripped}/api/projects/${projectId}/query/` with headers `Authorization: Bearer ${apiKey}` and `Content-Type: application/json`, body `{ query: { kind: "HogQLQuery", query } }`.
- **posthog-query-text**: The KPI query text MUST select `countIf` and `uniqIf(person_id, ...)` over the last 1 day, plus `count()` and `uniq(person_id)` over the last `INTERVAL 7 DAY`, `FROM events WHERE event = '$pageview'`.
- **posthog-query-timeout**: The KPI query MUST carry its own `AbortController` timing out at `KPI_TIMEOUT_MS` (20,000ms), with its timer cleared in a `finally` block; the timeout starts when the query starts, not while it waits its turn.
- **posthog-sequential-execution**: HogQL queries MUST run one at a time (`hogqlRows` queues on a per-thread tail), so at most one HogQL request from this process thread is outstanding at once.
- **hogql-shared-lease**: Before running, a query MUST take a lease in a `SharedArrayBuffer` slot shared with the other thread (`hogqlLockState` / `attachHogqlLockState`); a lease still in the future makes the query wait, an expired one is taken over, and the lease is released after the query.
- **hogql-request-shape**: `hogqlRows(env, query, timeoutMs)` MUST resolve `{ ok: true, rows }` from the response's `results` array.
- **hogql-failures-returned**: `hogqlRows` MUST return, never throw, a failure as `{ ok: false, error }`: `"PostHog is not configured"`, `"HTTP <status>"`, `"response had no results"`, or the thrown error's message.
- **posthog-http-failure-fails-poll**: When the query fails, `fetch()` MUST resolve `{ ok: false, items: [] }`, so an outage never overwrites good trend data.
- **posthog-single-warn-log**: A failed poll MUST log exactly one `console.warn` line, `[telemetry] PostHog poll failed (<error>)`.
- **posthog-empty-result-fails**: `fetch()` MUST resolve `{ ok: false, items: [] }` when no column of the first row yields a usable value, even when the request itself succeeded.
- **posthog-value-coercion**: `toMetricValue` MUST pass a finite `number` through, convert a non-empty numeric `string` via `Number`, and return `null` for anything else (including `NaN`, infinities, `null`, and empty strings); a column whose value is `null` is skipped, and the metrics that did yield values are still returned `ok: true`.
- **posthog-captured-at-per-batch**: Every `AnalyticsMetricDTO` produced within one `fetch()` call MUST carry the identical `capturedAt` ISO string, captured once per call.
- **posthog-scope-fixed**: Every `AnalyticsMetricDTO` this file emits MUST set `scope` to the literal string `"all"`.

### Shared Contract (ports.ts, referenced)

- **complete-flag-omission-vs-explicit**: Per `FetchResult.complete`'s documented default in `../ports` (unset defaults to `true`), `posthogFetcher` MUST leave `complete` unset on every result it returns, because its single KPI query is never a partial page in the pagination sense; `glitchtipFetcher` MUST set `complete` explicitly on every successful poll that made a request, per **complete-flag-by-page-size**, **issues-cursor-walk** and **issues-walk-bounds**, because its provider is cursor-paginated and a reconciling store depends on that signal being explicit rather than assumed.
