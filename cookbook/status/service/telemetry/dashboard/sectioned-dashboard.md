---
id: af0bacb9-bc1f-4773-85f5-35e33ae590ab
title: "Sectioned Dashboard"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Stale-while-revalidate cache for a dashboard of independently slow sections: reads never wait, each section has its own schedule and backoff, and settle awaits a refresh."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - caching
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Sectioned Dashboard

## Overview

`sectionedDashboard` builds a stale-while-revalidate cache for a dashboard made of independently slow sections. The status server uses it for the PostHog, Vercel and GlitchTip providers and the per-site error health, so a slow provider never holds back the others.

The design follows the source's header comment. PostHog queries run one at a time (its API answers 503 under concurrency) and take 2 to 30 seconds each, so a cold dashboard can take a minute. That is longer than the rewrite proxy in front of the server will wait, and it would hold a request open when most sections could already be on screen. So `read` never waits. It answers at once with what is known and starts a refresh if one is due. Each section publishes as it finishes, and the client polls while `refreshing` is true to watch them fill in.

Refreshes are started by reads, not timers, so an idle dashboard costs no provider quota. Each section keeps its own schedule: a refresh re-runs only the sections that are due, so one failing section is retried on its own, with backoff, while healthy sections wait out their full TTL.

The module exports `sectionedDashboard`, `emptySections` and the types `DashboardSection`, `DashboardSections`, `DashboardLoaders`, `DashboardRead`, `SectionedDashboard` and `SectionedDashboardOptions`. State lives in memory in the closure of one dashboard instance.

## Behavioral Requirements

**Section shape**

- **section-fields**: A `DashboardSection<T>` MUST carry `data` (the last good answer or `null`), `error` (why the latest attempt failed, or `null`) and `updatedAt` (when `data` was fetched, an ISO string, or `null`).
- **section-initial-state**: Before any attempt finishes, every section MUST read as `{ data: null, error: null, updatedAt: null }`.
- **empty-sections**: `emptySections(names)` MUST return an object with one section in that initial state for each name. The dashboard set uses it as the answer for an unconfigured provider.
- **read-shape**: `read(key)` MUST return `{ refreshing, sections }`, with `sections` holding one `DashboardSection` per name in `opts.sections`.
- **read-copy**: `read` MUST return a new `sections` object on each call (a shallow copy), so a caller holding an earlier result does not see later publishes. A section object is replaced, not mutated, when it is published.

**Reads never wait**

- **read-never-waits**: `read` MUST return synchronously, never waiting on a loader.
- **read-starts-refresh**: When `refreshing` is false and at least one section is due, `read` MUST start a refresh for exactly the due sections and return with `refreshing` true, except when the loaders builder throws (see `loaders-builder-throws`).
- **read-cold-start**: The first `read` of a key has every section due (`dueAt` 0), so it MUST start a refresh of all sections.
- **read-no-double-refresh**: While a refresh for a key is in flight, further reads of that key MUST NOT start another.
- **read-nothing-due**: When no section is due, `read` MUST start nothing and return `refreshing` false.
- **section-due-rule**: A section is due when its `dueAt` is less than or equal to `now()`.
- **keys-independent**: State is kept per key; a read or refresh of one key MUST NOT affect another key's sections, schedules or refresh flag.
- **keys-bounded**: Keys MUST come from a bounded set. State per key is created on first read and never removed.

**Refresh**

- **loaders-built-per-refresh**: `opts.loaders(key)` MUST be called once at the start of each refresh, so loaders can compute a time window from the current time.
- **only-due-loaders-run**: A refresh MUST call only the loaders of the sections that were due when it started.
- **concurrency-default**: Due sections MUST run strictly one after another unless `concurrency` is set. The default is 1.
- **concurrency-limit**: With `concurrency` greater than 1, at most that many loaders MUST run at once, taken in order.
- **section-publish-on-finish**: Each section MUST be published to state as soon as its own loader settles; with the default `concurrency` of 1 that is before the next section starts.
- **success-publish**: When a loader resolves, the section MUST become `{ data, error: null, updatedAt }` where `updatedAt` is `new Date(now()).toISOString()`.
- **failure-keeps-data**: When a loader rejects, the section MUST keep its prior `data` and `updatedAt` and take `error` set to the error's `message`, or `String(err)` for a non-`Error` value.
- **failure-isolated**: A failing loader MUST NOT stop the remaining due sections from running.
- **failure-logged**: Each failed section MUST be logged once with `console.warn` as `[telemetry] dashboard section <name> (<key>) failed: <error>`.
- **refresh-flag**: `refreshing` MUST be true from the moment a refresh starts until all of its due sections have settled, and false after.

**Scheduling and backoff**

- **ttl-after-success**: After a successful section, its `dueAt` MUST be `now() + ttlMs` and its failure count MUST reset to 0.
- **retry-default**: `retryMs` defaults to 60,000 ms.
- **retry-clamp**: The effective retry interval MUST be `min(retryMs, ttlMs)`.
- **retry-after-failure**: After a failed section, its `dueAt` MUST be `now() + min(retryMs * 2^(failures - 1), ttlMs)`, where `failures` counts failed attempts in a row including this one. The waits run retryMs, 2 times retryMs, 4 times retryMs and so on, never above `ttlMs`.
- **retry-only-failing**: A section that failed MUST be retried on its own schedule without re-running sections that succeeded.
- **incomplete-short-answer**: When `incomplete(name, data)` returns true for a resolved answer, the section MUST be published as a success (`error` null, data kept) but scheduled and counted like a failure, so it is retried after the backoff instead of the full TTL. The Vercel dashboard uses this when `data.failed > 0 || data.incomplete > 0`.
- **incomplete-optional**: When `incomplete` is not given, every resolved answer MUST count as complete.
- **loaders-builder-throws**: If `opts.loaders(key)` throws, the failure MUST be logged with `console.warn` as `[telemetry] dashboard refresh (<key>) failed: <message>`, every due section that did not settle MUST be scheduled as a failure, and `refreshing` MUST return to false. The builder runs before the first `await` of the refresh, so all of this happens inside the `read` call that triggered it and that `read` already returns `refreshing` false.
- **wedge-guard**: A refresh that ends, whether its loaders resolved, rejected or the builder threw, MUST clear the `refreshing` flag in its `finally` step. A loader that never settles is the loader's own responsibility (see the edge case "Loader that never settles").

**settle**

- **settle-contract**: `settle(key, timeoutMs)` MUST resolve `true` when no refresh is in flight for the key, and otherwise wait for the in-flight refresh or the timeout, whichever comes first.
- **settle-result**: After waiting, `settle` MUST resolve `!state.refreshing`: `true` when the refresh finished, `false` when the deadline passed first.
- **settle-never-starts**: `settle` MUST NOT start a refresh. A key never read resolves `true` at once and builds no loaders.
- **settle-negative-timeout**: A `timeoutMs` below 0 MUST be treated as 0.
- **settle-timer-cleared**: `settle` MUST clear its timeout timer when it returns, so a finished wait leaves no pending timer.
- **settle-use**: A caller that wants a warm answer reads, settles, then reads again. A server-side reader such as `/report` uses this so it does not push the polling that `read` implies onto its own client.

**Concurrency and ordering**

- **single-threaded-state**: State changes happen in ordinary JavaScript turns with no shared threads, so the check of `refreshing` and the start of a refresh in `read` cannot interleave with another `read`.
- **inflight-cleanup**: The in-flight promise MUST be cleared when the refresh ends, but only if it is still the same promise, so a later refresh's handle is never cleared by an earlier one.

**Side effects**

- **side-effects**: The module's only side effects are calls to the supplied loaders, `console.warn` on failures and `setTimeout` inside `settle`. It touches no files, network or storage itself; the loaders do.
- **clock-injection**: `now` defaults to `Date.now` and MAY be replaced for tests.

## Appearance

Not applicable — this is a cache and scheduler, not a visual component.

## States

Not applicable — this is a cache and scheduler, not a visual component. Its runtime states are described below instead of in a visual-state table.

Per key: **idle** (`refreshing` false, `inflight` null), **refreshing** (`refreshing` true, `inflight` set). A read in idle with a due section moves the key to refreshing. A refresh finishing moves it back to idle. Per section: **never fetched** (`dueAt` 0), **fresh** (`dueAt` in the future after a success), **backing off** (`dueAt` in the future after a failure or incomplete answer), and **due** (`dueAt` at or before now).

## Accessibility

Not applicable — this is a cache and scheduler, not a visual component.

## Conformance Test Vectors

The vectors use the test file `telemetry-sectioned-dashboard.test.ts`: `ttlMs` 10,000, `retryMs` 1,000, sections `a` and `b`, a fake clock starting at 1,000,000. Every vector is backed by a test in that file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sectioned-001 | read-never-waits, read-starts-refresh, read-cold-start, section-initial-state, loaders-built-per-refresh | Test "a cold read answers immediately and starts a refresh": loaders never resolve; `read("k1")` | `refreshing` true; `a` is `{ data: null, error: null, updatedAt: null }`; loaders built once |
| sectioned-002 | concurrency-default, section-publish-on-finish, refresh-flag | Test "publishes each section as it finishes, in order, one at a time": `a` pending, `b` a spy; read, then resolve `a` | `b` not called until `a` resolves; then `refreshing` false, `a.data` 1, `b.data` "two" |
| sectioned-003 | read-no-double-refresh | Test "reads during a refresh never start another": three reads while `a` pending | Loaders built once |
| sectioned-004 | ttl-after-success, section-due-rule, read-nothing-due | Test "does not refresh again inside the TTL, and does after it": read, advance 9,999 ms, read; advance 1 more ms, read | First later read `refreshing` false, built once; after 10,000 ms total `refreshing` true, built twice |
| sectioned-005 | failure-keeps-data, failure-isolated, failure-logged | Test "a failed section keeps its last good data, reports why, and the rest still load": `a` resolves 1, then throws `HTTP 504` after the TTL | `a` is `{ data: 1, error: "HTTP 504" }`; `b` is `{ data: "x", error: null }`; the source logs one `console.warn` for `a` (the test silences it and does not assert on it) |
| sectioned-006 | retry-after-failure, retry-default | Test "retries sooner after a failure than after a success": `a` always rejects; advance 999 ms, read; advance 1 ms, read | Built once after 999 ms; built twice at 1,000 ms |
| sectioned-007 | retry-only-failing, retry-after-failure | Test "retries only the failing section, backing off with each failure in a row": advance 1,000, read; advance 1,999, read; advance 1, read | Calls to `a` and `b`: [2, 1] after the first retry; still 2 for `a` at +1,999 ms; [3, 1] after the last advance |
| sectioned-008 | incomplete-short-answer | Test "an answer known to be short is shown as a success but retried like a failure": `incomplete` true for `a` when data is -1; read, then advance 1,000 | `a` is `{ data: -1, error: null }`; loaders built again at 1,000 ms |
| sectioned-009 | keys-independent | Test "keeps keys separate": `read("k1")`, `read("k2")` | Loaders built for `["k1"]` then `["k2"]` |
| sectioned-010 | loaders-builder-throws, wedge-guard | Test "a loaders() builder that throws cannot wedge the key refreshing forever": `loaders` throws `bad build`; read, flush, read | Second read `refreshing` false; the source logs `[telemetry] dashboard refresh (k) failed: bad build` (the test silences `console.warn` and does not assert on it) |
| sectioned-011 | settle-never-starts, settle-contract | Test "resolves true at once when nothing was ever read, and never starts a refresh": `settle("k1", 1000)` on a fresh dashboard | Resolves `true`; no loaders built |
| sectioned-012 | settle-contract, settle-result | Test "waits for the refresh in flight, then a second read has the data": read, `settle("k1", 60000)`, resolve `a` | Resolves `true`; next read has `a.data` 1 and `b.data` "two", `refreshing` false |
| sectioned-013 | settle-result, settle-timer-cleared | Test "gives up at the deadline and reports the key still refreshing": `a` never resolves; `settle("k1", 5000)`; advance fake timers 5,000 ms | Resolves `false`; a following read has `refreshing` true |
| sectioned-014 | settle-contract | Test "resolves true once the refresh has finished, without waiting": read, flush, `settle("k1", 60000)` | Resolves `true` |
| sectioned-015 | empty-sections | `emptySections(["a", "b"])` | `{ a: { data: null, error: null, updatedAt: null }, b: { data: null, error: null, updatedAt: null } }` |
| sectioned-016 | read-copy | Read twice around a publish, keeping the first result | The first result's sections are unchanged after the publish |
| sectioned-017 | retry-clamp | `ttlMs` 500, `retryMs` 1,000, a loader that fails | Next attempt is due at 500 ms, not 1,000 ms |
| sectioned-018 | failure-keeps-data, success-publish | A section fails after a success, then succeeds again | After the failure `error` is set with old `data` and `updatedAt`; after the success `error` is `null` and `updatedAt` is the new time |
| sectioned-019 | concurrency-limit | `concurrency` 2 with three due sections and pending loaders | Two loaders start at once; the third starts when one finishes |
| sectioned-020 | failure-keeps-data | A non-`Error` rejection such as the string `"boom"` | `error` is `"boom"` |

## Edge Cases

- **Empty or missing input**: `sections` is a list of names; with an empty list nothing is ever due, so `read` returns `{ refreshing: false, sections: {} }`. This is not exercised by a test; it follows from the due filter.
- **Unknown key**: Any `K` value creates state on first read. The type `K extends string` bounds the set at compile time only; a caller outside the type system can grow the map without limit. Callers MUST use a bounded enum, as the source comment says.
- **Failure before any success**: A section that has never loaded and fails keeps `data` `null` with `error` set and `updatedAt` `null`.
- **Repeated failures**: The wait doubles each time and is capped at `ttlMs`; after a success the count resets to 0.
- **Backoff exponent**: `2 ** (failures - 1)` grows without bound in the exponent but the result is capped by `Math.min` with `ttlMs`, so a long failure run cannot overflow the interval.
- **Incomplete answer repeated**: A section that keeps coming back incomplete is retried on the backoff schedule. Its `data` is replaced each time since each attempt publishes as a success.
- **`concurrency` of 0 or less**: `mapLimit` starts no workers, so no loader runs and the refresh ends at once. The `finally` step then marks every due section as a failure, so each is retried after the backoff and no section ever loads. The source does not validate `concurrency`. The caller owns passing a positive value; the callers in the dashboard set pass none or rely on the default of 1.
- **Loader not a function**: Calling `loaders[name]()` on a missing entry throws a `TypeError`, which the per-section handler catches as a failure of that section. Not exercised by a test.
- **Loader that never settles**: The refresh never ends, `refreshing` stays true, and later reads never start another refresh for that key. The source has no per-loader timeout; loaders own their own deadlines (the PostHog and Vercel loaders use provider cooldowns and HTTP failure handling in their own modules). `settle` still returns `false` at its deadline.
- **Loaders builder throws**: Covered by `loaders-builder-throws`. Also, because the failure is logged by the outer `catch`, no section-level `console.warn` appears.
- **Concurrent reads**: Reads are synchronous and JavaScript is single-threaded, so only one read at a time checks and starts a refresh. A second read during a refresh returns the current partial state.
- **Concurrent settle calls**: Several `settle` calls on one key MAY wait on the same in-flight promise; each has its own timer, cleared on return.
- **Settle after the refresh ended but before cleanup**: `settle` returns `!state.refreshing`, which is `true` once the refresh's `finally` step has run.
- **Offline or provider unavailable**: The module has no network code. An unreachable provider shows as a rejecting loader, handled by failure-keeps-data and backoff.
- **Process restart**: State is in memory only, so a restart makes every section cold again and the first read refreshes all of them.
- **Clock moves backwards**: `dueAt` is compared with `now()`, so a clock set back delays the next refresh; the module does not guard against it. Not exercised by a test.

## Configuration

Not applicable beyond the options below: the module reads no environment variables or settings files; everything comes from `SectionedDashboardOptions`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ttlMs` | number | required | How long a fully successful section is good for, and the cap on every retry wait |
| `retryMs` | number | 60,000, clamped to `ttlMs` | First retry wait after a failed or incomplete section; doubles with each further failure in a row |
| `concurrency` | number | 1 | How many due sections run at once; 1 runs strictly in order |
| `sections` | readonly array of section names | required | The section names, in refresh order |
| `loaders` | function from key to a record of loader functions | required | Built per refresh, one async function per section |
| `incomplete` | function from section name and data to boolean | none (every answer is complete) | True for an answer that is shown but known to be short |
| `now` | function returning epoch ms | `Date.now` | Clock, replaceable in tests |

The dashboard set passes `ANALYTICS_TTL_MS` for the PostHog, Vercel and site-health dashboards, and `ERRORS_TTL_MS` for GlitchTip. The Vercel dashboard supplies `incomplete`.

## Deep Linking

Not applicable: the module has no URLs or routes. The routes that serve its output live in `routes/telemetry-dashboards.ts`.

## Localization

Not applicable beyond a pass-through: the module holds no display strings of its own. The `error` field carries the loader's error message verbatim, in whatever language the provider code produced, and the `console.warn` text is an English log line prefixed `[telemetry]`.

## Accessibility Options

Not applicable: the module is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the module emits no events. It caches the answers of dashboards that report analytics.

## Privacy

Not applicable as a data handler: the module stores whatever the loaders return, in memory only, and sends nothing. Loader error messages reach clients in the `error` field and the server log; the module does not filter them, so a loader that puts a credential in an error message would expose it. The loaders own what their messages contain.

## Logging

The module logs failures with `console.warn` and nothing at other levels.

| Event | Level | Message |
|-------|-------|---------|
| A section loader rejected | warn | `[telemetry] dashboard section <name> (<key>) failed: <error>` |
| The refresh failed outside a section (the loaders builder threw, or `mapLimit` rejected) | warn | `[telemetry] dashboard refresh (<key>) failed: <message>` |

## Platform Notes

- **SwiftUI**: Port as a Swift `actor` (or a `@MainActor` class) holding a dictionary from key to state. `read` becomes a synchronous method that returns a struct of sections and a flag, and starts a detached `Task` for the refresh. Run due sections with a `TaskGroup` limited to `concurrency`, or sequentially with a `for` loop for the default of 1. Schedules (`dueAt`) MAY use a monotonic clock such as `ContinuousClock`, but `updatedAt` MUST come from an injected `() -> Date` wall-clock source. A SwiftUI view polls the read while `refreshing` is true, for example with a `.task` loop and `Task.sleep`.
- **Compose**: Port as a class holding a `ConcurrentHashMap` of key state, with refreshes launched in a `CoroutineScope` and `Semaphore(concurrency)` for the limit. `settle` is `withTimeoutOrNull(timeoutMs) { job.join() }` returning whether the job completed. Expose sections as `StateFlow` if the UI collects them, instead of polling.
- **React/Web**: This is the source platform. `sectioned-dashboard.ts` in `packages/web/packages/status-server/src/telemetry/dashboard/` is plain TypeScript. It depends on `mapLimit` from `@adh-sdk/deploy-platform/util`, which starts `min(limit, count)` workers that take items in order; that is how `concurrency-limit` is met. Client code polls the dashboard route while `refreshing` is true.
- **AppKit / UIKit**: Use the same Swift port. Poll on a `Timer` or `Task.sleep` loop while `refreshing`, and update the views on the main actor. Keep the refresh work off the main thread.
- **WinUI 3**: Port as a C# class with a `ConcurrentDictionary<string, KeyState>` and per-section schedule records. `read` returns a snapshot record and starts the refresh with `Task.Run`. Use `SemaphoreSlim` for the concurrency limit, or a plain `foreach` with `await` for 1. `settle` is `await Task.WhenAny(inflight, Task.Delay(Math.Max(0, timeoutMs), cts.Token))` with the `CancellationTokenSource` cancelled afterwards (the equivalent of `clearTimeout`), then `return !state.Refreshing`. Replace the 2 to the power of failures with `Math.Min(retryMs * Math.Pow(2, failures - 1), ttlMs)` and keep it in `double` to avoid integer overflow. The clock is `Func<DateTimeOffset>`, defaulting to `DateTimeOffset.UtcNow`, and `updatedAt` is `ToString("o", CultureInfo.InvariantCulture)` or a JavaScript-style ISO string. Log with `ILogger.LogWarning`. In an ASP.NET Core host, register it as a singleton service; if a UI polls it, expose the sections through `INotifyPropertyChanged` or an `ObservableCollection` on a `DispatcherQueue`-marshalled view model. Because .NET tasks run on multiple threads, the check-and-start in `read` and every schedule update MUST be guarded with a lock, which the single-threaded JavaScript source does not need.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/sectioned-dashboard.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/status-server/test/telemetry-sectioned-dashboard.test.ts` | confirmed (1.0.2) |
| web | `packages/web/packages/deploy-platform/src/util/map-limit.ts` | confirmed (1.0.2) |

## Design Decisions

**Decision**: `read` never waits; it returns what is known and starts a refresh when one is due.
**Rationale**: The source comment explains the cold dashboard can take a minute, which is past the rewrite proxy's limit, and holding a request open would delay sections that could already be on screen. Each section publishes as it finishes and the client polls while `refreshing`.
**Approved**: pending

**Decision**: Refreshes are driven by reads, not timers.
**Rationale**: The source comment states "an idle dashboard costs no provider quota". A timer would keep calling PostHog and Vercel whether or not anyone is looking.
**Approved**: pending

**Decision**: Each section has its own schedule, and a refresh re-runs only due sections.
**Rationale**: The source comment says one failing section is retried on its own "rather than dragging every healthy one back to the provider with it".
**Approved**: pending

**Decision**: Failure backoff doubles from `retryMs` up to `ttlMs`.
**Rationale**: The source comment says retries back off "rather than hitting a provider that keeps failing once a minute for as long as it fails". A one-off blip costs `retryMs` and not a whole TTL; the doubling stops at the TTL so a failing section is never retried less often than a healthy one.
**Approved**: pending

**Decision**: A failed section keeps its last good `data` and `updatedAt`, and only `error` changes.
**Rationale**: The `DashboardSection` comment says the last good answer "survives a later failure, so stale data stays on screen".
**Approved**: pending

**Decision**: An `incomplete` answer is published as a success with no error but is retried on the failure schedule.
**Rationale**: The option comment says it is "shown but known to be short (some of its calls failed)". The partial data is still useful on screen; holding it for the whole TTL would leave a chart flat after one project timed out.
**Approved**: pending

**Decision**: Sections run strictly one after another by default.
**Rationale**: The source comment says PostHog's API 503s under concurrency. Sections therefore queue unless the caller opts into a higher `concurrency`.
**Approved**: pending

**Decision**: `settle` exists apart from `read` and never starts a refresh.
**Rationale**: The `settle` comment says a server-side reader such as `/report` must not push the polling that `read` implies onto its own client; it reads, settles, and reads again.
**Approved**: pending

**Decision**: State per key is kept forever, so keys must come from a bounded enum.
**Rationale**: Stated in the source header comment. Bounded keys (the analytics ranges, or the single key `all`) keep the map small without an eviction policy.
**Approved**: pending

**Decision**: A `loaders` builder that throws counts as a failure of every due section that did not settle.
**Rationale**: The source comment says this lets such sections be "retried rather than left due on every read"; without it a throwing builder would be called on every read.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | passed | access-patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |

Separation of concerns passes: the file owns scheduling, caching and publishing, and every provider call is a loader supplied from outside. Unit-test coverage passes: `telemetry-sectioned-dashboard.test.ts` covers the cold read, per-section publishing, the TTL, failure with kept data, backoff, the incomplete answer, key separation, a throwing builder and all four `settle` cases. Vectors 015 to 020 cover `emptySections`, read copies, `retryMs` clamping, `concurrency` above 1 and non-`Error` rejections. Retry with backoff passes: failures double the wait from `retryMs` up to `ttlMs` and a success resets it. Graceful degradation passes: a failed section keeps its stale data and the other sections load. Timeout handling is partial: `settle` has a deadline, but a loader that never settles has no timeout in this module and holds its key refreshing; loaders own their own deadlines. Caching strategy passes: stale-while-revalidate with a per-section TTL and read-driven refresh.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-sectioned-dashboard.test.ts, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved the mapLimit detail to the React/Web note, narrowed wedge-guard and section-publish-on-finish to what the source does, remapped vector 020, marked unit-test-coverage partial with vectors 015 to 020 flagged untested, dropped bare MUST tags from edge cases, clarified the SwiftUI clock note and emptied references. |
