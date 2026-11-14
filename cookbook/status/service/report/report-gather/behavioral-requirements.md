
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

