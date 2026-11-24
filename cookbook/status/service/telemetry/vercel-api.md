---
id: 60ff967b-b041-4723-913e-016fba7bae6d
title: "Vercel API Client"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Shared Vercel REST client for the telemetry readers: timed, cooldown-aware requests, JSON GET, project listing, and the production-project rules."
platforms:
  - typescript
  - web
tags:
  - telemetry
  - vercel
  - status-server
depends-on: []
related:
  - c116715f-2986-4554-a779-97e99d875c54
  - 55ffb81c-6a7d-4837-9180-0b5d3fe952ec
references:
  - https://vercel.com/docs/rest-api
approved-by: ""
approved-date: ""
---

# Vercel API Client

## Overview

`vercel-api.ts` is the Vercel REST client the telemetry readers share: Web Analytics (`dashboard/vercel-section.ts`) and runtime logs (`fetchers/vercel-runtime.ts`). It uses the same token as the deploy poll, so it shares that token's quota and honors the shared 429 cooldown from `@adh-sdk/deploy-platform/cooldown`. It exports one request primitive (`vercelRequest`), a JSON helper (`vercelGet`), a paged project lister (`listProjects`), two error classes (`VercelRateLimited`, `VercelHttpError`), and the rules that decide which projects are production sites (`productionDomain`, `isProductionProject`, `isNonProductionHost`). It performs network I/O only through the global `fetch`; it holds no state of its own, because the cooldown lives in the shared module.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a network client and a set of predicates, not a visual component.

## States

Not applicable — this is a stateless client, not a visual component. The only runtime state, the 429 cooldown, lives in the shared `provider-cooldown` module, not here.

## Accessibility

Not applicable — this is shared logic with no visual surface or interaction.

## Conformance Test Vectors

Every vector is a test in `packages/web/packages/status-server/test/vercel-api.test.ts`, titled with its id.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vercel-api-001 | production-domain ("the domain is the first alias that isn't a vercel.app one") | aliases `x.vercel.app`, `x.com`; and aliases `x.vercel.app` only | `x.com`; null |
| vercel-api-002 | production-project ("a project is production unless its name ends in staging or testing") | names `site-production`, `site-staging`, `site-testing`, `testing-production` | true, false, false, true |
| vercel-api-003 | production-project, non-production-host | name `x`, alias `staging.x.com` | false |
| vercel-api-004 | rate-limit-429, cooldown-first ("fails on a 429, records the shared cooldown, and then asks nothing while it lasts") | first call answered 429; then a second read | the first read fails and `rateLimitedUntil("vercel")` is not null; the second makes no `fetch` call |
| vercel-api-005 | caller-signal ("fails at the overall deadline, the project list included") | `fetch` that never resolves, abort by caller deadline of 50 ms | the read fails in under 5 seconds |
| vercel-api-006 | http-error (test "fails on any other error, so the store keeps what it had") | a non-429 error status | the read fails; nothing saved |
| vercel-api-007 | list-continuation | page 1 with `pagination.next` 1700, page 2 with next null | two requests; the second has `until=1700`; both pages' projects returned |
| vercel-api-008 | list-page-cap | every page returns a `next` | exactly 20 requests, then the collected projects are returned with no error |
| vercel-api-009 | method-selection, post-body | `init.json` `{a:1}` | POST, body `{"a":1}`, `Content-Type: application/json` |
| vercel-api-010 | team-scope, query-params | `VERCEL_TEAM_ID` `team_1`, params `{limit:"5"}` | URL carries `teamId=team_1` and `limit=5` |
| vercel-api-011 | http-error | status 500, body `oops` | `VercelHttpError` with `status` 500, `body` `oops`, message `Vercel <path> HTTP 500` |
| vercel-api-012 | non-production-host | `STAGING.x.com`; `x.com`; null | true; false; false |
| vercel-api-013 | production-project | name `Site-STAGING` | false |
| vercel-api-014 | json-get | 200 response with body `not json` | rejects |
| vercel-api-015 | call-timeout, caller-signal | `fetch` that never resolves, no caller `signal`; then the same with a caller `signal` that never aborts; `AbortSignal.timeout` replaced by a signal the test aborts | `AbortSignal.timeout` is asked for `CALL_TIMEOUT_MS` (20,000 ms), and aborting that signal rejects the call with the timeout error in both cases; the caller signal does not replace it |
| vercel-api-016 | extra-headers | `init.headers` `{Authorization: "Bearer other"}` | the request carries `Authorization: Bearer other`, not the one built from `env` |
| vercel-api-017 | query-params | `VERCEL_TEAM_ID` `team_1`, params `{teamId: "team_2"}` | URL carries `teamId=team_2` once |
| vercel-api-018 | cooldown-first | `rateLimitedUntil("vercel")` returns a time | `VercelRateLimited` with message `Vercel rate limited until <ISO time>`, and `fetch` is not called |
| vercel-api-019 | list-errors | page 1 returns projects with a `next`; page 2 answers 500 | `listProjects` rejects with `VercelHttpError`; page 1's projects are not returned |
## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.VERCEL_API_TOKEN` | string, optional | none | Bearer token; shared with the deploy poll and its quota. |
| `env.VERCEL_TEAM_ID` | string, optional | none | Sent as `teamId` when non-empty. |
| `VERCEL_API` | string (exported constant) | `https://api.vercel.com` | Base URL. |
| `CALL_TIMEOUT_MS` | number (private constant) | 20,000 | Per-call timeout. |
| `MAX_PROJECT_PAGES` | number (private constant) | 20 | Page cap of `listProjects`; page size 100. |
| `signal` | `AbortSignal`, optional | none | Caller cancellation or deadline. |
| `init` | `{ json?, headers? }` | `{}` | Makes the call a POST with a JSON body; extra headers. |

## Deep Linking

Not applicable: the module calls an external API and defines no routes or URLs of its own.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `Vercel rate limited until <ISO time>` | `VercelRateLimited` message when a cooldown is active |
| none (hardcoded) | `Vercel rate limited` | `VercelRateLimited` message after a 429 |
| none (hardcoded) | `Vercel <path> HTTP <status>` | `VercelHttpError` message |

These are developer-facing error messages in English with no string table; callers decide what a person sees.

## Accessibility Options

Not applicable: no visual output.

## Feature Flags

Not applicable: the source reads no flag. Whether Vercel is used at all is decided by the callers through their configuration.

## Analytics

Not applicable: the module emits no event or metric.

## Privacy

- **Data collected**: The bearer token (`VERCEL_API_TOKEN`) and optional team id are credentials sent to Vercel; responses carry project names, ids and aliases.
- **Storage**: The module stores nothing; the token is supplied by the caller in `env`.
- **Transmission**: The token is sent only in the `Authorization` header to `https://api.vercel.com`. The query string carries `teamId` and caller parameters, not the token. `VercelHttpError` keeps the response body, which a caller could log.
- **Retention**: None.

## Logging

Not applicable: `vercel-api.ts` contains no log call. The cooldown module it calls writes a `console.error` line when it records a 429.

## Platform Notes

- **SwiftUI**: Port with `URLSession` and `async/await`: `URLRequest.timeoutInterval = 20` (note it is an idle timeout; use `Task` with a deadline or `withThrowingTaskGroup` for a hard 20 seconds), `URLComponents` for query items, `JSONSerialization` or `JSONDecoder`. Read the cooldown before each request from a lock-guarded or actor-isolated timestamp shared with the deploy poll.
- **Compose**: Port with OkHttp or Ktor: `OkHttpClient.Builder().callTimeout(20, SECONDS)` gives a whole-call timeout, `HttpUrl.Builder` for the query, `kotlinx.serialization` for JSON, and an `AtomicLong` for the cooldown expiry. Model `VercelRateLimited` and `VercelHttpError` as exception classes.
- **React/Web**: The source is `src/telemetry/vercel-api.ts` in `status-server`, using the global `fetch` and `AbortSignal.timeout` / `AbortSignal.any` (Node 20 or later). The cooldown is a `SharedArrayBuffer` shared between the API thread and the monitor worker thread.
- **AppKit / UIKit**: No UI. Same port as SwiftUI.
- **WinUI 3**: Port as a class library around a single `HttpClient` (reused, created through `IHttpClientFactory`): `HttpClient.Timeout` or a `CancellationTokenSource(TimeSpan.FromSeconds(20))` linked with the caller token through `CancellationTokenSource.CreateLinkedTokenSource` mirrors `AbortSignal.any`. Build the URL with `UriBuilder` and `System.Web.HttpUtility.ParseQueryString`; set `AuthenticationHeaderValue("Bearer", token)`; send POST bodies with `JsonContent.Create` or `StringContent` as `application/json`. Return `HttpResponseMessage` unread (`HttpCompletionOption.ResponseHeadersRead`) to keep streaming. Throw `VercelRateLimited` and `VercelHttpError` as `Exception` subclasses, read `Retry-After` from `response.Headers.RetryAfter` (delta or date), and keep the cooldown in a `static long` read with `Interlocked.Read` and written with `Interlocked.CompareExchange` to keep the furthest expiry. `Task`/`async` throughout. Expose project listing as `IAsyncEnumerable` only if you keep the 20-page cap. In ASP.NET Core, register it as a typed client in the host's service collection.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/vercel-api.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One request primitive shared by Web Analytics and runtime logs.
**Rationale**: The header comment says both readers share the deploy poll's token, quota and 429 cooldown; one client keeps that policy in one place.
**Approved**: pending

**Decision**: Check the shared cooldown before every call, not only a load's first.
**Rationale**: The `vercelRequest` doc comment: several workers run at once, and without the per-call check one 429 leaves the rest hitting a throttled API, whose 429s push the cooldown further out.
**Approved**: pending

**Decision**: `signal` adds to the per-call timeout rather than replacing it.
**Rationale**: A caller deadline must not remove the 20-second ceiling; `AbortSignal.any` combines them.
**Approved**: pending

**Decision**: Return the raw `Response` from `vercelRequest`.
**Rationale**: A caller can stream a large body; `vercelGet` is the parsed variant.
**Approved**: pending

**Decision**: Cap project listing at 20 pages with no signal when it truncates.
**Rationale**: Known debt: the cap bounds the page loop, so one read cannot spend an unbounded share of the shared token's quota. The source states no reason for the number 20, and nothing tells a caller that the list was cut short. Revisit when an account passes 2,000 projects.
**Approved**: pending

**Decision**: Send the request even when `env.VERCEL_API_TOKEN` is undefined, and let Vercel's 401 surface as `VercelHttpError`.
**Rationale**: The source leaves the missing-token check to the callers, which skip the call when there is no token; the client sends `Bearer undefined` rather than failing before `fetch`. This is recorded as the observed behavior and has not been chosen over a typed error thrown before the call.
**Approved**: pending

**Decision**: Drop the `-staging` and `-testing` projects before anything is counted or queried.
**Rationale**: Every site is three Vercel projects (`x-production`, `x-staging`, `x-testing`) and analytics runs only on the first, so the other two are not sites to report on.
**Approved**: pending

**Decision**: Match the staging and testing suffix only at the end of the name.
**Rationale**: The `isProductionProject` doc comment: `testing-production` is the production site of a site about testing.
**Approved**: pending

**Decision**: Make `productionDomain` a first filter and fallback, not the answer.
**Rationale**: Aliases belong to the latest production deployment, so a queued deployment leaves only `*.vercel.app`; `loadVercelTraffic` asks the domains API for the real answer.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | partial | Access Patterns |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | Security |

`separation-of-concerns` passes because the client holds only transport, the 429 policy delegated to the shared cooldown module, and the production predicates. `unit-test-coverage` passes: `vercel-api.test.ts` covers `vercelRequest`, `vercelGet`, `listProjects` and the production predicates, one test per vector 001 to 019. `timeout-configuration` passes with the 20-second per-call timeout. `rate-limit-handling` passes through the cooldown check and the 429 branch. `retry-with-backoff` fails because the client never retries; it only refuses calls during a cooldown. `pagination-support` is partial: it follows `pagination.next` but stops silently at 20 pages. `secure-transport` passes because the base URL is HTTPS and the token goes only in the `Authorization` header.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (vercel-api.test.ts, 19 of 19 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added related links and the Vercel REST docs reference, rewrote token-presence as MUST statements, moved rationale out of requirements into Design Decisions, labeled the page cap as known debt, and added vectors 015-019 for the timeout ceiling, extra headers, query params, cooldown message and list errors. |
