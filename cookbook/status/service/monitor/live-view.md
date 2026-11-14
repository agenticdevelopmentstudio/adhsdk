---
id: 1f17d751-d49c-4f0a-89d9-20c17b9dcee4
title: "Status Server Live View Verdicts"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pure verdict functions for GET /live: snapshot freshness, unconfirmed in-flight deploys with their deadline, and stale-monitor candidates"
platforms:
  - typescript
  - web
tags:
  - status-server
  - freshness
  - deploys
  - monitoring
depends-on: []
related:
  - add8a34c-a40d-417e-9ee8-aec108e73474
  - 2c8b4572-3851-4111-97d6-a42792fb7150
  - ac044c52-64bb-4e4f-b0d8-56dd88ab7d47
  - 9d2d3132-0853-4e3a-8e81-503356e4585d
references: []
approved-by: ""
approved-date: ""
---

# Status Server Live View Verdicts

## Overview

`live-view.ts` holds the judgements that `GET /live` publishes beside its raw facts, so the dashboard reads a verdict instead of re-deriving one with its own copy of the rule. Three verdicts live here: how stale the snapshot is (`snapshotFreshness`, `liveFreshness`), whether an in-flight deploy's phase is still believed (`deployUnconfirmed`, `deployUnconfirmedAt`, `effectiveDeployStatus`), and which down endpoints are stale-monitor candidates to retire (`selectStaleMonitors`, `staleMonitorsView`). Per the source comment, these rules used to live in status-web and ran against the browser's clock; they now run against the snapshot's own `generatedAt` (re-stamped every cycle by the SSE stream) or a caller-supplied `nowMs`, so a verdict is never more than one cycle old, and when the stream stops the freshness verdict is exactly what goes stale and says so. Every function is pure and synchronous: no I/O, no clock reads, no logging.

`/live` carries these verdicts under names that every port MUST emit alike, as defined by Live Types ([adhsdk.ingredient.status.service.monitor.live-types](cookbook:2c8b4572-3851-4111-97d6-a42792fb7150)): `freshness` (a `LiveFreshness`) and `staleMonitors` (a `StaleMonitorsView`) on the snapshot, and `unconfirmedAt` (the `deployUnconfirmedAt` result) on each deploy it lists. The route code that builds them is `monitor/overview.ts` (see Status Server Monitor Overview, [adhsdk.ingredient.status.service.monitor.overview](cookbook:add8a34c-a40d-417e-9ee8-aec108e73474)).
## Behavioral Requirements

### Constants

- **snapshot-stale-floor**: `SNAPSHOT_STALE_FLOOR_MS` MUST equal `300000` (5 minutes).
- **unconfirmed-floor**: `UNCONFIRMED_AFTER_MS` MUST equal `600000` (10 minutes).
- **stale-monitor-threshold**: `STALE_MONITOR_MS` MUST equal `604800000` (7 days).

### Snapshot freshness

- **snapshot-stale-window**: `snapshotStaleMs(probeIntervalMs)` MUST return `max((probeIntervalMs ?? 0) * 5, SNAPSHOT_STALE_FLOOR_MS)`, so a null, undefined or small interval yields 300000 and an interval above 60000 yields five times the interval.
- **freshness-missing-clock**: `snapshotFreshness(lastCycleAt, generatedAt, probeIntervalMs)` MUST return `"fresh"` when `lastCycleAt` or `generatedAt` is null, undefined or the empty string, because no probe ever recorded means a brand-new monitor, not a wedged one.
- **freshness-lag**: Otherwise `snapshotFreshness` MUST compute the lag as `Date.parse(generatedAt) - Date.parse(lastCycleAt)` and return `"fresh"` when the lag is not greater than the stale window, `"stale"` when it is greater than the window and not greater than three times the window, and `"very-stale"` when it is greater than three times the window.
- **freshness-nan-safe**: When either clock is unparseable the lag is `NaN` and `snapshotFreshness` MUST return `"fresh"`; a NaN must never raise a banner.
- **freshness-negative-lag**: A negative lag (probe newer than the read) MUST return `"fresh"`.
- **freshness-data-vs-read-clock**: The freshness verdict MUST compare the data clock (`lastCycleAt`, the newest persisted probe) against the read clock (`generatedAt`), so a wedged poller that keeps serving a fresh `generatedAt` over frozen probes is noticed.
- **live-freshness-shape**: `liveFreshness(lastCycleAt, generatedAt, probeIntervalMs)` MUST return `{ state, asOf }` where `state` is `snapshotFreshness(lastCycleAt, generatedAt, probeIntervalMs)` and `asOf` is `lastCycleAt` echoed unchanged (including `null`).

### Unconfirmed deploys

- **unconfirmed-window**: `unconfirmedWindowMs(probeIntervalMs)` MUST return `max(UNCONFIRMED_AFTER_MS, (probeIntervalMs ?? 0) * 5)`, so a slower poller does not demote a phase it confirms on its normal schedule.
- **in-flight-statuses**: Only deploys whose `status` is `"building"` or `"queued"` are in flight; every other `DeployStatus` (`success`, `failed`, `canceled`, `unknown`) is settled.
- **settled-never-unconfirmed**: `deployUnconfirmed` MUST return `false` for a settled deploy, however old.
- **unconfirmed-clock**: For an in-flight deploy `deployUnconfirmed` MUST parse `phaseConfirmedAt`, falling back to `createdAt` when `phaseConfirmedAt` is falsy (empty string, null or undefined).
- **unconfirmed-fails-closed**: When that clock is unparseable, `deployUnconfirmed` MUST return `true`, so a deploy is not believed rather than asserting live progress on a date nothing can read.
- **unconfirmed-threshold**: For a parseable clock, `deployUnconfirmed` MUST return `true` when `nowMs - confirmed` is strictly greater than `unconfirmedWindowMs(probeIntervalMs)` and `false` otherwise (exactly the window is still believed).
- **effective-status**: `effectiveDeployStatus` MUST return `"unknown"` when `deployUnconfirmed` is `true` and otherwise the deploy's own `status`, the same demotion the activity feed applies.
- **unconfirmed-deadline**: `deployUnconfirmedAt` MUST return, for an in-flight deploy that is not yet unconfirmed, the ISO string (`toISOString`) of the confirmation time plus `unconfirmedWindowMs(probeIntervalMs)`, so a display holding an old snapshot can age the phase on its own clock without knowing the window.
- **unconfirmed-deadline-null**: `deployUnconfirmedAt` MUST return `null` for a settled deploy and for an in-flight deploy that `deployUnconfirmed` already reports as unconfirmed, including one with an unparseable clock, because its status already says so.
- **deadline-agrees-with-verdict**: The deadline and `effectiveDeployStatus` MUST agree: at `nowMs` equal to the deadline the effective status is the deploy's own, and 1 ms after it the effective status is `"unknown"`.

### Stale monitors

- **stale-monitor-selection**: `selectStaleMonitors(services, nowMs, thresholdMs)` MUST include a service only when its `status` is `"down"`, its `downSince` is non-null and non-empty, `nowMs - Date.parse(downSince)` is finite, and that age is at least `thresholdMs` (inclusive), where `thresholdMs` defaults to `STALE_MONITOR_MS`.
- **stale-monitor-malformed-onset**: A malformed `downSince` MUST be skipped, never surfaced as a NaN age.
- **stale-monitor-status-only-down**: A service whose `status` is anything other than `"down"` (`healthy`, `degraded` and the like) MUST be excluded however old its `downSince` is.
- **stale-monitor-dns-decides-nothing**: `dnsOk` MUST NOT affect selection; it is copied to the output unchanged, because a host that still resolves can be gone.
- **stale-monitor-shape**: Each selected entry MUST be a `StaleMonitor` with `slug`, `name`, `url`, `environment` (`s.environment || null`, so an empty string becomes `null`), `detail`, `dnsOk`, `downSince` (the input ISO string unchanged) and `ageMs` (the computed age).
- **stale-monitor-detail**: `detail` MUST be the service's `error` when `error` is not null or undefined (an empty string is kept), else `"HTTP <statusCode>"` when `statusCode` is not null or undefined, else `"down"`.
- **stale-monitor-order**: The result MUST be sorted by `ageMs` descending (longest-down first).
- **stale-monitor-ties**: Entries with equal `ageMs` MUST keep their input order, so the sort MUST be stable.
- **stale-monitors-view**: `staleMonitorsView(services, nowMs)` MUST return `{ thresholdDays, monitors }` where `thresholdDays` is `Math.round(STALE_MONITOR_MS / 86400000)` (currently `7`) and `monitors` is `selectStaleMonitors(services, nowMs)` with the default threshold, so a banner can state the number without owning it.

### Purity

- **purity**: Every function in this module MUST be free of side effects: no mutation of its arguments, no I/O, no logging and no read of the system clock; time enters only through `nowMs`, `generatedAt` and the probe clocks passed in.

## Appearance

Not applicable — these are pure verdict functions over snapshot data, not a visual component.

## States

Not applicable — these are pure verdict functions over snapshot data, not a visual component. The two verdict vocabularies (`fresh`, `stale`, `very-stale`; in-flight, unconfirmed, settled) are defined under Behavioral Requirements.

## Accessibility

Not applicable — these are pure verdict functions over snapshot data, not a visual component.

## Conformance Test Vectors

Vectors come from `live-view.test.ts` where a test is named; the others are traced directly to the function bodies. `GEN` is `2024-06-01T12:00:00.000Z` and `lag(ms)` is `GEN` minus `ms`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-live-view-001 | snapshot-stale-window, snapshot-stale-floor | `snapshotStaleMs(undefined)`, `(null)`, `(60_000)`, `(120_000)` | `300000`, `300000`, `300000`, `600000` — `live-view.test.ts` › "snapshotStaleMs" |
| status-server-monitor-live-view-002 | freshness-missing-clock | `snapshotFreshness(null, GEN, 60_000)`, `(undefined, GEN)`, `(lag(10 min), null)` | `"fresh"` for each — `live-view.test.ts` › "is fresh when there is no probe yet, or no read clock" |
| status-server-monitor-live-view-003 | freshness-lag | `snapshotFreshness(lag(4 min), GEN, 60_000)`, `lag(6 min)`, `lag(16 min)` | `"fresh"`, `"stale"`, `"very-stale"` — `live-view.test.ts` › "is fresh within the window, stale past it, very-stale past 3x" |
| status-server-monitor-live-view-004 | snapshot-stale-window, freshness-lag | `snapshotFreshness(lag(6 min), GEN, 120_000)` and `lag(11 min)` | `"fresh"` then `"stale"` (window is 10 min) — `live-view.test.ts` › "scales the window with the probe interval" |
| status-server-monitor-live-view-005 | freshness-nan-safe, freshness-negative-lag | `snapshotFreshness("not-a-date", GEN, 60_000)`; `(lag(20 min), "not-a-date")`; `(GEN + 30 s, GEN)` | `"fresh"` for each — `live-view.test.ts` › "is NaN-safe and ignores a negative lag" |
| status-server-monitor-live-view-006 | live-freshness-shape | `liveFreshness(lag(6 min), GEN, 60_000)`; `liveFreshness(null, GEN, 60_000)` | `{ state: "stale", asOf: lag(6 min) }`; `{ state: "fresh", asOf: null }` — `live-view.test.ts` › "liveFreshness echoes the data clock it judged" |
| status-server-monitor-live-view-007 | unconfirmed-window, unconfirmed-floor | `unconfirmedWindowMs(undefined)`, `(60_000)`, `(300_000)` | `600000`, `600000`, `1500000` — `live-view.test.ts` › "unconfirmedWindowMs" |
| status-server-monitor-live-view-008 | unconfirmed-threshold, effective-status | Building deploy confirmed at `C`; `deployUnconfirmed(d, C + 600_000 - 1)` and `C + 600_000 + 1` | `false` then `true`; `effectiveDeployStatus` is `"building"` then `"unknown"` — `live-view.test.ts` › "demotes an in-flight deploy whose phase outlived its confirmation" |
| status-server-monitor-live-view-009 | in-flight-statuses | Queued deploy at `C + 600_000 + 1` | `effectiveDeployStatus` is `"unknown"` — `live-view.test.ts` › "demotes a queued deploy the same way" |
| status-server-monitor-live-view-010 | settled-never-unconfirmed | `status: "success"` deploy, `nowMs = C + 30 days` | `deployUnconfirmed` is `false`; `effectiveDeployStatus` is `"success"` — `live-view.test.ts` › "never demotes a settled deploy, however old" |
| status-server-monitor-live-view-011 | unconfirmed-clock, unconfirmed-fails-closed | `phaseConfirmedAt: ""` with `createdAt = C`, at `C + 600_000 + 1` and at `C`; and `createdAt: "nope"` at `C` | `true`; `false`; `true` — `live-view.test.ts` › "fails CLOSED on an unparseable clock, and falls back to createdAt" |
| status-server-monitor-live-view-012 | unconfirmed-window | Probe interval `360_000`; `deployUnconfirmed` at `C + 600_001` and at `C + 1_800_001` | `false`, then `true` — `live-view.test.ts` › "honors the cadence-scaled window over the floor" |
| status-server-monitor-live-view-013 | unconfirmed-deadline, deadline-agrees-with-verdict | `deployUnconfirmedAt(d, C)`; interval `360_000` variant | `new Date(C + 600_000).toISOString()`; `new Date(C + 1_800_000).toISOString()`; effective status `"building"` at the deadline and `"unknown"` at deadline + 1 — `live-view.test.ts` › "publishes the deadline a display ages an in-flight deploy against, on the same window" |
| status-server-monitor-live-view-014 | unconfirmed-deadline-null | `deployUnconfirmedAt` for a `success` deploy; for a deploy past the window; for `createdAt: "nope"` with an empty `phaseConfirmedAt` | `null` for each — `live-view.test.ts` › "has no deadline for a settled deploy, or for one already demoted" |
| status-server-monitor-live-view-015 | stale-monitor-selection, stale-monitor-shape, stale-monitor-detail | One service `down`, `error: "HTTP 500"`, `downSince` 30 days before `NOW` | One entry matching `{ slug: "ep1", dnsOk: true, detail: "HTTP 500" }`, `ageMs === 30 * 86_400_000` — `live-view.test.ts` › "includes a down endpoint past the threshold" |
| status-server-monitor-live-view-016 | stale-monitor-dns-decides-nothing | The same three services with `dnsOk` true, then false | Slugs `["gone", "also-gone"]` both times; the output keeps `dnsOk: false` — `live-view.test.ts` › "selects the same rows whether or not the hosts resolve; DNS decides nothing" |
| status-server-monitor-live-view-017 | stale-monitor-status-only-down, stale-monitor-malformed-onset | `downSince` 2 days ago; `healthy` with `downSince: null`; `degraded` 40 days; `down` with `downSince: null`; `downSince: "not-a-date"` | `[]` — `live-view.test.ts` › "excludes short outages, non-down rows, unknown and malformed onsets" |
| status-server-monitor-live-view-018 | stale-monitor-detail | `error: null`, `statusCode: 503` | `detail === "HTTP 503"` — `live-view.test.ts` › "derives the detail from statusCode when there is no error string" |
| status-server-monitor-live-view-019 | stale-monitor-order, stale-monitor-threshold | Down 8 days and 90 days; and exactly 7 days and 6 days | Order `["older", "newer"]`; 7 days is included, 6 days is not — `live-view.test.ts` › "sorts longest-down first and uses an inclusive 7-day threshold" |
| status-server-monitor-live-view-020 | stale-monitors-view | `staleMonitorsView([svc()], NOW)` | `{ thresholdDays: 7, monitors: [{ slug: "ep1" }] }` — `live-view.test.ts` › "staleMonitorsView names the threshold in days" |
| status-server-monitor-live-view-021 | stale-monitor-detail, stale-monitor-shape | Down service with `error: null`, `statusCode: null`, `environment: ""` | `detail === "down"`, `environment === null` — traced to the `??` chain and `|| null`; not exercised by a test |
| status-server-monitor-live-view-022 | stale-monitor-detail | Down service with `error: ""` and `statusCode: 503` | `detail === ""`, because an empty string is kept (`??` only skips null and undefined) — traced to the `??` chain; not exercised by a test |
| status-server-monitor-live-view-023 | stale-monitor-ties | Two down services with the same `downSince`, input order `["first", "second"]` | Slugs `["first", "second"]` — traced to the stable `Array.sort`; not exercised by a test |
## Edge Cases

- **Null and empty input**: A null, undefined or empty clock in `snapshotFreshness` returns `"fresh"` — MUST. An empty `services` array returns `[]` monitors and `thresholdDays` `7` — MUST. An empty `phaseConfirmedAt` falls back to `createdAt` — MUST.
- **Boundary values**: A freshness lag exactly equal to the window is `"fresh"`, and exactly three windows is `"stale"` (both comparisons are strict) — MUST. A deploy exactly one window past confirmation is still believed (`>` is strict) — MUST. A service down for exactly `thresholdMs` is selected (`<` skips, so equal is included) — MUST. A `probeIntervalMs` of `0`, null or undefined uses the floor — MUST.
- **Concurrent access**: Not applicable — every function is pure over its arguments with no shared state, and the runtime is single-threaded JavaScript.
- **Error states**: Not applicable — no function performs I/O, throws or catches. Unparseable dates are handled by value: `snapshotFreshness` reads fresh (a banner is never raised on NaN), `deployUnconfirmed` fails closed (not believed), and `selectStaleMonitors` skips the row.
- **Offline or disconnected state**: Not applicable — the module touches no network. Its freshness verdict is the signal that the data has stopped moving when a poller or the SSE stream stops; the data clock lags the re-stamped read clock.
- **Unparseable clock asymmetry**: An unparseable data or read clock reads fresh, yet an unparseable deploy clock reads unconfirmed; this opposite direction is deliberate in the source comments (a banner must not rise on NaN, a progress claim must not rest on one) — MUST.
- **Display older than the snapshot**: A client may keep showing a snapshot after the stream stalls; `deployUnconfirmedAt` is the deadline it can age on; this module only publishes the deadline and places no requirement on the display.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `probeIntervalMs` | `number \| null \| undefined` | none (treated as 0) | Probe cadence scaling the freshness and unconfirmed windows to five times the interval, never below their floors. `liveFreshness` takes a `number` and the other functions accept `null` or `undefined`; any missing value counts as 0. |
| `SNAPSHOT_STALE_FLOOR_MS` | `number` | `300000` | Minimum freshness window. Compile-time constant. |
| `UNCONFIRMED_AFTER_MS` | `number` | `600000` | Minimum unconfirmed window. Compile-time constant. |
| `STALE_MONITOR_MS` | `number` | `604800000` | Default stale-monitor threshold. Compile-time constant. |
| `thresholdMs` | `number` | `STALE_MONITOR_MS` | Optional third argument to `selectStaleMonitors`; `staleMonitorsView` never passes it. |
| `nowMs` | `number` | none, required | Caller's clock for the deploy and stale-monitor verdicts. |

## Deep Linking

Not applicable: the module defines no URL scheme or route; it returns verdicts to the `/live` route builder.

## Localization

The module contains one hardcoded English string, `"down"`, used as the last-resort `detail` of a `StaleMonitor`, plus the `"HTTP <code>"` form; both are shown to dashboard users and have no localization mechanism. The other strings are enum values, not text.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — stale-monitor detail | `HTTP <statusCode>` | `detail` when the probe saw a status code and no error |
| n/a — stale-monitor fallback | `down` | `detail` when the probe saw neither error nor status code |

## Accessibility Options

Not applicable: the module has no UI and responds to none of Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the module consults no feature-flag system.

## Analytics

Not applicable: the module emits no analytics or telemetry event.

## Privacy

Not applicable: the module stores and transmits nothing itself. It copies a service's `name`, `url`, `slug`, `environment` and probe error text into `StaleMonitor` rows for the `/live` response; those values originate upstream and are not inspected here.

## Logging

Not applicable: the module contains no `console.*` or logger call.

## Platform Notes

- **SwiftUI**: not a view concern. A Swift port is a set of free functions over `Date`/`TimeInterval` and enums (`enum SnapshotFreshness: String { case fresh, stale, veryStale = "very-stale" }`); parse ISO strings with `ISO8601DateFormatter` (with `.withFractionalSeconds`), and treat a nil parse result as the NaN cases above. A view model reads the verdicts and never re-judges.
- **Compose**: not a view concern. A Kotlin port uses `java.time.Instant.parse` inside `runCatching` to reproduce the NaN rules, `enum class` for the freshness states, and `sortedByDescending { it.ageMs }` for the stale-monitor order; the display ages the deploy against `deployUnconfirmedAt` using its own clock.
- **React/Web** (source platform): lives at `packages/web/packages/status-server/src/monitor/live-view.ts` with tests in `packages/web/packages/status-server/test/live-view.test.ts`. It relies on `Date.parse` returning `NaN` for bad input and on `Number.isFinite`; the route code in `routes/reads.ts` and `monitor/overview.ts` call it, and the dashboard (status-web) consumes the published verdicts.
- **AppKit / UIKit**: same non-view framing as SwiftUI; a controller binds to the already-judged `LiveFreshness` and `StaleMonitorsView` values and schedules a one-shot `Timer` at `unconfirmedAt` to flip a still-building deploy to unknown.
- **WinUI 3**: a .NET port is a static class with `static double SnapshotStaleMs(double? probeIntervalMs)` and the like; use `DateTimeOffset.TryParse(..., CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var t)` to reproduce `Date.parse` and `NaN` (a failed parse maps to the "fresh", "fails closed" or "skip" rule per function), `enum SnapshotFreshnessState { Fresh, Stale, VeryStale }` with a `JsonStringEnumConverter` and a kebab-case naming policy for `very-stale` (via `System.Text.Json`), and format the deadline with `ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")`, because `toISOString` always emits three fractional digits and `Z`. Return `IReadOnlyList<StaleMonitor>` from `OrderByDescending(m => m.AgeMs)`, which is stable like the source's `Array.sort`. Bind an `InfoBar` for the banner and a `DispatcherTimer` set to `UnconfirmedAt` to age the deploy in an `ObservableCollection` row, via `INotifyPropertyChanged`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/monitor/live-view.ts` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Compute the verdicts on the server and publish them on `/live` beside the raw facts.
  **Rationale**: Stated in the source comment: the dashboard "reads a verdict instead of re-deriving one from the facts with its own copy of the rule", and the rules move off the browser's clock onto the snapshot's own `generatedAt`.
  **Approved**: pending
- **Decision**: Judge freshness as data clock versus read clock, and read fresh when a clock is missing, unparseable or negative.
  **Rationale**: Stated in the doc comment: a wedged poller keeps a fresh `generatedAt` over frozen probes; no probe yet means a brand-new monitor; "a NaN must never raise a banner".
  **Approved**: pending
- **Decision**: Scale both freshness and unconfirmed windows to 5 times the probe cadence, with floors of 5 and 10 minutes.
  **Rationale**: Stated in the doc comments: the freshness floor means "a fast cadence does not alarm on one slow cycle"; the unconfirmed window means "a slower poller must not demote a phase it confirms on its normal schedule".
  **Approved**: pending
- **Decision**: Fail closed for an in-flight deploy with an unparseable clock.
  **Rationale**: Stated in the doc comment: such a deploy "is not believed, rather than asserting live progress on a date nothing can read".
  **Approved**: pending
- **Decision**: Publish `unconfirmedAt` so a display can demote a stale in-flight phase on its own clock.
  **Rationale**: Stated in the doc comment: a client can keep showing a snapshot after the monitor or stream stalls while it still looks connected.
  **Approved**: pending
- **Decision**: Select stale monitors by down duration only, never by DNS result.
  **Rationale**: Stated in the doc comment: "DNS decides nothing: a host that still resolves can be gone"; `dnsOk` is carried through as information.
  **Approved**: pending
- **Decision**: `staleMonitorsView` always uses the default threshold and reports `thresholdDays` from the constant.
  **Rationale**: Stated in the doc comment so the banner can state the number "without owning the number". A caller wanting another threshold must call `selectStaleMonitors` directly; recorded as the code's behavior.
  **Approved**: pending

- **Decision**: `detail` is a fixed English string (`"HTTP <statusCode>"` or `"down"`), not structured data.
  **Rationale**: The doc comment on `StaleMonitor.detail` says only "what the probe last saw: its error, else the status code, else 'down'"; the source gives no reason for building text in a verdict module. A structured `{ kind, value }` that status-web formats would let it be localized, and is the alternative to weigh. Recorded as the code's behavior.
  **Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

`separation-of-concerns` passes: the module only judges data it is handed and takes the clock as an argument, leaving probing, persistence, routing and rendering to other files. `unit-test-coverage` passes: `live-view.test.ts` covers every exported function and its boundaries; only the final `down` fallback and the empty-environment mapping are traced directly to source. `good-test-properties` passes: the tests use fixed timestamps and explicit `nowMs`, no real timers, and one concern per `it`. `fault-tolerance` passes: every malformed date has a defined result and no function throws.

`no-hardcoded-strings` is partial: the module builds the English `detail` text (`"down"`, `"HTTP <statusCode>"`) with no localization mechanism; the other strings are enum values, not text.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added a stable-order tie requirement, defined the /live field names with a Live Types link, recorded the fixed English detail text as a Design Decision and a partial no-hardcoded-strings check, simplified the WinUI note, reworded the configuration and display edge case, added related links and tags, and added vectors 022 and 023. |
