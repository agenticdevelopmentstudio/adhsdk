---
id: f03325ef-f4c6-43ab-9a88-1a0bf3daa002
title: "Dashboard Set"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One set of stale-while-revalidate dashboard caches per app, built from config and storage, shared by the dashboard routes, GET /report and the MCP tools."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - cache
depends-on:
  - af0bacb9-bc1f-4773-85f5-35e33ae590ab
  - 967202ce-c607-4115-9f63-466a4004e7f3
related:
  - a7c2b9e1-5d4f-4a2c-9e6f-8b3a1c5d7e2f
  - 8648272e-2da3-46fc-b9e8-5148dacdbcff
  - 77587f0b-5a27-44d9-a507-46bb90c9046a
  - ce157d5a-c145-4348-b58f-6a76c9fda1d6
  - 1c240b7a-21b3-4a89-b24f-a5bf5cf5f37b
references: []
approved-by: ""
approved-date: ""
---

# Dashboard Set

## Overview

`createDashboardSet(config, storage)` builds the Analytics and Errors dashboards as one set of stale-while-revalidate caches per app. It is built once at app creation and handed to every reader (the dashboard routes, `GET /report` and the MCP tools), so a report and an open dashboard tab share one refresh instead of each paying a minute of provider time for the same answer.

The set returns a `DashboardSet` with four operations. `analytics(range)` and `errors(nowMs?)` answer at once with what is known and let a refresh run behind the answer; `settleAnalytics` and `settleErrors` wait for that refresh, for a server-side reader that must hand its own client a finished answer. The caches themselves come from the `sectionedDashboard` function ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab)), and the loaders from the PostHog, GlitchTip and Vercel section modules; this ingredient specifies how the set composes them.

## Behavioral Requirements

- **single-instance**: The set MUST be constructed once per app and shared by every reader; construction MUST create its caches and no network call.
- **analytics-never-waits**: `analytics(range)` MUST return synchronously with the last known sections and MUST NOT wait on a provider.
- **analytics-shape**: `analytics(range)` MUST return `generatedAt` (ISO), `refreshing`, `range`, `configured` (`{ posthog, vercel }`), `sections` and `views`.
- **analytics-sections**: `sections` MUST hold the PostHog sections `traffic`, `dimensions`, `paths`, `vitals`, `health` and the Vercel section `vercel`; a provider that is not configured MUST supply those sections in their empty state (`data` null, `error` null, `updatedAt` null) and MUST NOT be read.
- **analytics-refreshing**: `refreshing` MUST be true when either the PostHog or the Vercel cache for that range is refreshing.
- **providers-independent**: The PostHog and Vercel caches (and the GlitchTip and sites caches) MUST refresh independently, so a slow provider does not hold back another.
- **analytics-ttl**: The PostHog, Vercel and sites caches MUST treat a fully successful refresh as good for 10 minutes; the GlitchTip cache MUST use 60 seconds.
- **window-per-refresh**: Each refresh MUST compute its time window from the current time using `rangeWindow(range, now)` ([adhsdk.ingredient.status.service.telemetry.dashboard.ranges](cookbook:d4e7dd53-4771-425f-af0a-0186ba89c3ef)): the PostHog and sites windows when the refresh builds its loaders, the Vercel window when its loader runs; the sites caches MUST always use the `30d` window.
- **vercel-incomplete**: A Vercel section whose data reports `failed` greater than 0 or `incomplete` greater than 0 MUST be treated as short and retried on the retry schedule of the sectioned cache ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab); 60 seconds, doubling with each failure in a row, up to the TTL), not held for the whole TTL.
- **errors-shape**: `errors(nowMs)` MUST return `generatedAt` (the ISO form of `nowMs`, defaulting to the current time), `refreshing`, `refreshingSources` (`{ glitchtip, posthog }`), `configured` (`{ glitchtip, posthog, vercel }`), `sections` and `views`.
- **errors-sections**: `sections` MUST hold `issues` (GlitchTip), `sites` and `detail` (PostHog, 30 days) and `runtime`; an unconfigured provider MUST supply its sections in the empty state.
- **runtime-in-request**: When Vercel is configured, `errors` MUST read the runtime-errors report from the store through `loadRuntimeErrorsReport(storage.telemetry.runtimeErrors, nowMs)` ([adhsdk.ingredient.status.service.telemetry.runtime-errors](cookbook:c116715f-2986-4554-a779-97e99d875c54)) within the same call and MUST NOT leave it for a later poll. When Vercel is not configured it MUST supply the empty state.
- **runtime-failure**: When that store read throws, `runtime` MUST be `{ data: null, error: <message>, updatedAt: null }` and `errors` MUST still resolve.
- **runtime-updated-at**: A successful runtime section MUST carry `updatedAt` equal to the report's `readAt` (when the groups were read from Vercel), not the time of this request.
- **errors-refreshing**: `refreshing` MUST be true when the GlitchTip or the sites cache is refreshing, and MUST NOT include the runtime read; `refreshingSources` MUST say which of the two.
- **configured-predicates**: Whether a provider is read MUST be decided by `glitchtipConfigured`, `posthogConfigured` and `vercelConfigured` on the config at each call. The `credentials` the loaders and the `resolvedCounter` use are taken from the config once, when the set is built, so a set sees one fixed credential set for its life.
- **views-memoized**: `views` MUST be derived by `analyticsViews` or `errorsViews` ([adhsdk.ingredient.status.service.telemetry.dashboard.views](cookbook:967202ce-c607-4115-9f63-466a4004e7f3)) and MUST be recomputed only when an input changed by identity: for analytics every section object plus the two configured flags, kept per range; for errors the `sites` section, the `detail` section and the PostHog flag. A client polling an unchanged refresh MUST get the same views object while every provider the views read is configured; an unconfigured provider supplies fresh empty section objects on each call, so that memo is recomputed on every call.
- **runtime-not-a-view-input**: The runtime section MUST NOT be an input of the errors views memo, because it is read fresh each request and no view uses it.
- **settle-analytics**: `settleAnalytics(range, timeoutMs)` MUST wait on the PostHog and Vercel caches for that range in parallel, each bounded by `timeoutMs`, and MUST resolve true only when both settled.
- **settle-errors**: `settleErrors(timeoutMs)` MUST wait on the GlitchTip and sites caches in parallel and MUST resolve true only when both settled.
- **settle-never-starts**: A settle MUST NOT start a refresh; a caller that wants a warm answer reads, settles, and reads again.
- **resolved-counter-shared**: One `resolvedCounter` built from the credentials MUST be shared by every GlitchTip refresh, so its cached resolved-issue count survives between refreshes.

## Appearance

Not applicable — this is a cache-composition service, not a visual component.

## States

Not applicable — this is a cache-composition service, not a visual component.

## Accessibility

Not applicable — this is a cache-composition service, not a visual component.

## Conformance Test Vectors

Vectors 001 and 002 are also traced to `telemetry-dashboards.int.test.ts` (routes with no provider configured); vectors 001 to 021 are traced to `telemetry-dashboard-set.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dashboard-set-001 | analytics-shape, analytics-sections | `analytics('7d')` with no provider configured | `configured` `{ posthog: false, vercel: false }`, every section in the empty state, `refreshing` false |
| dashboard-set-002 | errors-sections, errors-shape | `errors()` with no provider configured | Empty `issues`, `sites`, `detail` and `runtime`; no failure |
| dashboard-set-003 | runtime-in-request | `errors()` with Vercel configured and a store read | `runtime.data` is the report and `updatedAt` equals its `readAt` |
| dashboard-set-004 | runtime-failure | `errors()` with Vercel configured and a store that throws `boom` | `runtime` is `{ data: null, error: 'boom', updatedAt: null }`; the other sections are unaffected |
| dashboard-set-005 | analytics-shape | `analytics('7d')` with no provider configured | `range` is `7d` and `generatedAt` is an ISO timestamp |
| dashboard-set-006 | views-memoized | Two `analytics('24h')` calls with PostHog and Vercel both configured and no section published between them | The same `views` object both times |
| dashboard-set-007 | views-memoized | `analytics('24h')` then `analytics('7d')` | Independent memos; one range's views never reused for the other |
| dashboard-set-008 | settle-never-starts | `settleAnalytics('24h', 1000)` before any read | Resolves true at once and starts no refresh |
| dashboard-set-009 | settle-analytics | A PostHog refresh that outlasts `timeoutMs` | Resolves false once `timeoutMs` has elapsed (with fake timers, after advancing by exactly `timeoutMs`); the refresh keeps running |
| dashboard-set-010 | vercel-incomplete | A Vercel result with `failed` 1 | Shown as data without an error, retried after 60 seconds (the default retry, with a fake clock advanced by 60 seconds), not after 10 minutes |
| dashboard-set-011 | errors-refreshing | GlitchTip refreshing, sites idle | `refreshing` true, `refreshingSources` `{ glitchtip: true, posthog: false }` |
| dashboard-set-012 | single-instance | `createDashboardSet(config, storage)` with a spy on every loader | No loader and no network call runs at construction |
| dashboard-set-013 | analytics-never-waits | `analytics('24h')` with a PostHog loader that never resolves | The call returns at once with empty sections and `refreshing` true |
| dashboard-set-014 | analytics-refreshing | PostHog idle, Vercel refreshing for `7d` | `analytics('7d').refreshing` is true |
| dashboard-set-015 | providers-independent | A PostHog loader that never resolves and a Vercel loader that resolves | The `vercel` section publishes while the PostHog sections stay empty |
| dashboard-set-016 | analytics-ttl | A fully successful GlitchTip refresh, then reads at 59 and 61 seconds | No refresh at 59 seconds, a new one at 61 seconds; the PostHog caches stay fresh until 10 minutes |
| dashboard-set-017 | window-per-refresh | A sites refresh for `errors()` with PostHog configured, whatever the analytics range | The sites loaders get the `30d` window, computed from the current time |
| dashboard-set-018 | configured-predicates | `analytics('24h')` with PostHog configured, then with it unconfigured | The second call reports `configured.posthog` false and reads no PostHog cache |
| dashboard-set-019 | runtime-not-a-view-input | Two `errors()` calls whose `runtime` objects differ, with `sites` and `detail` unchanged | The same `views` object both times |
| dashboard-set-020 | settle-errors | A GlitchTip refresh in flight and a sites refresh in flight, both finishing within `timeoutMs` | `settleErrors(timeoutMs)` resolves true after both settle |
| dashboard-set-021 | resolved-counter-shared | Two GlitchTip refreshes with the same credentials | Both use the same `resolvedCounter`, so the second reuses the cached resolved-issue count |
## Edge Cases

- With every provider unconfigured, both dashboards answer with empty sections and never fail; this is the normal state of a fresh deployment.
- A section whose loader throws keeps its previous `data` and gains an `error`; stale data stays on screen (behavior of the underlying cache).
- A cold dashboard answers with empty sections and `refreshing` true on the first read; the data arrives on later reads.
- `analytics` stamps `generatedAt` from the clock, not from an injected time; only `errors` takes a `nowMs`.
- The runtime read can throw on a store fault; the error is carried in the section and the call still resolves.
- A `settle` on a key never read resolves true, because nothing is in flight.
- The `analytics` memo is kept per range, so a range's views are not shared with another range, and the map is created for every key of `ANALYTICS_RANGES` up front.
- Section state lives for the life of the process, so keys must come from a closed list; the set only uses the three ranges and `all` (the one key of the GlitchTip and sites caches, which hold no per-range state), and nothing caller-supplied.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | `StatusConfig` | required | Supplies `credentials`, `glitchtipProjects` and the configured predicates |
| `storage` | `Storage` | required | Read for `telemetry.runtimeErrors` |
| `range` | `24h`, `7d` or `30d` | none | The analytics window, per call |
| `nowMs` | number | current time | The clock for the errors answer and the runtime read |
| `timeoutMs` | number | none | The wait limit of a settle call |
| `ANALYTICS_TTL_MS` | number | 600000 | Freshness of the PostHog, Vercel and sites caches; a module constant |
| `ERRORS_TTL_MS` | number | 60000 | Freshness of the GlitchTip cache; a module constant |

## Deep Linking

Not applicable: the set is an in-process service; the routes that expose it own the URLs.

## Localization

Not applicable: the set holds no user-facing strings; the runtime section's `error` carries a store error message as is.

## Accessibility Options

Not applicable: the set has no rendering.

## Feature Flags

Not applicable: the set reads no flag; whether a provider is read depends on its credentials in the config.

## Analytics

Not applicable: the set serves analytics data to readers but emits no events of its own.

## Privacy

The set holds provider credentials (PostHog, GlitchTip and Vercel tokens) from `config.credentials` and passes them to the section loaders; it never returns them, and it sends them only to those providers' APIs. Per-site traffic and issue titles it returns are operator-only data, gated by the routes.

## Logging

The set itself makes no log call; the underlying cache logs a section failure as `[telemetry] dashboard section <name> (<key>) failed: <error>` through `console.warn`.

## Platform Notes

- **SwiftUI**: Hold the caches in an `actor` per dashboard; `read` returns a snapshot value type, and `Task` plus `async let` run the independent provider refreshes. Observe the snapshot from a view model with `AsyncStream` while `refreshing`.
- **Compose**: Use a repository class with a `CoroutineScope` per cache, `StateFlow` for the snapshot, and `withTimeoutOrNull` for the settle deadline.
- **React/Web**: Keep the module as is: closures over a `Map`, `Promise.race` for settle. A browser client polls the route while `refreshing` is true.
- **AppKit / UIKit**: Same as SwiftUI; run each refresh on a background `Task` and deliver the snapshot to the main actor.
- **WinUI 3**: The set is a server-side service, so in a WinUI/.NET client keep it as an in-process singleton owned by the app (or run it in an ASP.NET Core host that the client polls); each cache is a class with a `ConcurrentDictionary` of key state and a background `Task` per refresh, and settle uses `Task.WhenAny(refresh, Task.Delay(timeout))`. The `IMemoryCache` is not used because the stale-while-revalidate rule keeps stale data on failure.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/dashboard-set.ts` | confirmed (1.0.3) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One set shared by every reader.
**Rationale**: The dashboard routes, the report and the MCP tools read the same caches, so a report and an open tab share one refresh.
**Approved**: pending

**Decision**: Providers refresh separately.
**Rationale**: PostHog, Vercel, GlitchTip and the sites read have their own caches, so one slow provider never holds back another's sections.
**Approved**: pending

**Decision**: Runtime errors read in the request.
**Rationale**: They come from the app's own store, which the monitor cycle fills, so they are cheap and always fresh; the provider sections are the slow ones.
**Approved**: pending

**Decision**: Views memoized by identity.
**Rationale**: A section object is replaced only when a refresh publishes it, so the cheap identity check lets polling clients share one derivation.
**Approved**: pending

**Decision**: Settle separate from read.
**Rationale**: Reading starts the refresh and never waits; a server-side reader that must give a finished answer settles explicitly, so polling is not pushed onto its own client.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

The set only composes: caching lives in the sectioned cache, loaders in the section modules, and views in the views module, so concerns are separated. Its integration test covers the unconfigured case through the routes, and `telemetry-dashboard-set.test.ts` has a test for every vector, 001 to 021, with the loaders and views replaced by spies, so unit-test coverage passes. Stale-while-revalidate with a per-provider schedule, and a runtime section that reports its own error, give graceful degradation.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-dashboard-set.test.ts, 21 of 21 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Linked the ranges, sectioned-cache, runtime-errors and views specs, replaced the route-level vector 005 with a set-level one, tightened the settle and retry timings, added vectors 012-021 for construction, never-waiting reads, refreshing, provider independence, TTL, windows, predicates, view inputs, settle and the shared resolved counter, and rewrote the WinUI 3 note as translation guidance. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
