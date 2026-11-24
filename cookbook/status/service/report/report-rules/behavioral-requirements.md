
The public surface is the constants `UPTIME_FLOOR`, `ERROR_ISSUE_CAP`, `RUNTIME_GROUP_CAP`, `SITE_ROW_CAP`, `RUNTIME_5XX_MAJOR_COUNT`; the types `SourceRead`, `MonitorInput`, `DeployLogTail`, `DeploysInput`, `RuntimeErrorsInput`, `ReportInputs`, `DeployProblem`; and the functions `firstLine`, `issueKeys`, `digestMonitor`, `newestPerTarget`, `failingDeployProblems`, `digestDeploys`, `digestIntegrations`, `activeIssueOrder`, `siteTroubled`, `glitchtipListCurrent`, `digestErrors`, `runtimeSeverity`, `digestRuntimeErrors`, `digestAnalytics`, `digestUptime`, `compareFindings` and `buildReport`. A digest is `{ notes, unconfigured, findings, section, updatedAt? }`.

### Constants

- **constants-values**: The module MUST use `UPTIME_FLOOR` 99.5, `ERROR_ISSUE_CAP` 15, `RUNTIME_GROUP_CAP` 15, `SITE_ROW_CAP` 10 and `RUNTIME_5XX_MAJOR_COUNT` 5. It MUST take the failure-rate line used by `siteTroubled` from the dashboard views module (`telemetry/dashboard/views.ts`, specified by [adhsdk.ingredient.status.service.telemetry.dashboard.views](cookbook:967202ce-c607-4115-9f63-466a4004e7f3)): `FAILURE_RATE_HIGH` is 0.05, and `isFailureRateHigh(failures, requests)` is true when `requests` is above 0 and `failures / requests` is at least 0.05.

### Text helpers

- **first-line**: `firstLine` MUST return null for null, undefined, empty or whitespace-only text, and otherwise the first non-empty-trimmed line (split on `\n` or `\r\n`), trimmed.
- **first-line-width**: `firstLine` MUST cut a line longer than `width` (default 160) to `width - 1` characters followed by the ellipsis character.
- **finding-shape**: A finding MUST carry `severity`, `source` and `title`, and MUST add `detail` (as the first line of the given text), `since`, `link` and `issueKey` only when each is non-empty.

### Building the report

- **build-envelope**: `buildReport` MUST return `schema` `REPORT_SCHEMA`, `generatedAt` as `now` in ISO form, and `monitorVersion` as given.
- **build-coverage-keys**: `buildReport` MUST give coverage and sections one entry for each of the seven `REPORT_SOURCES` in order: `monitor`, `deploys`, `integrations`, `errors`, `runtimeErrors`, `analytics`, `uptime`.
- **failed-source**: For a source whose read failed, `buildReport` MUST set coverage to `{ ok: false, error }`, the section to null, and add a major finding with source `report`, title `could not read <name>` and the error as detail.
- **ok-coverage**: For a source read, `buildReport` MUST set coverage `ok` true, MUST include `notes` and `unconfigured` only when non-empty, and MUST include `updatedAt` whenever the digest defines it (null included).
- **complete-rule**: `buildReport` MUST set `complete` true only when every source is read and no source has any note. `unconfigured` entries MUST NOT clear it.
- **section-null-rule**: A section MUST be null exactly when its source failed.
- **verdict-rule**: `buildReport` MUST take the verdict from the worst finding (critical gives `down`, major gives `degraded`, minor gives `attention`), and with no findings MUST give `healthy` when `complete` and `unknown` otherwise.
- **counts-rule**: `buildReport` MUST report `counts` as the number of findings at each of `critical`, `major` and `minor`.
- **finding-order**: `compareFindings` MUST order findings by severity (critical first), then by `source`, then by `title`, comparing text by code unit; `buildReport` MUST return findings in that order.
- **dedupe-context**: `buildReport` MUST tell the monitor digest whether the GlitchTip issue list is current (from the errors read) and which provider health the deploys read holds (null when it failed).

### Monitor

- **monitor-problems**: `digestMonitor` MUST make one finding per board problem, with severity the problem's own severity, source `monitor:<problem source>`, title `<name> <environment>: <source> <state>` (the parts of each half joined by single spaces, empty parts omitted), detail from the problem's detail, `since`, `link` as `sourceUrl` else `liveUrl`, and `issueKey` from `issueKeys`.
- **monitor-no-regrade**: `digestMonitor` MUST NOT raise a finding for a service that has no board problem, and MUST still count it in `byStatus`.
- **monitor-glitchtip-dedupe**: `digestMonitor` MUST skip a board problem whose target is a GlitchTip errors target when the GlitchTip list is current, and MUST keep it otherwise.
- **monitor-provider-dedupe**: `digestMonitor` MUST skip a board problem whose target is a platform-health target for a provider present in the deploys read, and MUST keep it when the deploys read is absent or lacks that provider.
- **issue-keys**: `issueKeys` MUST map each open issue's target to its name when that name is non-empty and unique among the open issues, and to its target otherwise.
- **monitor-stale**: When `stale` is true, `digestMonitor` MUST add the note `monitor data is stale: <detail>` and a major finding titled `status monitor has stopped probing` with source `monitor`, where the detail is `last completed cycle at <lastCycleAt>` or `no cycle has completed since the loop started`.
- **monitor-never-cycled**: When not stale and `lastCycleAt` is null, `digestMonitor` MUST add the note `monitor has not completed a probe cycle` and no finding.
- **monitor-section**: `digestMonitor` MUST return `overall`, `checkedAt` (the snapshot's `generatedAt`), `lastCycleAt`, `stale`, the service count, `byStatus` counts, the open-issue count and `unprobed` (names of services with status `unknown`, sorted), and MUST set coverage `updatedAt` to `lastCycleAt`.

### Deploys

- **failing-list**: `failingDeployProblems` MUST return only board problems with state `failed` that name a deployment, newest deployment `createdAt` first, ties broken by deployment id.
- **deploys-failing-section**: `digestDeploys` MUST list failing deploys from the board's problems only, never from the feed, each with `id`, `platform` (the problem source), `project`, `tier` (the environment), `branch`, `createdAt`, `commit` (first line, 80 characters), `error` (first line, 160 characters) and `url` (the `sourceUrl`).
- **deploys-log-fields**: For a failing deploy with a log entry, `digestDeploys` MUST set `logError` when the entry is an error, and otherwise `logTail` and `logLines`.
- **deploys-no-board**: When the board problems are null, `digestDeploys` MUST list no failing deploys and MUST add the note `failing deploys come from the board, which could not be read`.
- **deploys-providers**: `digestDeploys` MUST list providers that are not configured under `unconfigured` (sorted by name), and for a configured provider that is not ok MUST add a finding with source `provider:<name>` and title `<name> API unreachable from the monitor`, with the severity of the board's platform-health problem for that name, else minor.
- **deploys-config-degraded**: When the feed reports `configDegraded`, `digestDeploys` MUST add the note `monitor config fell back to the static list: <reason>`, using `reason unknown` when there is none.
- **deploys-section**: `digestDeploys` MUST report `deployTargets` as the count of `newestPerTarget` of the feed, `inFlight` as those whose `effectiveStatus` is `building` or `queued`, plus `staleProd` and `providers` from the feed, and MUST set coverage `updatedAt` to the feed's `lastCycleAt`.
- **newest-per-target**: `newestPerTarget` MUST keep one deployment per (platform, provider project id or else project name, tier or else environment), the one with the latest `createdAt`.
- **deploys-no-findings-for-failures**: `digestDeploys` MUST NOT add findings for failing or stale deploys, because those are findings through their board problem.

### Integrations

- **integrations-findings**: `digestIntegrations` MUST add a major finding for a check in state `error` and a minor finding for state `warn`, with source `integration:<id>`, title `<label> integration <state>` (label falls back to id) and the first line of the detail.
- **integrations-unconfigured**: `digestIntegrations` MUST list a check that is not configured and not in state `error` under `unconfigured` as its label, followed by `(unset: <names>)` when it has `missingEnv`, and MUST raise no finding for it.
- **integrations-error-wins**: A check in state `error` MUST raise its finding even when it reports `configured` false, and MUST NOT be listed as unconfigured.
- **integrations-section**: `digestIntegrations` MUST return `overall` and each check's `id`, `label`, `configured`, `state` and first-line `detail`, and set coverage `updatedAt` to the response's `generatedAt`.

### Errors

- **errors-notes**: `digestErrors` MUST list `glitchtip` and `posthog` as unconfigured when not configured, and MUST add `errors dashboard still refreshing at the deadline` when `refreshing`.
- **errors-section-notes**: `digestErrors` MUST add a note `<label>: <error>` for each errored section (`glitchtip issues`, `posthog site health`, `posthog error detail`), with `(showing older data)` appended when the section still holds data, and MUST add `glitchtip issue list could not be read to the end` when the issue summary is not complete.
- **errors-issue-findings**: `digestErrors` MUST make a finding for each active GlitchTip issue, in `activeIssueOrder`, up to `ERROR_ISSUE_CAP`, with severity major for level `fatal` and minor otherwise, source `glitchtip`, title `<project>: <title first line, 100 characters>` (the id when the title is empty), detail `<count> events, <userCount> users` plus `, in <source>` when present, `since` as `firstSeen` and `link` as `permalink`.
- **issue-order**: `activeIssueOrder` MUST order `fatal` issues first, then by higher `count`, then by `title`.
- **errors-issue-overflow**: When more than `ERROR_ISSUE_CAP` issues are active, `digestErrors` MUST add one finding titled `<n> more active GlitchTip issues not listed`, detail `all are in sections.errors.active`, whose severity is the worst of the hidden issues (major if any hidden issue is fatal, else minor).
- **errors-site-findings**: `digestErrors` MUST sort site rows by errors plus failures descending, then host, consider only the first `SITE_ROW_CAP`, and add a minor finding with source `posthog` and title `<host>: <errors> client errors, <failures> failed of <requests> requests` for each troubled row, with detail `p95 <n>ms` when p95 is not null.
- **site-troubled**: `siteTroubled` MUST be true when requests are 0 and errors plus failures are above 0, and otherwise when errors plus failures divided by requests is at least 5% (`isFailureRateHigh`).
- **glitchtip-current**: `glitchtipListCurrent` MUST be true only when the issues section has data, has no error, no GlitchTip refresh is in progress (`refreshingSources.glitchtip` false) and the summary is complete; a PostHog refresh MUST NOT affect it.
- **errors-section**: `digestErrors` MUST return `summary`, all active issues, all site rows (sorted), `siteErrors` and `failedRequests` (empty when absent), and set coverage `updatedAt` to the issues `updatedAt` else the sites `updatedAt`.

### Runtime errors

- **runtime-severity**: `runtimeSeverity` MUST be major for level `fatal` or a status of 500 or above with a count of at least `RUNTIME_5XX_MAJOR_COUNT`, and minor otherwise.
- **runtime-findings**: `digestRuntimeErrors` MUST rank groups major before minor, keeping the store's order within a severity, and list the first `RUNTIME_GROUP_CAP` as findings with source `vercel-runtime`, title `<project>: <method path, else source>` plus ` → <status>` when the status is not null, detail `<count>× <level>: <message>`, `since` as `firstSeen` and `link` as `https://<domain>` when there is a domain.
- **runtime-overflow**: `digestRuntimeErrors` MUST add one finding titled `<n> more Vercel runtime error groups not listed` with detail `see sections.runtimeErrors.groups` when the larger of `total` and the group count exceeds the number listed, and its severity MUST be the worst of the ranked groups past the cap, minor when there are none.
- **runtime-notes**: When `configured`, `digestRuntimeErrors` MUST add `vercel runtime errors not read yet` when `readAt` is null, else `vercel runtime read was cut short; there may be more groups than listed` when not complete, and for a failing read MUST add `last <n> vercel runtime read(s) failed (latest <ISO time>)`, with `read` when the streak is 1 and `reads` otherwise, followed by `; these groups are from the read at <readAt>` when a read exists.
- **runtime-unconfigured**: When not `configured`, `digestRuntimeErrors` MUST list `vercel` as unconfigured and add no note.
- **runtime-updated-at**: `digestRuntimeErrors` MUST set coverage `updatedAt` to `readAt` when configured and null otherwise, and the section MUST return `window`, `readAt`, `complete`, `total` and all `groups`.

### Analytics and uptime

- **analytics-notes**: `digestAnalytics` MUST list `posthog` and `vercel` as unconfigured when not configured, add `analytics dashboard still refreshing at the deadline` when `refreshing`, add `<label>: <error>` (with `(showing older data)` when data remains) for each errored section (`posthog traffic`, `posthog dimensions`, `posthog paths`, `posthog web vitals`, `posthog site health`, `vercel web analytics`), and add `vercel web analytics: <n> projects could not be read` when the Vercel `failed` count is above 0.
- **analytics-no-findings**: `digestAnalytics` MUST return no findings.
- **analytics-section**: `digestAnalytics` MUST return `range`, PostHog totals and sites (host, pageviews, sessions) and Vercel totals, counts and projects (project, domain, pageviews, visitors), each list sorted by pageviews descending then name, and `vitals`; missing data MUST be null or empty, and coverage `updatedAt` is the traffic `updatedAt` else the Vercel `updatedAt`.
- **uptime-findings**: `digestUptime` MUST add a minor finding with source `uptime` and title `<name>: <percent to 2 decimals>% up over <days>d` for each service whose `uptimePercent` is not null and below `UPTIME_FLOOR`, lowest first; a service at exactly the floor or with null uptime MUST NOT be listed.
- **uptime-section**: `digestUptime` MUST return `days`, `floor` and each service's `slug`, `name`, `uptimePercent` and `totalChecks`, with no notes and no `updatedAt`.

