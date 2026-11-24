---
id: 033e89fb-48b3-424d-984d-e4f29e9a6708
title: "Dashboard Queries"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Two cached reads for the analytics and errors dashboards that poll every 5s while the backend is refreshing, then every 60s, and fall back to 60s on error."
platforms:
  - typescript
  - web
tags:
  - dashboard
  - polling
  - tanstack-query
  - data-fetching
depends-on:
  - eb7e9eeb-86f3-4053-827a-ea259833c6ad
  - e8f3cd4d-e208-49db-a500-24d6f7b978f9
related:
  - e322fd0c-1552-4bd9-b129-3c809af3a972
references: []
approved-by: ""
approved-date: ""
---

# Dashboard Queries

## Overview

This module holds the dashboard's two cached reads of the status backend's dashboard routes, plus the rule that sets how often they poll. It exports three things:

- **the analytics-dashboard read** — takes an analytics range (`"24h"`, `"7d"` or `"30d"`) and an optional options object, requests `/analytics/dashboard?range=<range>` and returns the read result typed as the analytics dashboard response.
- **the errors-dashboard read** — takes an optional options object, requests `/errors/dashboard` and returns the read result typed as the errors dashboard response.
- **the poll-interval function** (`dashboardPollMs`) — takes a body, or `undefined`, and returns `5000` when the body's `refreshing` flag is true and `60000` otherwise.

Both routes answer at once with whatever the backend already has and keep refreshing behind the response, so the dashboard watches them fill in: it polls quickly while the body says `refreshing`, then at the board's usual pace. Both reads send their request through the dashboard's injected API client (see status-web-api ([adhsdk.ingredient.status.dashboard.api](cookbook:eb7e9eeb-86f3-4053-827a-ea259833c6ad))) and share one request helper that throws on a non-ok response. The response shapes come from the dashboard wire-type mirror ([adhsdk.ingredient.status.dashboard.telemetry.dashboard-types](cookbook:e8f3cd4d-e208-49db-a500-24d6f7b978f9)). Compare the sibling read that does not poll, status-web-hooks-use-uptime ([adhsdk.ingredient.status.dashboard.state.uptime](cookbook:e322fd0c-1552-4bd9-b129-3c809af3a972)).

Consumers: the board shell calls each read with `enabled` set from the open topic, so only the visible topic fetches and polls; the analytics view and the errors view call the same reads with no options, sharing the cache entry the board shell filled.

## Behavioral Requirements

### Poll interval

- **poll-filling**: The poll-interval function MUST return `5000` (milliseconds) when its argument is an object whose `refreshing` is true.
- **poll-settled**: The poll-interval function MUST return `60000` (milliseconds) when its argument's `refreshing` is false.
- **poll-no-data**: The poll-interval function MUST return `60000` when its argument is `undefined`, because no body has arrived yet to say the backend is refreshing.
- **poll-error-state**: Each read's interval MUST be `60000` while the read is in its error state (which, with the host cache's default retries, begins only once those retries are exhausted), even when the retained body says `refreshing`; the source's doc comment gives the reason: a failed read keeps the last body, and "a backend that has started failing would be polled every 5s for as long as it fails."
- **poll-after-recovery**: Each read's interval MUST return to being decided by the latest body's `refreshing` flag once a refetch succeeds and the read leaves the error state.
- **poll-interval-recomputed**: Each read MUST pass the interval as a function of the read's current state, so the interval changes after every settled fetch without the caller doing anything.

### The analytics-dashboard read

- **analytics-signature**: The analytics-dashboard read MUST accept a required `range` (an analytics range) and an optional second argument carrying an optional `enabled` boolean.
- **analytics-query-key**: The analytics-dashboard read MUST cache its result under a key combining `"analytics-dashboard"` and the `range`, so each range has its own cache entry.
- **analytics-request-path**: Each fetch MUST request the relative path `/analytics/dashboard?range=<range>`, which the client resolves against its base path (by default `/api`).
- **analytics-range-interpolation**: The `range` MUST be one of the three `AnalyticsRange` values (`"24h"`, `"7d"`, `"30d"`), which the type enforces; the source interpolates it into the query string by plain string conversion, with no percent-encoding and no runtime check, and the backend owns any further validation. A port MAY percent-encode the value.
- **analytics-keep-previous**: While a different range is loading, the analytics-dashboard read MUST keep returning the previous range's body as its data instead of dropping to an empty state; the source's comment says this is to "keep the last chart up while another range loads, instead of flashing skeletons."
- **analytics-focus-refetch**: The analytics-dashboard read MUST refetch when the window regains focus.

### The errors-dashboard read

- **errors-signature**: The errors-dashboard read MUST accept one optional argument, an options object carrying an optional `enabled` boolean.
- **errors-query-key**: The errors-dashboard read MUST cache its result under the single key `"errors-dashboard"`.
- **errors-request-path**: Each fetch MUST request the relative path `/errors/dashboard`, with no query string.
- **errors-no-placeholder**: The errors-dashboard read MUST NOT keep any previous body as placeholder data; it has no range to change.
- **errors-focus-refetch**: The errors-dashboard read MUST refetch when the window regains focus.

### Shared behavior of both reads

- **enabled-default**: Each read MUST fetch when `enabled` is omitted, `undefined` or `true`, and MUST NOT fetch when `enabled` is `false`.
- **return-value**: Each read MUST return the full read-result object unchanged (fields such as `data`, `error`, `isLoading`, `isError`, `isPlaceholderData`, `refetch`), adding no fields of its own.
- **client-source**: Each read MUST obtain its HTTP client through dependency injection, which resolves to the client supplied by the nearest override provider, or the same-origin default client (base path `/api`) when none is mounted.
- **request-init**: Each fetch SHOULD be issued through the client's raw request operation. The source passes no request options, so it is a default `GET` with no added headers, body or cancellation signal; a port MAY add an `Accept` header or cancel the request when its caller goes away.
- **success-body**: When the response is ok, the read MUST resolve with the parsed JSON body, typed as the response type without runtime schema validation.
- **non-ok-error**: When the response's `ok` flag is false, the read MUST throw an `Error` and enter its error state.
- **non-ok-message-detail**: The thrown error's message MUST be the message the response body carries when the body is JSON and yields a non-empty string: `error` when it is a string, otherwise `error.message`, otherwise `message`. A string `error` that is empty ends the search without trying `message`, and so does an `error.message` that is an empty string.
- **non-ok-message-fallback**: When the body yields no such message (not JSON, or none of the places above yields a non-empty string), the thrown error's message MUST be `status <code>` with the numeric HTTP status (for example `status 502`).
- **parse-failure**: When an ok response's body is not valid JSON, the rejection from parsing it MUST propagate as the read's error.
- **network-failure**: When the underlying request rejects (network failure or unreachable host), the rejection MUST propagate unchanged as the read's error.
- **stale-data-kept-on-error**: The reads MUST NOT clear the last good body when a refetch fails; the body stays in `data` beside the new `error`, which the poll-error-state rule relies on.
- **no-polling-when-disabled**: Each read MUST NOT poll while `enabled` is false, because the read is not fetching.
- **no-other-policy**: Each read MUST NOT set its own staleness duration, cache lifetime or retry count; those come from the host cache's defaults.
- **no-timeout**: Each read MUST NOT impose its own request timeout; a request that never settles leaves the read fetching until the client or browser ends it.
- **no-persistence**: Each read MUST NOT write dashboard data to any durable store; results live only in the in-memory shared cache.
- **shared-cache-entry**: Concurrent callers with the same key MUST share one cache entry; deduplicating their requests is done by the shared cache, not by this module, so two components calling the same read under one shared cache issue one request.
- **client-only**: This module MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

## Appearance

Not applicable — this is a data-fetching state, not a visual component.

## States

Not applicable — this is a data-fetching state, not a visual component.

## Accessibility

Not applicable — this is a data-fetching state, not a visual component.

## Conformance Test Vectors

`use-dashboards.dom.test.tsx` covers all 20 vectors, one test per vector id, against stub transports under a shared cache provider with retries disabled; the poll-pace vectors run under fake timers.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dash-001 | poll-filling | the poll-interval function called with a body whose `refreshing` is `true` | `5000` |
| dash-002 | poll-settled | the poll-interval function called with a body whose `refreshing` is `false` | `60000` |
| dash-003 | poll-no-data | the poll-interval function called with `undefined` | `60000` |
| dash-004 | poll-error-state, stale-data-kept-on-error | a read whose last body had `refreshing: true`, then a refetch returns `502` | the read is in its error state, `data` still holds the old body, and the next poll is scheduled 60000 ms out, not 5000 |
| dash-005 | analytics-request-path, enabled-default, request-init, client-source | the analytics-dashboard read called with `"7d"` and no options, default client; stub returns `200` and a valid body | exactly one fetch to `/api/analytics/dashboard?range=7d` with no request options; `data` holds the body |
| dash-006 | errors-request-path, errors-query-key | the errors-dashboard read called with no options; stub returns `200` and a valid body | exactly one fetch to `/api/errors/dashboard`, cached under `"errors-dashboard"` |
| dash-007 | enabled-default, no-polling-when-disabled | either read called with `{ enabled: false }` | no fetch is issued, and none after 60 seconds |
| dash-008 | analytics-keep-previous, analytics-query-key | the analytics-dashboard read first called with `"24h"` (resolved), then re-rendered with `"7d"` whose request is still pending | `data` still holds the `"24h"` body and `isPlaceholderData` is true until the `"7d"` response arrives |
| dash-009 | non-ok-error, non-ok-message-detail | stub returns `500` with body `{"error":{"message":"Unauthorized"}}` | the read's `error.message` is `Unauthorized` |
| dash-010 | non-ok-message-detail | stub returns `500` with body `{"error":"invalid range"}` | the read's `error.message` is `invalid range` |
| dash-011 | non-ok-message-fallback | stub returns `502` with body `<html>Bad Gateway</html>`, and separately `500` with body `{"error":{}}` | the read's `error.message` is `status 502`, and `status 500` |
| dash-012 | parse-failure | stub returns `200` with body `not json` | the read enters its error state with the JSON parse rejection |
| dash-013 | network-failure | stub transport rejects with `TypeError("Failed to fetch")` | the read's `error` is that `TypeError`, unchanged |
| dash-014 | shared-cache-entry | two components call the analytics-dashboard read with `"30d"` under one shared cache | one request is sent |
| dash-015 | poll-after-recovery, poll-interval-recomputed | a read whose body has `refreshing: true` (5000 ms), then a refetch returns `502`, then the next refetch returns a success body with `refreshing: true` | the interval is 5000, then 60000 while in the error state, then 5000 again with no action from the caller |
| dash-016 | analytics-focus-refetch | the analytics-dashboard read has settled; the window loses and regains focus | one extra fetch to the same path is issued |
| dash-017 | errors-focus-refetch | the errors-dashboard read has settled; the window loses and regains focus | one extra fetch to `/api/errors/dashboard` is issued |
| dash-018 | errors-no-placeholder | the errors-dashboard read is unmounted and a fresh caller mounts under a cleared cache while the request is pending | `data` is `undefined` and `isPlaceholderData` is false until the response arrives |
| dash-019 | return-value, success-body | either read called against a stub returning `200` and the JSON body `{"refreshing":false}` | the returned object is the full read result with `data` equal to the parsed body and no extra fields |
| dash-020 | enabled-default | either read first called with `{ enabled: false }`, then re-rendered with `{ enabled: true }` | no fetch while disabled; one fetch begins on the switch and polling starts |
## Edge Cases

- **Empty body**: an ok response whose body is `{}` or `null` MUST be returned as the read's `data` unchanged; the module performs no shape check, so `refreshing` is read from whatever arrived and a body with no `refreshing` makes the poll interval `60000`.
- **Boundary — range value**: a `range` outside `"24h"`, `"7d"`, `"30d"` is a type error for a typed caller. If an untyped caller passes one anyway, the source sends it as given (a value such as `7d&x=y` would add query parameters, so a port SHOULD percent-encode), and any error response surfaces through the non-ok path; the backend's own message (for example `invalid range`) is what the error carries.
- **Boundary — enabled toggling**: switching `enabled` from `false` to `true` MUST start the fetch and the polling; switching it back to `false` MUST stop both, while the cached body stays in the shared cache.
- **Error states — failure while refreshing**: a refetch failure after a body marked `refreshing` MUST drop the interval to 60 seconds and keep the old body; once a later fetch succeeds the interval follows the new body.
- **Error states — unreadable error body**: when the non-ok body is not JSON, the module MUST still throw, with the `status <code>` message.
- **Offline or disconnected state**: a request that rejects because the network is down MUST surface as the read's error with the transport's own message and MUST be polled again 60 seconds after the read enters its error state (with the host cache's default retries, that is after those retries are exhausted, which is why the vectors disable them), plus on window focus; the module has no offline detection and no backoff of its own.
- **Concurrent access**: two callers with the same key share one cache entry and one in-flight request through the shared cache; callers with different ranges hold separate entries and poll independently. The module holds no state of its own, and JavaScript is single-threaded, so no ordering rule is needed here.
- **Cancellation and timeouts**: the module passes no abort signal and sets no timeout; an unmounted caller does not cancel an in-flight request through this module.
- **Placeholder across ranges**: while a new range is loading the previous range's body is shown, so a view MUST check the read's placeholder flag if it needs to tell the two ranges apart; the module offers no other signal.
- **Background tab**: the interval is a poll setting handed to the shared cache; whether it keeps firing while the tab is hidden is that library's default, not something this module sets.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `range` (analytics-dashboard read) | `"24h"`, `"7d"` or `"30d"` | none — required | The window the analytics dashboard covers; part of the cache key and the request path. |
| `options.enabled` (both reads) | boolean | `true` | Set `false` to suspend fetching and polling, as the board shell does for a topic that is not open. |
| `FILLING_POLL_MS` | constant | `5000` | Poll interval while the latest body says `refreshing`. Not configurable. |
| `SETTLED_POLL_MS` | constant | `60000` | Poll interval otherwise, including while the read is in its error state. Not configurable. |
| status API client | `StatusApiClient` | the same-origin default (base path `/api`) | Injected through the dashboard's API provider; resolved with `useStatusApi`. |

The module reads no environment variables or settings keys.

## Deep Linking

Not applicable: this module requests two backend routes and registers no route or URL of its own.

## Localization

The module produces no text of its own except the fallback error message `status <code>`, a hardcoded English string used when the backend's error body carries no message; any backend message is passed through as sent. Views that show the read's error (the analytics view renders `query.error.message`) therefore show untranslated text. The string is not externalized in the source.

## Accessibility Options

Not applicable: the module has no visual output and responds to no display setting.

## Feature Flags

Not applicable: no read branches on a flag; the only switch is the caller-supplied `enabled` option, described under Configuration.

## Analytics

Not applicable: the module emits no events.

## Privacy

Not applicable: the module stores nothing and sends only a `GET` for aggregate dashboard data through the injected client; what the client attaches and what the response contains belong to the API client and the backend.

## Logging

Not applicable: no function in the module logs.

## Platform Notes

- **SwiftUI**: Start from an `@Observable` `@MainActor` model per dashboard holding the decoded response, an error and a loading flag. Fetch with `URLSession.shared.data(for:)`, build the analytics path with `URLComponents`, and decode into `Codable` structs. Replace the cache's interval with a `Task` loop: `try await Task.sleep(for:)` for 5 seconds while the body says `refreshing` and 60 seconds otherwise or after an error. Keep the previous body in the model while a failure or a new range loads. There is no built-in cache, so share one model per key to match the source's single request; refresh on `scenePhase` becoming `.active` to mirror the focus refetch, and pause the loop while the scene is not active, matching TanStack Query's default of not polling in a hidden tab. Gate the loop on a topic-visible flag in place of `enabled`.
- **Compose**: Start from a `ViewModel` exposing `StateFlow<UiState>` per dashboard, fetching with Ktor `HttpClient` or Retrofit and decoding with `kotlinx.serialization`. Drive the poll with a `flatMapLatest` over the range and a `while (isActive) { fetch(); delay(...) }` loop choosing 5000 ms or 60000 ms from the last state. Keep the last successful body in the `StateFlow` on failure. Refresh on `Lifecycle.Event.ON_RESUME` to approximate the focus refetch, and stop the loop while the lifecycle is below `STARTED` so polling pauses in the background like the source.
- **React/Web**: Source platform. `packages/web/packages/status-web/src/hooks/use-dashboards.ts` is the whole module, a pair of TanStack Query `useQuery` wrappers; it begins with the `"use client"` directive, so it runs only in client components under a React Server Components host. The poll interval is a function passed as `refetchInterval`, which TanStack Query calls with the query after each settle; `keepPreviousData` is the `placeholderData` for the analytics read; `refetchOnWindowFocus: true` restates the library default. The library's own defaults supply retry (three retries with backoff), the in-memory cache, request deduplication, and the fact that `refetchInterval` does not fire while `enabled` is false or the tab is hidden. A host MUST mount a `QueryClientProvider`, and MAY mount a `StatusApiProvider`. `errorMessage` and `useStatusApi` come from `src/api/client.ts`; the response types come from `src/telemetry/dashboard-types.ts`. Callers are `BoardShell.tsx` (with `enabled` set from the open topic), `AnalyticsView.tsx` and `ErrorsView.tsx`.
- **AppKit / UIKit**: Use the same `URLSession` and `Codable` stack as SwiftUI, driven from a `@MainActor` model shared by the view controllers. Schedule the poll with a `Timer` or a `Task` loop that re-arms after each response with the interval chosen from the latest body, invalidate it when the topic's view disappears or the app is in the background (the source does not poll in a hidden tab), and re-fetch on `NSApplication.didBecomeActiveNotification` or `UIApplication.willEnterForegroundNotification` to mirror the focus refetch.
- **WinUI 3**: Start from one view model per dashboard implementing `INotifyPropertyChanged` (or CommunityToolkit.Mvvm's `ObservableObject` with `[ObservableProperty]`) exposing the response record, `bool IsLoading`, and `Exception? Error`. Fetch in an `async Task LoadAsync(CancellationToken)` with a shared `HttpClient.GetAsync($"{basePath}/analytics/dashboard?range={range}")`; when `response.IsSuccessStatusCode` is false, read the body with `System.Text.Json` (`JsonDocument`) looking for `error` as a string, then `error.message`, then `message`, and throw `new HttpRequestException(message ?? $"status {(int)response.StatusCode}")`; otherwise deserialize with `JsonSerializer.DeserializeAsync<T>` using `JsonSerializerDefaults.Web`. Poll with a `PeriodicTimer` or a `DispatcherQueueTimer` whose `Interval` is reset after each load to `TimeSpan.FromSeconds(5)` while the response's `Refreshing` is true and `TimeSpan.FromSeconds(60)` otherwise or when `Error` is set; start it when the page's `Loaded` event fires or the topic opens and stop it on `Unloaded`, when the topic closes (the `enabled` equivalent), or while the window is deactivated, since the source does not poll in a hidden tab. Marshal updates onto the UI thread through `DispatcherQueue.TryEnqueue`. Differences from the source: .NET has no query cache, so register the view models as singletons shared by the board and the dashboard pages to get one request per key; `HttpClient.Timeout` defaults to 100 seconds whereas the source has none; keep the previous response when a reload fails, as the cache does; and refresh on `Window.Activated` for the focus refetch. Keep the previous range's response in the analytics view model until the new range's first response arrives.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/hooks/use-dashboards.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The poll interval is 5 seconds while the body says `refreshing` and 60 seconds otherwise.
**Rationale**: The comment in the source says both routes "answer at once with what the backend has and refresh behind the response, so a client watches them fill in." A fast poll is only worth its cost while something is filling in.
**Approved**: pending

**Decision**: A read in its error state is polled every 60 seconds even when its retained body says `refreshing`.
**Rationale**: The `refetchMs` doc comment: a failed read keeps the last body, and a body taken mid-refresh still says `refreshing`, so judging by the body alone would poll a failing backend every 5 seconds for as long as it fails. Nothing is filling in while the read fails.
**Approved**: pending

**Decision**: The analytics read keeps the previous range's body as placeholder data while a new range loads; the errors read has no placeholder.
**Rationale**: Source comment: "Keep the last chart up while another range loads, instead of flashing skeletons." The errors dashboard has a single key, so there is no previous key to show.
**Approved**: pending

**Decision**: The error message comes from the backend's body when it has one, else `status <code>`.
**Rationale**: `errorMessage` in `api/client.ts` reads both shapes the backend sends (`{ error: { message } }` from its error handler and `{ error: "..." }` from a route). Showing the backend's own words, such as `invalid range`, is more useful than a bare status code.
**Approved**: pending

**Decision**: The `range` is interpolated into the path without encoding or validation.
**Rationale**: The type `AnalyticsRange` allows only `"24h"`, `"7d"` and `"30d"`, none of which needs encoding (a port that accepts a looser type MAY encode), and the source leaves checking any other value to the backend, whose error the read would surface through the non-ok path. This avoids a second copy of the validation, at the cost of a round trip for a bad value.
**Approved**: pending

**Decision**: The `enabled` option exists so the board shell can fetch and poll only the topic that is open.
**Rationale**: `BoardShell.tsx` passes `enabled: topic === "errors"` and `enabled: topic === "analytics"`, so a hidden dashboard costs no requests; the views themselves call the reads with no options because they only mount when their topic is shown.
**Approved**: pending

**Decision**: No retry, staleness, timeout or persistence policy is set in this module.
**Rationale**: The module takes the shared cache's defaults, so one place sets the dashboard's retry and staleness behavior. A port must supply those defaults separately, which Platform Notes call out. A hung request has no ceiling, which is deliberate, prudent debt: it is worth paying down if a dashboard is ever observed stuck fetching, and the intended fix is an abort signal passed through the client's raw request operation (or a client-level timeout) that ends the request and lets the read enter its error state.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of Concerns**: The module holds no presentation and no data shaping. The base path and transport live in the API client, caching and the loading state machine in the shared cache, the message extraction in `errorMessage`, and the rendering in the analytics and errors views.

**Unit Test Coverage**: `use-dashboards.dom.test.tsx` beside the module exercises the poll-interval function, the error-state interval rule, the keep-previous behavior, the request paths, the error messages and focus refetch across all 20 conformance vectors.

**Explicit Error Handling**: A non-ok status, a network rejection and a JSON parse failure each reject the read function and surface through the read's `error`; none is swallowed, and the backend's message is carried when it has one.

**Timeout Handling**: The module sets no timeout and passes no abort signal, so a hung request leaves the read fetching until the browser ends it, though it leaves no inconsistent state behind.

**Graceful Degradation**: A failed refetch keeps the last good body on screen and drops the poll to the settled pace, so a failing backend is neither blanked nor hammered.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (use-dashboards.dom.test.tsx, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Required range to be an AnalyticsRange value with port encoding allowed, relaxed request-init, renamed single-threaded-ordering to shared-cache-entry, cited dashboard-types by UUID, added tags, retry and background-polling notes, a debt paydown path, and vectors dash-015 to dash-020. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from `use-dashboards.ts` |
