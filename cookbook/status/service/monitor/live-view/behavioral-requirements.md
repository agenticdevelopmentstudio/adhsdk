
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

