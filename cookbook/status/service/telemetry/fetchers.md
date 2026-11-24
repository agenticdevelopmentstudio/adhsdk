---
id: 8648272e-2da3-46fc-b9e8-5148dacdbcff
title: "Status Server Fetchers"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two Fetcher-port adapters feeding the status server's telemetry streams — a cursor-paged GlitchTip issues walk and a single-query PostHog HogQL poll, env-gated, never retried, with a process-wide one-query-at-a-time HogQL lease."
platforms:
  - typescript
  - web
tags:
  - telemetry
  - glitchtip
  - posthog
  - fetcher
  - server
depends-on: []
related: []
references:
  - packages/web/packages/status-server/src/telemetry/fetchers/glitchtip.ts (adhsdk)
  - packages/web/packages/status-server/src/telemetry/fetchers/posthog.ts (adhsdk)
  - packages/web/packages/status-server/test/telemetry-glitchtip-fetcher.test.ts (adhsdk)
  - packages/web/packages/status-server/test/telemetry-posthog-fetcher.test.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# Status Server Fetchers

## Overview

Two files under `src/telemetry/fetchers/` — `glitchtip.ts` and `posthog.ts` — are the two provider adapters behind the status server's telemetry `Fetcher<T>` port (`../ports`, external to this recipe's two files but the contract both implement). `glitchtipFetcher` walks GlitchTip's Sentry-API-compatible organization-issues endpoint page by page, following the cursor in each response's `Link` header, and maps the grouped issues to `ErrorDTO`; `posthogFetcher` answers all four headline KPIs with one HogQL query against PostHog's query API and maps the row to `AnalyticsMetricDTO` (both DTOs from `../types`, external). Each is built from a small `*Env` record naming its provider's credentials (`GlitchtipEnv`, `PosthogEnv`), no-ops with an empty successful result when those credentials are not all present, and otherwise resolves a `FetchResult<T>` without retrying: the GlitchTip walk shares one 12 s budget across all its pages, and the PostHog query has its own 20 s timeout. `posthog.ts` also exports `hogqlRows`, the one-query-at-a-time HogQL helper that the dashboards' sections share, and `glitchtip.ts` exports `fetchGlitchtipIssues`, the paged walk for any issue query. Both files are PURE with respect to storage — they only fetch and map; persisting the result is `collect.ts`'s and the `Store<T>` port's job (external), and choosing which fetcher backs which stream is `server.ts`'s composition-root job (also external). The folder also holds `vercel-runtime.ts`, a third adapter that this recipe does not specify; the runtime-errors recipe describes it.
## Behavioral Requirements
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
## Appearance

Not applicable — this is a pair of telemetry Fetcher-port adapters, not a visual component.

## States

Not applicable — this is a pair of telemetry Fetcher-port adapters, not a visual component; their runtime branches (unconfigured, succeeded, failed, timed out) are captured under Behavioral Requirements, not a visual-state table.

## Accessibility

Not applicable — this is a pair of telemetry Fetcher-port adapters, not a visual component.

## Conformance Test Vectors
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| status-server-fetchers-001 | unconfigured-no-op | `glitchtipFetcher({}).fetch()` | Resolves `{ ok: true, items: [] }`; no `fetch` call is made — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-001" |
| status-server-fetchers-002 | issues-request-shape | `glitchtipFetcher(ENV).fetch()` with a stubbed `fetch` returning `[]` | The single outbound URL is `https://glitchtip.example/api/0/organizations/adh/issues/?query=is:unresolved&limit=100`, with header `Authorization: Bearer tok` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-002" |
| status-server-fetchers-003 | complete-flag-by-page-size, issue-mapping-delegated | Response body is an array of 2 issues (`a`, `b`), no `Link` header | `r.ok === true`, `r.complete === true`, `r.items.map(i => i.issueKey)` equals `["a","b"]` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-003" |
| status-server-fetchers-004 | complete-flag-by-page-size | Response body is an array of exactly 100 (`PAGE_LIMIT`) issues, no `Link` header | `r.ok === true`, `r.complete === false` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-004" |
| status-server-fetchers-005 | non-array-body-fails-poll | Response body is `{ detail: "Authentication credentials were not provided." }` on a 200 | Resolves `{ ok: false, items: [] }` and logs a warning naming the non-array body — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-005" |
| status-server-fetchers-006 | http-error-fails-poll | Response is not `ok`, status 502 | Resolves `{ ok: false, items: [] }` and logs a warning containing `HTTP 502` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-006" |
| status-server-fetchers-007 | thrown-fetch-fails-poll, issues-no-retry | Stubbed `fetch` throws `Error("ECONNREFUSED")` | Resolves `{ ok: false, items: [] }`; `fetch` is invoked exactly once; the warning contains `ECONNREFUSED` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-007" |
| status-server-fetchers-008 | issue-project-fallback | `mapIssues([{id:"1",title:"t",project:{slug:"adh",name:"ADH"}},{id:"2",title:"t",project:{name:"Some Team's App"}},{id:"3",title:"t",project:null}])` | Projects resolve to `"adh"`, `"Some Team's App"`, `"unknown"` respectively — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-008" |
| status-server-fetchers-009 | issue-count-coercion, issue-timestamp-normalization, issue-field-defaults | `mapIssues([{id:"1",title:"t",count:"42",firstSeen:"not-a-date",lastSeen:"2026-08-18T00:00:00Z"}])` | Resolves `{ id: "1", issueKey: "1", project: "unknown", title: "t", culprit: null, level: null, count: 42, userCount: 0, firstSeen: null, lastSeen: "2026-08-18T00:00:00.000Z", permalink: null }` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-009" |
| status-server-fetchers-010 | posthog-unconfigured-no-op | `posthogFetcher({}).fetch()`, and one with `POSTHOG_API_KEY` missing | Resolves `{ ok: true, items: [] }`; no `fetch` call is made — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-010" |
| status-server-fetchers-011 | posthog-single-kpi-query, posthog-query-text, posthog-hogql-request-shape | `posthogFetcher(ENV).fetch()` with the HogQL POST answering `{results:[[1,2,3,4]]}` | Exactly 1 POST to `https://ph.example/api/projects/7/query/` with `Authorization: Bearer k`, `Content-Type: application/json`, body `{ query: { kind: "HogQLQuery", query } }`; the query text contains `countIf(timestamp > now() - INTERVAL 1 DAY)`, `uniqIf(person_id, timestamp > now() - INTERVAL 1 DAY)`, `event = '$pageview'` and `INTERVAL 7 DAY` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-011" |
| status-server-fetchers-012 | posthog-query-timeout | The POST never resolves until its signal aborts | The query's `AbortController` fires at 20,000ms (not before); the poll resolves `{ ok: false, items: [] }` and warns `PostHog poll failed (<error>)` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-012" |
| status-server-fetchers-013 | posthog-sequential-execution | Three `hogqlRows` calls made together, each POST recording start and end | Each POST starts only after the previous one has ended; never more than one in flight — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-013" |
| status-server-fetchers-014 | posthog-http-failure-fails-poll, posthog-single-warn-log | The HogQL POST responds HTTP 503 | Resolves `{ ok: false, items: [] }`; exactly one `console.warn` call, containing `PostHog poll failed (HTTP 503)` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-014" |
| status-server-fetchers-015 | posthog-empty-result-fails | The row holds no usable value (`[null,"abc","",undefined]`), or `results` is `[]` | Resolves `{ ok: false, items: [] }` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-015" |
| status-server-fetchers-016 | posthog-value-coercion | Row `["42","abc",0,null]` | Resolves `ok: true` with two items, `pageviews`/`24h` = 42 and `pageviews`/`7d` = 0; `"abc"` and `null` are skipped; `toMetricValue("abc")` and `toMetricValue(Infinity)` are `null` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-016" |
| status-server-fetchers-017 | posthog-captured-at-per-batch, posthog-scope-fixed | A successful 4-column row | Every emitted `AnalyticsMetricDTO.capturedAt` is the identical ISO string; every `scope` is `"all"` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-017" |
| status-server-fetchers-018 | complete-flag-omission-vs-explicit | Any `posthogFetcher(...).fetch()` result, configured or not | The returned object has no `complete` key — `"complete" in result` is `false` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-018" |
| status-server-fetchers-019 | issues-request-timeout | The GlitchTip request never resolves until its signal aborts | The signal is not aborted at 11,999ms and is aborted at 12,000ms; the poll resolves `{ ok: false, items: [] }` and warns `timed out after 12000ms` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-019" |
| status-server-fetchers-020 | issues-cursor-walk | Page 1 is 100 issues with a `Link` header holding a `rel="next"` cursor `c1` with `results="true"`; page 2 is 1 issue whose next link says `results="false"`; the third response is page 1 again | Three requests: page 1, the same URL plus `&cursor=c1`, then page 1 again; `ok: true`, `complete: true`, 101 items — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-020" |
| status-server-fetchers-021 | issues-later-page-failure-incomplete | Page 1 is 100 issues with a next cursor; page 2 responds HTTP 502 | `ok: true`, `complete: false`, the 100 items already read — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-021" |
| status-server-fetchers-022 | issues-walk-bounds | Every page repeats the same cursor; separately, every page has a fresh cursor forever | Both walks end `ok: true`, `complete: false`; the endless walk stops at `MAX_PAGES` (20) requests — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-022" |
| status-server-fetchers-023 | issues-next-url-rebuilt | The `Link` header names an origin other than the configured one | Every request goes to the configured `GLITCHTIP_URL` origin — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-023" |
| status-server-fetchers-024 | issues-link-header-authoritative | A full page of 100 whose next link says `results="false"` | `complete: true`, exactly one request — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-024" |
| status-server-fetchers-025 | hogql-request-shape | `hogqlRows` with `POSTHOG_HOST` ending in `///`, response `{results:[["a",1]]}` | Resolves `{ ok: true, rows: [["a",1]] }`; the URL is `https://ph.example/api/projects/7/query/` and the body is `{ query: { kind: "HogQLQuery", query: "SELECT 1" } }` — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-025" |
| status-server-fetchers-026 | hogql-failures-returned | `hogqlRows` unconfigured; HTTP 500; a body with no `results`; a thrown `ECONNRESET` | Resolves `{ ok: false, error }` with `"PostHog is not configured"`, `"HTTP 500"`, `"response had no results"`, `"ECONNRESET"` — never throws — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-026" |
| status-server-fetchers-027 | hogql-shared-lease | A lease slot adopted via `attachHogqlLockState` holds a lease ending 500ms from now | The query's POST is not issued at 300ms, is issued after 600ms, and the slot is `0n` again afterwards; `hogqlLockState()` returns the adopted buffer — `telemetry-posthog-fetcher.test.ts` › "status-server-fetchers-027" |
| status-server-fetchers-028 | issues-interrupted-flag, issues-query-parameter | `fetchGlitchtipIssues(ENV, "is:resolved")` with page 1 full and a next cursor, page 2 HTTP 502; then a walk that repeats a cursor | The first walk is `ok: true`, `complete: false`, `interrupted: true`, with the 100 issues read, and its first URL carries `?query=is:resolved&limit=100`; the repeated-cursor walk is `complete: false` with no `interrupted` — `telemetry-glitchtip-fetcher.test.ts` › "status-server-fetchers-028" |
## Edge Cases

- **Null and empty input**: any one of GlitchTip's three env fields absent, or PostHog's three absent, produces a clean, immediate `{ ok: true, items: [] }` no-op rather than a partial attempt; a GlitchTip issues response of `[]` produces `{ ok: true, items: [], complete: true }`, distinct from an unconfigured no-op only in that the request was actually made.
- **Boundary values**: a GlitchTip page of exactly `PAGE_LIMIT` (100) issues with no usable `Link` header is treated as truncated (`complete: false`); 99 issues is treated as the whole answer. A `Link` header with `results="false"` makes even a full page the end. A walk stops at `MAX_PAGES` (20) pages, or at a repeated cursor, `complete: false`.
- **Concurrent access**: `glitchtip.ts` holds no module-level state, and each walk builds its own `AbortController`. `posthog.ts` holds two: `hogqlTail`, the thread's queue of HogQL requests, and the lease slot shared with the other thread, so every HogQL query in the process runs one at a time. A lease lapses after its holder's timeout plus a second, so a terminated worker cannot block the queue for longer than that.
- **Error states**: on GlitchTip, a failed page 1 (HTTP error, non-array body, thrown or aborted request) is `ok: false`; the same failure on a later page, or on the closing re-read of page 1, keeps the pages read as `ok: true, complete: false` (**issues-later-page-failure-incomplete**). On PostHog, `hogqlRows` returns each failure as `{ ok: false, error }`, and the poll resolves `ok: false` for a failed query or for a row with no usable value. Neither file retries; a failure is reported for the current poll and left to the next scheduled cycle (external).
- **Offline / disconnected state**: the GlitchTip walk is bounded by one 12 s `AbortController` and each PostHog query by its own `timeoutMs` (20 s for the KPI query), so an unreachable or hanging provider fails or truncates the poll within a fixed budget rather than hanging the caller. A PostHog query waiting on the lease is not counted against its timeout.
- **Moving list**: a GlitchTip issue that fires mid-walk moves to the top of the list and may appear on two pages; the walk keeps one copy per id and re-reads page 1 at the end to catch every mover.
- **Malformed `Link` header**: GlitchTip's `Link` value is a stringified Python set, not RFC 8288; `parseNextPage` finds the `rel="next"` entry wherever it sits, and a value with no such entry is `unknown`, which falls back to the page-size rule.
- **glitchtip-issue-schema-unverified**: `mapIssues`/`GlitchtipIssue` reads `id`, `title`, `culprit`, `level`, `count`, `userCount`, `firstSeen`, `lastSeen`, `permalink`, and `project` in the shapes declared, falling back per field as described above; the file's own comment records that this shape should be verified against a live GlitchTip instance. The response schema itself is owned by GlitchTip.
- **posthog-query-response-schema**: the KPI poll reads its four values from `results[0]`, columns 0 to 3, of a `{ results: [[...]] }` response. A body with no `results` array is a failed query (`response had no results`); a row whose columns are all unusable fails the poll, and a single unusable column is skipped. The response schema itself is owned by PostHog.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.GLITCHTIP_URL` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | GlitchTip instance base URL; trailing slashes are stripped before building the issues-endpoint URL. All three GlitchTip fields must be present or the fetcher no-ops. |
| `env.GLITCHTIP_API_TOKEN` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | Sent as `Authorization: Bearer` on the issues request. |
| `env.GLITCHTIP_ORG` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | GlitchTip organization slug interpolated into the issues-endpoint path. |
| `TIMEOUT_MS` | `number` (module constant, `glitchtip.ts`) | `12_000` | Deadline for the whole GlitchTip walk, every page and the closing re-read of page 1, via one `AbortController`. Not exported; not caller-configurable. |
| `MAX_PAGES` | `number` (exported module constant, `glitchtip.ts`) | `20` | Hard stop for the walk: 2,000 unresolved issues at `PAGE_LIMIT` per page. Reaching it ends the walk `complete: false`. |
| `PAGE_LIMIT` | `number` (exported module constant, `glitchtip.ts`) | `100` | Page size requested from GlitchTip (its own cap) and the threshold `complete-flag-by-page-size` compares a page's length against when the `Link` header is unusable. |
| `env.POSTHOG_HOST` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | PostHog project host; trailing slashes stripped before building the query-endpoint URL. All three PostHog fields must be present or the fetcher no-ops. |
| `env.POSTHOG_API_KEY` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | Sent as `Authorization: Bearer` on every HogQL query. |
| `env.POSTHOG_PROJECT_ID` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | Interpolated into the HogQL query-endpoint path. |
| `KPI_COLUMNS` | array (module constant, `posthog.ts`) | fixed 4 entries: `pageviews`/`24h`, `visitors`/`24h`, `pageviews`/`7d`, `visitors`/`7d` | The column order of the one KPI query's row. Not exported; not caller-configurable. |
| `KPI_QUERY` | `string` (module constant, `posthog.ts`) | one HogQL `SELECT` over `$pageview` events of the last 7 days | Answers all four KPIs at once. Not exported; not caller-configurable. |
| `KPI_TIMEOUT_MS` | `number` (module constant, `posthog.ts`) | `20_000` | Deadline for the KPI query, via its own `AbortController`, counted from when the query starts. Not exported; not caller-configurable. |
| `timeoutMs` | `number` (`hogqlRows` argument) | caller-supplied | Deadline for one HogQL query from any caller; the lease is held for this plus `HOGQL_LEASE_GRACE_MS`. |
| `HOGQL_LEASE_GRACE_MS` | `number` (module constant, `posthog.ts`) | `1_000` | How long past a query's own timeout its lease is held, so the abort can land and unwind. |
| `HOGQL_LEASE_POLL_MS` | `number` (module constant, `posthog.ts`) | `50` | How often a thread waiting on the other thread's lease looks again. |

## Deep Linking

Not applicable: neither file constructs or consumes an application deep link or universal link; every URL either file builds (the GlitchTip issues endpoint, the PostHog query endpoint) is a configured provider API host, not a link into this application.

## Localization

Not applicable: neither file emits a user-facing string; every string literal in either file is a diagnostic `console.warn` message (see Logging) or opaque provider data passed through unchanged.

## Accessibility Options

Not applicable: neither file renders UI, so Reduce Motion, Increase Contrast, and Differentiate Without Color have nothing to apply to.

## Feature Flags

Not applicable: neither file consults a feature-flag system; whether a fetcher is active is decided entirely by the presence of its three env credentials, per **unconfigured-no-op** and **posthog-unconfigured-no-op**.

## Analytics

Not applicable: neither file emits a self-referential analytics/telemetry event about its own invocation; producing the `AnalyticsMetricDTO` stream is the module's whole purpose, and that is fully specified under Behavioral Requirements, not a side-channel instrumentation event.

## Privacy

- **Data collected**: `glitchtip.ts` reads GlitchTip issue metadata (title, culprit, level, count, user count, timestamps, a permalink, and a project slug/name) — application error data, not end-user personal data. `posthog.ts` reads only aggregate, anonymous counts (`countIf`/`uniqIf`/`count()`/`uniq` over `$pageview` events); per the file's own comment, this is a deliberate privacy-first design — "no person data ever leaves PostHog into here." Both files also hold their provider's bearer credential (`GLITCHTIP_API_TOKEN`, `POSTHOG_API_KEY`) for the duration of one `fetch()` call.
- **Storage**: neither file writes to persistent storage; both are PURE with respect to storage, per each file's own header comment. Persisting a fetch's results is `collect.ts`'s and the `Store<T>` port's job, external to these two files.
- **Transmission**: every outbound call in both files sends its provider credential as an `Authorization: Bearer` header, never in a query string or request body; the transport scheme (`http://` vs `https://`) is whatever the caller-supplied `GLITCHTIP_URL`/`POSTHOG_HOST` value specifies — neither file validates or enforces `https://`.
- **Retention**: neither file caches, persists, or retains a credential or a fetched item beyond the lifetime of one `fetch()` call; there is no in-memory cache of any kind in either file.

## Logging

Subsystem: process `console` | Category: telemetry

| Event | Level | Message |
|-------|-------|---------|
| A GlitchTip issues page returned a non-`ok` HTTP response | warn | `` [telemetry] GlitchTip issues HTTP <status> `` |
| A GlitchTip issues page body parsed but was not an array | warn | `[telemetry] GlitchTip issues returned a non-array body — treating as a failed poll` |
| The GlitchTip issues walk timed out | warn | `` [telemetry] GlitchTip issues fetch timed out after <TIMEOUT_MS>ms `` |
| A GlitchTip issues request threw a non-timeout error | warn | `` [telemetry] GlitchTip issues fetch failed: <message> `` |
| GlitchTip re-read of page 1 failed after a multi-page walk | warn | `[telemetry] GlitchTip issues re-read of page 1 failed — reporting the walk incomplete` |
| The PostHog KPI query failed | warn | `` [telemetry] PostHog poll failed (<error>) `` |

## Platform Notes

- **React/Web** (source platform): both files live under `packages/web/packages/status-server/src/telemetry/fetchers/`, on Node's global `fetch`, `AbortController`, `setTimeout`/`clearTimeout`, and (for the HogQL lease) `SharedArrayBuffer` and `Atomics` — no framework dependency beyond the runtime globals. `../ports` and `../types` (this package's own modules) supply the `Fetcher`/`FetchResult` contract and `ErrorDTO`/`AnalyticsMetricDTO` shapes both files implement and produce.
- **SwiftUI**: a port models `GlitchtipEnv`/`PosthogEnv` as small `Sendable` structs of optional `String`s, `mapIssues`'s pure mapping as a free function over `Codable` structs mirroring `ErrorDTO`/`AnalyticsMetricDTO`, and the bounded single-attempt fetch via `URLSession` with `URLRequest.timeoutInterval` (or a `Task` wrapped in `withTimeout`/`Task.sleep` racing) in place of `AbortController`; the HogQL queue is a serial executor (an `actor` or a serial `Task` chain) so only one query is outstanding, and the GlitchTip cursor walk is a plain `for` loop over `await` calls under one deadline.
- **Compose**: the same structural mapping as SwiftUI — Kotlin `data class`es for the env/DTO shapes, a coroutine `withTimeout(...)` block per request in place of `AbortController`, a `Mutex` around each HogQL query so only one runs at a time, and a sequential `for` loop with `suspend` calls for the GlitchTip walk.
- **AppKit/UIKit**: identical mapping to SwiftUI's; `URLSession`'s `dataTask`/`data(for:)` with `URLSessionConfiguration.timeoutIntervalForRequest` is the direct analogue of each file's bounded, non-retried single attempt.
- **WinUI 3**: a .NET port uses `HttpClient` with a per-call `CancellationTokenSource` (timed via `CancelAfter`) as the `AbortController`/`AbortSignal.timeout` analogue — one `CancellationTokenSource` for the whole GlitchTip walk, and a fresh one per HogQL query; `System.Text.Json` replaces `res.json()`/`JSON.stringify` for both the GlitchTip issues array and the HogQL request/response bodies; the four `KPI_COLUMNS` entries become a fixed, non-configurable `IReadOnlyList<MetricSpec>` record array; HogQL queries are serialized with a `SemaphoreSlim(1)` (and a shared lease if the threads are separate processes), matching **posthog-sequential-execution** and **hogql-shared-lease**; and `GlitchtipEnv`/`PosthogEnv` map to small `record` types with nullable `string` properties, since neither carries behavior. No `Windows.Storage` or `ObservableCollection`/`INotifyPropertyChanged` counterpart applies — neither file persists anything or exposes an observable collection.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/fetchers/` | confirmed (1.1.1) |

## Design Decisions

- **Decision**: `glitchtipFetcher` never retries a failed or timed-out request, and one 12 s budget covers the whole walk rather than each page.
  **Rationale**: the source comment states this directly — the issues query can occasionally stall, a retry on a stalled provider would double that cycle's wait, and under sustained degradation stacked retries wedged the scheduler; a per-page budget would let more pages mean a longer cycle.
  **Approved**: pending
- **Decision**: a GlitchTip page of exactly `PAGE_LIMIT` (100) issues with no usable `Link` header is always treated as truncated (`complete: false`), even though 100 could coincidentally be the provider's true total.
  **Rationale**: the source comment explains the asymmetry directly — a reconciling store reads "absent from this poll" as "resolved upstream", which is sound for a whole answer and catastrophic for a truncated one; erring toward "may not have seen everything" costs a delayed resolve, while erring the other way costs a false all-clear during a live incident.
  **Approved**: pending
- **Decision**: a multi-page GlitchTip walk claims `complete` only after re-reading page 1, and a failure after page 1 returns the pages already read as `ok` but not `complete`.
  **Rationale**: the walk is not a snapshot: an issue that fires mid-walk moves to the top of the list, past the pages still to come. Reporting the walk complete would resolve every issue on the unread pages, and reporting it failed would mark a reachable GlitchTip with a large backlog as an outage.
  **Approved**: pending
- **Decision**: the next-page URL is rebuilt from the configured base and the cursor, never taken from the `Link` header.
  **Rationale**: the bearer token goes on every request, so a header value must not be able to choose where it is sent.
  **Approved**: pending
- **Decision**: PostHog's four KPIs come from one HogQL query on a 20 s timeout. They were once four sequential queries.
  **Rationale**: the source comment records the history — the four queries ran on a 10 s timeout each and PostHog answers in 2 to 30 s depending on load, so the batch usually died on the first query and a poll could spend most of 40 s doing it, which stalled the Overview.
  **Approved**: pending
- **Decision**: HogQL queries run one at a time for the whole process, queued per thread and then serialized across threads by a lease in a `SharedArrayBuffer`.
  **Rationale**: the API returns HTTP 503 under concurrent load and the callers do not know about each other. The monitor's worker thread loads its own copy of the module, so a per-thread queue left two queues. A lease (an expiry time) rather than a held flag, because a terminated worker could never clear a flag.
  **Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`separation-of-concerns` passes: `mapIssues` (GlitchTip), `parseNextPage` and `toMetricValue` are pure, network-free functions, and `mapIssues` is the one the module calls "the testable core, no network"; all I/O is isolated to `fetchGlitchtipIssues`, `hogqlRows` and the two fetchers' `fetch()` closures. `unit-test-coverage` passes: every conformance vector (status-server-fetchers-001 to -028) has a passing test, the GlitchTip ones in `telemetry-glitchtip-fetcher.test.ts` and the PostHog ones in `telemetry-posthog-fetcher.test.ts`. `explicit-error-handling` passes: every GlitchTip failure path resolves a distinct outcome (a failed page 1 is `ok: false`, a later failure is `ok` but incomplete and marked `interrupted`), and `hogqlRows` returns every PostHog failure as a named `error` string; a response with no `results` array is a failure, not an empty answer. `timeout-configuration` passes: the GlitchTip walk is bounded by one `AbortController` and each HogQL query by its own, both cleared in a `finally`. `retry-with-backoff` fails as written: neither file retries a failed request under any condition — a deliberate choice recorded in Design Decisions, not an oversight. `error-response-handling` passes: both files distinguish a non-`ok` HTTP response, a body that parses but is the wrong shape, and a thrown/aborted request, each mapped to its own outcome. `graceful-degradation` passes: `glitchtipFetcher` keeps the pages already read when a later page fails rather than discarding them, and both fetchers degrade every recognizable failure to `ok: false` or an incomplete result rather than throwing past their own boundary; a PostHog column that is unusable is skipped while the others are kept. `data-integrity` passes: the `complete` flag is set conservatively (a full page with no usable `Link` header, a repeated cursor, the page cap and a failed re-read of page 1 are never claimed complete), and a failed poll never resolves `ok: true` with a smaller-than-reality item set. `no-pii-in-logs` passes: every `console.warn` line names an HTTP status, a timeout duration, or an error message — never a credential, a token, or provider response body. `secure-transport` is `partial`: both files send their provider credential only via an `Authorization: Bearer` header, never a query string or body, but neither validates or enforces that `GLITCHTIP_URL`/`POSTHOG_HOST` is `https://` — the transport scheme is entirely whatever the caller configured.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Match recipe to source: cursor-paged GlitchTip walk, single-query PostHog poll with shared lease; drop four-query batch claims |
| 1.1.0 | 2026-10-04 | Mike Fullerton | Resolved posthog-malformed-result-shape marker as current behavior plus pending decision |
| 1.0.2 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation, documenting the GlitchTip issues fetcher and PostHog HogQL analytics fetcher: their env-gated no-op, single bounded fetch attempt, DTO mapping, the `complete`-flag contract with the reconciling errors store, and the PostHog batch's sequential, partial-success semantics. Records the open questions over both providers' unverified response schemas and PostHog's unsignaled malformed-shape case.
