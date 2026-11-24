---
id: 24b45917-4361-44d8-a3dc-224cc2807aa9
title: "Status Report Gather"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The reading half of the status report: validates report params, reads every source in parallel and fail-soft, settles dashboards, tails failing deploy logs, then builds the report."
platforms:
  - typescript
  - web
tags:
  - status
  - report
  - fail-soft
  - parallel-reads
  - timeouts
depends-on:
  - 581dbca7-c086-48ee-a6e9-e4b80536aa1f
related:
  - 77587f0b-5a27-44d9-a507-46bb90c9046a
references: []
approved-by: ""
approved-date: ""
---

# Status Report Gather

## Overview

The module that reads every source behind `GET /report` and the MCP tool `get_report`, then hands the results to `buildReport` (specified by [adhsdk.ingredient.status.service.report.report-rules](cookbook:581dbca7-c086-48ee-a6e9-e4b80536aa1f)) to make the report. It owns four things: `parseReportParams` (the validated query), `reportSources` (the production reads, built from the app's shared services), `gatherReport` (the parallel, fail-soft read) and `logTail` (the log excerpt). It judges nothing itself. A source that throws or hangs past its deadline becomes a failed read, and the report goes on without it; the rules module turns that into coverage and a finding. The two telemetry dashboards are given up to `wait` seconds to finish a cold refresh, so a CLI or an MCP agent gets a finished answer instead of a "poll me" flag.

## Behavioral Requirements

The public surface is `ReportServices`, `ReportSources`, `LOG_DEPLOY_CAP`, `LOG_TAIL_LINES`, `REPORT_DEFAULTS`, `parseReportParams`, `logTail`, `reportSources` and `gatherReport`.

### Parameters

- **params-defaults**: `parseReportParams` MUST return `range` `24h`, `days` 7, `wait` 20 and `logs` false for any field that is absent, null or the empty string. These are the values of `REPORT_DEFAULTS`.
- **range-allowlist**: `parseReportParams` MUST reject a `range` that is not one of the values in `ANALYTICS_RANGES` (`24h`, `7d`, `30d`) with an HTTP 400 whose message is `range must be one of 24h, 7d, 30d`.
- **days-bounds**: `parseReportParams` MUST accept `days` only as an integer from 1 to 365 and MUST reject anything else with an HTTP 400 whose message is `days must be an integer 1-365`.
- **wait-bounds**: `parseReportParams` MUST accept `wait` only as an integer from 0 to 60 and MUST reject anything else with an HTTP 400 whose message is `wait must be an integer 0-60`.
- **integer-forms**: `parseReportParams` MUST accept an integer param as a number or as a string of digits with an optional leading minus sign, and MUST reject a decimal string, a non-numeric string or a non-integer number.
- **logs-forms**: `parseReportParams` MUST read `logs` as true for `true`, `1` and `'1'`, and as false for `false`, `0` and `'0'`, and MUST reject any other value with an HTTP 400 whose message is `logs must be 0 or 1`.
- **params-error-type**: Every rejection from `parseReportParams` MUST be thrown as an `HTTPException` with status 400, and the first failing field wins, checked in the order range, logs, days, wait.

### Log tails

- **log-tail-lines**: `logTail` MUST return the last `LOG_TAIL_LINES` (40) lines of a log, split on `\n` or `\r\n`, after dropping trailing whitespace.
- **log-tail-count**: `logTail` MUST return `lines` as the count of all lines of the trimmed log, not the count kept.
- **log-tail-empty**: `logTail` MUST return an empty `tail` and `lines` 0 when the trimmed log is empty.

### Production sources

- **sources-monitor-with-loop**: When `ReportServices.scheduler` is present, `reportSources.monitor` MUST return the snapshot, the board problems, `lastCycleAt` as the scheduler's last cycle time in ISO form (or null), and `stale` from the scheduler's `cycleStale()`.
- **sources-monitor-without-loop**: When `ReportServices.scheduler` is absent, `reportSources.monitor` MUST take `lastCycleAt` from the newest persisted probe time (`storage.history.newestCheckAt()`) and MUST set `stale` true only when that probe exists and is older than `defaultStaleAfterMs(config.probeIntervalSeconds * 1000)`.
- **sources-monitor-no-probe**: When no loop runs here and no probe is persisted, `reportSources.monitor` MUST return `lastCycleAt` null and `stale` false.
- **sources-deploy-log-missing**: `reportSources.deployLog` MUST return `{ error: 'deployment is not in the monitored feed' }` when the deployment id is not found, and `{ error: 'no build log for <platform> (or no token)' }` when the row exists but its log is null.
- **sources-deploy-log-tail**: `reportSources.deployLog` MUST return the `logTail` of the provider log when one is found, read with a 10 second timeout (`LOG_TIMEOUT_MS`).
- **sources-deploy-log-error**: `reportSources.deployLog` MUST convert a thrown error into `{ error: <message> }` and MUST NOT throw.
- **sources-runtime-errors**: `reportSources.runtimeErrors` MUST return `configured` from `vercelConfigured(config)`, the loaded runtime-errors report, and `failing` as `{ streak, atMs }` from the `vercel-runtime` platform fact only when that fact is configured and not ok, otherwise null.
- **sources-delegated**: `reportSources` MUST read `live` through `buildLiveSnapshot`, `uptime` through `buildUptime(storage, days)` and `integrations` through the shared `ReportServices.integrations` cache, and MUST report `monitorVersion` as `config.gitCommitSha`.

### Gathering

- **gather-parallel**: `gatherReport` MUST start the monitor, deploys, integrations, errors-dashboard, runtime-errors, analytics-dashboard and uptime reads together and wait for all of them. The deploys read is a compound read: the deploy feed first, then (when `logs` is true) the log reads in parallel, so its time is the feed time plus the log time, and the time of the whole answer follows from the slowest of the seven.
- **gather-fail-soft**: `gatherReport` MUST turn a source that throws into `{ ok: false, error: <message> }` and MUST still read and report every other source.
- **gather-source-deadline**: `gatherReport` MUST fail a non-dashboard source that has not settled within `SOURCE_TIMEOUT_MS` (20 seconds) with the error `<what> timed out after 20s`, where `<what>` is `monitor read`, `deploy feed`, `integrations check`, `runtime errors read` or `uptime read`.
- **gather-dashboard-deadline**: `gatherReport` MUST give each dashboard read `params.wait` seconds plus `SOURCE_TIMEOUT_MS` before failing it with `errors dashboard timed out after <n>s` or `analytics dashboard timed out after <n>s`.
- **gather-settle**: When a dashboard read reports `refreshing` and `params.wait` is above 0, `gatherReport` MUST call the matching settle function with `params.wait * 1000` milliseconds and then read the dashboard again, using the second read whatever the settle function returned.
- **gather-no-wait**: When `params.wait` is 0, `gatherReport` MUST NOT call a settle function and MUST use the first dashboard read as it is.
- **gather-analytics-range**: `gatherReport` MUST read the analytics dashboard and settle it for `params.range`, and MUST pass `params.days` to the uptime read.
- **gather-build**: `gatherReport` MUST return `buildReport` of the seven reads, with `now` from the injected clock (default `new Date()`) and `monitorVersion` from the sources.
- **gather-monitor-shared**: `gatherReport` MUST read the monitor once and share that one read between the monitor slot and the deploy-log selection.

### Deploy logs

- **deploys-no-logs**: When `params.logs` is false, `gatherReport` MUST read only the deploy feed (`sources.live`) and MUST NOT read any build log; the deploys input is `{ live }`.
- **deploys-feed-fails**: When the deploy feed read fails, `gatherReport` MUST return that failed read and MUST NOT read any build log, even when `params.logs` is true.
- **deploys-log-selection**: When `params.logs` is true and the feed read succeeds, `gatherReport` MUST read logs for the first `LOG_DEPLOY_CAP` (5) entries of `failingDeployProblems` of the monitor's board problems, in that function's order (newest first), by `deployment.id`.
- **deploys-log-source-of-truth**: The failing deploys whose logs are read MUST come from the board's problems, not from the deploy feed's deployments.
- **deploys-log-no-monitor**: When `params.logs` is true and the monitor read failed, `gatherReport` MUST read no build log and still return the feed read as `{ live, logs: {} }`.
- **deploys-log-parallel**: `gatherReport` MUST read the selected logs in parallel, each with a deadline of `LOG_TIMEOUT_MS` plus 1 second (11 seconds), and MUST record a log read that throws or times out as `{ error: <message> }` under that deploy id.

### Whole-answer time

- **whole-answer-deadline**: NEEDS REVIEW: Not implemented in source. Behavior undefined. A source comment says the CLI allows `wait` plus 30 seconds for the whole answer, but with `wait` 0 and `logs` true the deploy path runs the feed read (up to 20 seconds) and then the log reads (up to 11 seconds) in sequence, so a report can take up to 31 seconds; the CLI's actual request timeout lives outside this source, and reading it would settle whether the allowance is met.

## Appearance

Not applicable — this is a data-gathering module with no visual surface, not a visual component.

## States

Not applicable — this is a data-gathering module, not a visual component. Its runtime states are per-source results: each source ends as `{ ok: true, data }` or `{ ok: false, error }`, and a dashboard may still be refreshing at its deadline, which the rules module records as a coverage note.

## Accessibility

Not applicable — this is a data-gathering module, not a visual component.

## Conformance Test Vectors

Every vector is covered by a test in `report-gather.test.ts` in the status-server `test` directory; each test title starts with its vector id.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| report-gather-001 | params-defaults | `parseReportParams({})`; and with `range`, `days`, `wait`, `logs` all `''` (test: `defaults`) | `{ range: '24h', days: 7, wait: 20, logs: false }` for the first; `days` 7 and `wait` 20 for the second |
| report-gather-002 | integer-forms, logs-forms, range-allowlist | `{ range: '30d', days: '365', wait: '0', logs: '1' }` (test: `accepts the CLI's query and the MCP tool's typed values`) | `{ range: '30d', days: 365, wait: 0, logs: true }` |
| report-gather-003 | days-bounds, integer-forms, params-error-type | `{ days: '0' }`, `'366'`, `'1.5'`, `'seven'` (test: `rejects %j with a 400`) | Each throws an `HTTPException`, status 400, message `days must be an integer 1-365` |
| report-gather-004 | wait-bounds | `{ wait: '-1' }` and `{ wait: 61 }` | Each throws status 400, message `wait must be an integer 0-60` |
| report-gather-005 | logs-forms | `{ logs: 'yes' }` and `{ logs: 2 }`; and `{ logs: '0' }` | The first two throw status 400, message `logs must be 0 or 1`; the third returns `logs` false |
| report-gather-006 | range-allowlist | `{ range: '1y' }` | Throws status 400, message `range must be one of 24h, 7d, 30d` |
| report-gather-007 | params-error-type | `{ range: '1y', days: '0' }` | The message is the range message, not the days message |
| report-gather-008 | log-tail-lines, log-tail-count, log-tail-empty | `logTail('a\nb\r\nc\n\n')` and `logTail('')` (test: `keeps the last lines and counts them all`) | `{ tail: ['a','b','c'], lines: 3 }` and `{ tail: [], lines: 0 }` |
| report-gather-009 | log-tail-lines, log-tail-count | A 60-line log (from the `logs=1` test) | `tail` has 40 entries ending in the 60th line, and `lines` is 60 |
| report-gather-010 | gather-build, gather-parallel | Healthy sources, `wait` 0, clock `2026-11-06T12:00:00Z` (test: `reads every source into a healthy, complete report`) | `verdict` `healthy`, `complete` true, `monitorVersion` `v1`, `generatedAt` `2026-11-06T12:00:00.000Z` |
| report-gather-011 | gather-fail-soft | `integrations` throws `integrations exploded` (test: `a source that throws is uncovered...`) | `coverage.integrations` is `{ ok: false, error: 'integrations exploded' }`, `sections.integrations` null, a major finding `could not read integrations`, `complete` false, `verdict` `degraded`, and `uptime` still read |
| report-gather-012 | gather-settle, gather-analytics-range | Both dashboards refreshing until settled, `wait` 5, `range` `7d` (test: `a dashboard refreshing on first read is given wait to settle`) | `settleErrors` called with 5000, `settleAnalytics` called with `7d` and 5000, `complete` true, no `errors` coverage notes |
| report-gather-013 | gather-settle | The errors dashboard stays refreshing and its settle returns false, `wait` 1 (test: `a dashboard still refreshing at the deadline`) | `coverage.errors.notes` contains `errors dashboard still refreshing at the deadline`, `complete` false, `verdict` `unknown` |
| report-gather-014 | gather-no-wait | Analytics dashboard refreshing, `wait` 0 (test: `wait=0 never waits`) | `settleAnalytics` is not called; `coverage.analytics.notes` contains `analytics dashboard still refreshing at the deadline` |
| report-gather-015 | gather-analytics-range | `days` 30 (test: `passes days to the uptime read`) | `sections.uptime.days` is 30 |
| report-gather-016 | deploys-log-selection, deploys-log-source-of-truth, deploys-log-parallel, gather-monitor-shared | Seven failing board problems `d0` to `d6`, `logs` true, empty feed; `d6` has no token (test: `logs=1 attaches...`) | `deployLog` called 5 times, in order `d6 d5 d4 d3 d2`; `failing` lists all seven newest first; `d6` has `logError` `no build log for vercel (or no token)`; `d5` has a 40-line `logTail` ending `d5 59` and `logLines` 60; `d0` has no log fields |
| report-gather-017 | deploys-no-logs | One failing problem, `logs` false (test: `without logs no build log is read`) | `deployLog` is never called |
| report-gather-018 | deploys-log-parallel | `deployLog` throws `socket hang up`, `logs` true (test: `a log read that throws becomes that deploy's logError`) | `failing[0]` has `logError` `socket hang up` |
| report-gather-019 | deploys-feed-fails | `live` rejects, `logs` true, failing problems on the board | No `deployLog` call; the deploys read is failed with the feed's error |
| report-gather-020 | gather-source-deadline, gather-dashboard-deadline | A source that never settles; and a dashboard that never settles with `wait` 5 | After 20 seconds that source is `{ ok: false, error: '<what> timed out after 20s' }`; the dashboard fails after 25 seconds with `errors dashboard timed out after 25s`; the report is built either way |
| report-gather-021 | sources-monitor-without-loop, sources-monitor-no-probe | No scheduler; newest probe older than `defaultStaleAfterMs` of the probe interval; then no probe at all | First: `stale` true and `lastCycleAt` is the probe time; second: `lastCycleAt` null, `stale` false |
| report-gather-022 | sources-monitor-with-loop | A scheduler whose `cycleStale()` is true and `lastCycleAt()` is null | `stale` true, `lastCycleAt` null, and `storage.history.newestCheckAt` is not called |
| report-gather-023 | sources-deploy-log-missing, sources-deploy-log-tail, sources-deploy-log-error | `fetchDeploymentLog` returns null; returns a row with a null log; returns a log; throws `boom` | `{ error: 'deployment is not in the monitored feed' }`; `{ error: 'no build log for <platform> (or no token)' }`; the `logTail` of the log; `{ error: 'boom' }` |
| report-gather-024 | sources-runtime-errors, sources-delegated | The `vercel-runtime` fact is configured and not ok with streak 3 at `sampledAtMs` 99 | `failing` is `{ streak: 3, atMs: 99 }`; with the fact ok or absent it is null; `monitorVersion` equals `config.gitCommitSha` |
| report-gather-025 | deploys-log-no-monitor | Monitor read fails, `logs` true | No `deployLog` call; the deploys read is `{ ok: true, data: { live, logs: {} } }` |
| report-gather-026 | params-error-type | `{ range: '1y', logs: 'yes', days: '0', wait: '99' }`, then `{ logs: 'yes', days: '0', wait: '99' }`, then `{ days: '0', wait: '99' }` | Each throws status 400; the messages are the range message, the logs message and the days message in turn, so the check order is range, logs, days, wait |
| report-gather-027 | integer-forms, params-defaults, log-tail-empty, log-tail-count | `{ days: '+5' }`, `{ days: ' 5' }`, `{ days: '1e1' }` (each rejected); `{ days: '007' }` (accepted as 7); `{ range: null, days: null, wait: null, logs: null }` (all defaults); then `logTail('  \n \t ')` and `logTail('x  ')` | The first three throw status 400 with the days message; `days` is 7 for `'007'`; the null fields give `{ range: '24h', days: 7, wait: 20, logs: false }`; the whitespace-only log gives `{ tail: [], lines: 0 }` and `'x  '` gives `{ tail: ['x'], lines: 1 }` |

The `whole-answer-deadline` bullet carries an open question and has no vector.

## Edge Cases

- **Null and empty params** (MUST): null, undefined and `''` for `range`, `days`, `wait` or `logs` take the default; they are never an error.
- **Boundary params** (MUST): `days` 1 and 365 and `wait` 0 and 60 are accepted; 0 and 366, and -1 and 61, are rejected.
- **Param forms** (MUST): `'+5'`, `' 5'` and `'1e1'` are not digit strings and are rejected; `'007'` is accepted as 7. A numeric `logs` other than 0 or 1 is rejected.
- **Empty or whitespace log** (MUST): a log of only whitespace gives `{ tail: [], lines: 0 }`; a one-line log gives that line and `lines` 1. Trailing spaces on the last line are dropped too.
- **Source throws** (MUST): the read becomes a failed read with the error's message, or `String(err)` for a non-Error throw; no other read is affected.
- **Source hangs** (MUST): the deadline rejects after 20 seconds (dashboards: `wait` plus 20). The deadline does not cancel the underlying work, which may keep running after the report is returned; the code has no cancellation.
- **Dashboard still refreshing** (MUST): the second read is used even when settle returned false or timed out; the rules module records the note.
- **Dashboard settle throws** (MUST): the throw fails that dashboard read like any other source error.
- **Concurrent access**: the sources are read concurrently with `Promise.all` on single-threaded JavaScript, and the only shared promise is the monitor read, awaited by the deploy-log selection after the feed read. Each call to `gatherReport` is independent; the dashboards and integrations caches are shared with the routes and own their own ordering.
- **Failed or empty board** (MUST): with `logs` true and a monitor read that failed, or a board with no failing deploys, no log is read.
- **More than five failing deploys** (MUST): only the first five by the board's order have logs; the rest are listed without log fields.
- **Log source unavailable** (MUST): a missing deployment, a missing token, a provider error or a timeout is recorded as that deploy's `{ error }`; it never fails the report.
- **Storage unavailable**: a storage error inside a source read is the same as any thrown error and becomes a failed read.
- **Offline or disconnected state**: the module makes no network call itself; it awaits reads that do (providers, dashboards, log fetch). A disconnect during one of them surfaces as that source's error or its deadline, and the report is still built from the rest. With no scheduler, `lastCycleAt` comes from the stored probe, so a monitor running elsewhere is judged by data, not by liveness.

## Configuration
Request parameters, which a caller can set:


| Option | Type | Default | Description |
| `range` | `24h`, `7d` or `30d` | `24h` | Analytics dashboard range |
| `days` | integer 1 to 365 | 7 | Window of the uptime read |
| `wait` | integer 0 to 60 seconds | 20 | How long each dashboard may finish a cold refresh |
| `logs` | boolean | false | Attach the log tail of failing deploys |

Internal constants, which a caller cannot set and a port must not expose as settings:

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `LOG_DEPLOY_CAP` | exported constant | 5 | Failing deploys whose log is read |
| `LOG_TAIL_LINES` | exported constant | 40 | Lines of each log kept |
| `LOG_TIMEOUT_MS` | constant, not exported | 10000 | Each log read, plus 1000 ms on the outer deadline |
| `SOURCE_TIMEOUT_MS` | constant, not exported | 20000 | Any non-dashboard source; dashboards add `wait` |

Injected dependencies and test seams, supplied by the host code or a test and never by a request:


| Option | Type | Default | Description |
| `ReportServices` | `storage`, `config`, `dashboards`, `integrations`, optional `scheduler` | injected | Built once in `createApp` and shared with MCP |
| `ReportSources` | seam of seven reads | `reportSources(services)` | Tests swap any read |
| `now` | function returning a `Date` | `() => new Date()` | Injected clock |
| `config.gitCommitSha`, `config.probeIntervalSeconds` | `StatusConfig` | from config | Report version and the no-loop stale window |
## Deep Linking

Not applicable: the module has no routes or URLs of its own; the routes that call it are specified by [adhsdk.ingredient.status.service.routes](cookbook:77587f0b-5a27-44d9-a507-46bb90c9046a).

## Localization

Not applicable: no localization exists in this module. The deadline messages (`<what> timed out after <n>s`), the log messages (`deployment is not in the monitored feed`, `no build log for <platform> (or no token)`) and the param 400 messages are hardcoded English strings that surface in the report and the response.

## Accessibility Options

Not applicable: the module has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the module reads no feature flag; `logs` and `wait` are per-request params, not flags.

## Analytics

Not applicable: the module sends no analytics event. It reads the analytics dashboard as report data, which is a different thing.

## Privacy

- **Data collected**: None collected by this module. It carries commit messages, deploy error text, provider log tails and error groups from its sources into the report.
- **Storage**: None. Nothing is persisted; the report is built per call.
- **Transmission**: The report goes to the caller of `/report` or `get_report`. `deployLog` reads provider logs through `fetchDeploymentLog`, which uses the provider connection held in the app's storage and config; no token is added to the payload by this module.
- **Retention**: None.

Log tails are passed through as read. The module does no redaction.

## Logging

Not applicable: the module has no log call. A failure is returned in the failed read and so reaches the report as coverage and a finding, never as a log line.

## Platform Notes

- **SwiftUI**: The source is TypeScript on the web; a Swift port is an orchestrator. Use `async let` or a `TaskGroup` for the seven reads, and wrap each in a helper that returns a `Result` and races a `Task.sleep` deadline inside `withThrowingTaskGroup`, cancelling the loser (the source cannot cancel). Throw a typed error carrying status 400 for params.
- **Compose**: Use Kotlin coroutines: `async` for each read inside `coroutineScope`, `withTimeout` for the deadline (which does cancel, unlike the source) and `runCatching` for the fail-soft wrapper. Call the dashboard's own settle function for the wait.
- **React/Web**: The source platform. The files are `src/report/report-gather.ts` in the status-server package, with `report-rules.ts` and `types.ts` beside it and `test/report-gather.test.ts` as its tests. `Promise.race` against a `setTimeout` is the deadline, cleared in `finally`; `Promise.all` is the parallelism, safe because every wrapped read never rejects. `HTTPException` comes from `hono/http-exception`.
- **AppKit / UIKit**: Same as SwiftUI. Use `URLSession` for any provider read behind the sources and `withTaskGroup` for the fan-out; do the gather off the main actor.
- **WinUI 3**: Use `Task.WhenAll` over seven tasks, each wrapped in a helper that catches and returns a `SourceRead` record. For the deadline use `Task.WhenAny(work, Task.Delay(timeout))`, or pass a `CancellationTokenSource(timeout)` to `HttpClient` and the storage calls, which cancels the work where the source only abandons it. Validate params in the minimal API handler and return `Results.BadRequest` with the same message; model `SourceRead<T>` as a pair of records. In a server host, `ReportServices` is a singleton registered in dependency injection with the scheduler optional, and `System.Text.Json` serialises the result.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/report/report-gather.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every source is read through a wrapper that never throws, and a failed read is data (`{ ok: false, error }`).
**Rationale**: A report about a failing fleet must still arrive when one source is the thing that is failing. The rules module turns each failure into coverage and a major finding, so nothing is silent.
**Approved**: pending

**Decision**: The deadline is a `Promise.race` and does not cancel the work it abandons.
**Rationale**: The sources are shared reads and caches with no cancellation hook. The cost is that an abandoned read may finish later and is simply ignored.
**Approved**: pending

**Decision**: Dashboards get `wait` seconds to settle, and the first-read result is replaced by a second read whether or not settle succeeded.
**Rationale**: A cold refresh would otherwise return a "poll me" flag to a CLI or an agent that cannot poll. A dashboard still refreshing at the deadline is disclosed by the rules module as a coverage note, not read as healthy.
**Approved**: pending

**Decision**: Failing-deploy logs follow the board's failing list (`failingDeployProblems`), not the deploy feed.
**Rationale**: The report lists the board's failing deploys, so the logs must belong to those same builds. The test `logs=1 attaches...` uses an empty feed to pin this.
**Approved**: pending

**Decision**: With no scheduler in the process, the stale window is computed here from the newest stored probe with `defaultStaleAfterMs`.
**Rationale**: The monitor loop may run in another process; one stale rule (the scheduler's window) applies either way, so the two cannot disagree.
**Approved**: pending

**Decision**: Whole-answer time is bounded only by per-source deadlines, which add up in the deploy-log path.
**Rationale**: The log reads must follow the feed read, because the failing list is only needed for them. The open question on `whole-answer-deadline` records the one case that exceeds the stated allowance.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

Reading, validating and judging are separate: this module reads and validates, and the rules module judges, so separation of concerns is met. Every conformance vector has a passing test in `test/report-gather.test.ts`, including the production `reportSources` reads and the 20 and 25 second deadlines, so unit-test coverage is passed. Every failure becomes a failed read rather than a throw, which meets explicit error handling and graceful degradation. Every source has a deadline, but the deadline abandons the work instead of cancelling it and the deploy path can exceed the stated whole-answer allowance, so timeout handling is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (report-gather.test.ts, 27 of 27 vectors); unit-test coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Linked the report-rules and routes recipes and added the rules recipe to depends-on, marked vectors 007 and 019 to 027 as untested, added vectors 026 and 027 for check order and param forms, split Configuration into request params, internal constants and seams, said deploys is a compound read, and removed (MUST) from the descriptive edge cases. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
