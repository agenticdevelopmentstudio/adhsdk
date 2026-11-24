---
id: 581dbca7-c086-48ee-a6e9-e4b80536aa1f
title: "Status Report Rules"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The pure rules that turn the status report's source reads into findings, coverage, a verdict and sections; no I/O and no clock."
platforms:
  - typescript
  - web
tags:
  - status
  - report
  - pure-rules
  - findings
  - verdict
depends-on:
  - e2b50620-c7b1-4268-a56e-e039fea3349f
  - 967202ce-c607-4115-9f63-466a4004e7f3
related:
  - 77587f0b-5a27-44d9-a507-46bb90c9046a
  - 24b45917-4361-44d8-a3dc-224cc2807aa9
references: []
approved-by: ""
approved-date: ""
---

# Status Report Rules

## Overview

The business logic of the status report. `buildReport` takes the seven source reads (each a payload or the reason there is none), a `now` date and a monitor version, and returns the `ReportResponse`: a verdict, severity counts, per-source coverage, a sorted list of findings and one section per source. The module is pure: no I/O, no clock (`now` is an input), so every rule is tested with fixtures. The reading half, which produces the inputs, is [adhsdk.ingredient.status.service.report.report-gather](cookbook:24b45917-4361-44d8-a3dc-224cc2807aa9).

Two rules carry the rest. First, a missing source is never a healthy source: a failed read, an errored or still-refreshing dashboard section, and a monitor that stopped cycling each land in coverage and make `complete` false, so "no findings" with `complete` false means "don't know". A provider with no credentials is listed as `unconfigured` instead and does not clear `complete`, because it is a standing fact about the deployment. Second, every finding names where it came from (`source`) and, where there is one, where to look next (`link`, `issueKey`). The payload shapes are specified by [adhsdk.ingredient.status.service.report.types](cookbook:e2b50620-c7b1-4268-a56e-e039fea3349f).

## Behavioral Requirements

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

## Appearance

Not applicable — this is a pure rules module, not a visual component.

## States

Not applicable — this is a pure rules module, not a visual component. Each source read is either `{ ok: true, data }` or `{ ok: false, error }`, and the module keeps no state between calls.

## Accessibility

Not applicable — this is a pure rules module, not a visual component.

## Conformance Test Vectors

Every vector is covered by a test in `report-rules.test.ts`, whose titles start with the vector id (test names in parentheses are the original descriptions).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| report-rules-001 | build-envelope, verdict-rule, complete-rule, counts-rule | A healthy fleet (test: `a healthy fleet is healthy and complete`) | `verdict` `healthy`, `complete` true, no findings, counts all 0, the given `monitorVersion` and `generatedAt` as `now` in ISO form |
| report-rules-002 | ok-coverage, complete-rule | Cloudflare Pages unconfigured (test: `an unconfigured provider is disclosed...`) | `coverage.deploys.unconfigured` is `['cloudflare-pages']` and `complete` true |
| report-rules-003 | failed-source, section-null-rule, verdict-rule, complete-rule | `errors` read failed with `GlitchTip timed out` (test: `a failed source is never healthy`) | `complete` false, coverage `{ ok: false, error }`, `sections.errors` null, `verdict` `degraded`, a major `report` finding `could not read errors` |
| report-rules-004 | errors-section-notes, verdict-rule | Issues section errored `GlitchTip 500` with no data (test: `a failed dashboard section makes the report incomplete`) | Note `glitchtip issues: GlitchTip 500`, `complete` false, `verdict` `unknown` |
| report-rules-005 | monitor-problems, issue-keys | One failed vercel problem with detail `Build failed\nmore` (test: `open issues become findings with the issues-show key`) | One finding: major, `monitor:vercel`, `zork production: vercel failed`, detail `Build failed`, the `since`, `link`, `issueKey` `zork`; verdict `degraded` |
| report-rules-006 | monitor-problems, verdict-rule | A critical `http` problem (test: `a down endpoint is critical...`) | `verdict` `down`; finding critical, `monitor:http`, `Shop production: http down`, detail `timeout` |
| report-rules-007 | monitor-no-regrade, monitor-section | Services `down` and `degraded` with no board problems (test: `a non-healthy service the board holds back...`) | No findings, `verdict` `healthy`, `byStatus` `{ degraded: 1, down: 1 }` |
| report-rules-008 | failing-list, deploys-failing-section | Problems: failed d1 (09:00), failed d2 (10:00), a `stuck` one, one with no deployment (test: `failing deploys are the board's failed deploy problems`) | Failing ids `['d2','d1']`; `d2` is `{ id, platform 'vercel', project 'b', tier 'staging', branch 'staging', createdAt, commit 'fix: thing', error 'Type error', url }` |
| report-rules-009 | deploys-failing-section, deploys-no-findings-for-failures | A newer canceled row and a failed preview in the feed; board holds d1 and an old d0 (test: `the feed's newest row does not decide...`) | Failing ids `['d1','d0']` and `deployTargets` 2 |
| report-rules-010 | deploys-no-board | Monitor read failed (test: `with no board to read...`) | `failing` empty and the note `failing deploys come from the board, which could not be read` |
| report-rules-011 | deploys-section | Two `building` rows, one with `effectiveStatus` `unknown` (test: `an unconfirmed in-flight deploy...`) | `inFlight` 1 |
| report-rules-012 | monitor-stale, complete-rule | `stale` true, `lastCycleAt` set (test: `a stalled monitor is a major finding and incomplete`) | First note starts `monitor data is stale`, major finding `status monitor has stopped probing`, `stale` true, `complete` false |
| report-rules-013 | errors-issue-findings, issue-order, errors-issue-overflow, errors-section | 20 active issues, one inactive, one fatal (test: `active GlitchTip issues surface, fatal first, and are capped`) | 16 `glitchtip` findings (15 plus `6 more active GlitchTip issues not listed`, minor); the first finding is major `api: Fatal`; the section lists 21 active with the fatal first; the inactive one is not a finding |
| report-rules-014 | errors-site-findings, site-troubled, uptime-findings, verdict-rule | Sites a (3 errors, 2 of 50), b (clean), c (1 in 100,000), d (2 errors, 0 requests); Shop at 97.5% (test: `PostHog site errors and low uptime are minor findings`) | Findings for `a.dev`, `d.dev` and `Shop: 97.50% up over 7d`; none for b or c; `verdict` `attention` |
| report-rules-015 | analytics-notes, verdict-rule | Analytics `refreshing` true (test: `a dashboard still refreshing at the deadline is incomplete`) | Note `analytics dashboard still refreshing at the deadline`, `complete` false, `verdict` `unknown` |
| report-rules-016 | monitor-glitchtip-dedupe | An errors board problem and a current issue list; then the errors read failed (test: `counts a GlitchTip error once`) | First: sources `['glitchtip']`; second: `monitor:glitchtip` is present with no `issueKey` |
| report-rules-017 | glitchtip-current, monitor-glitchtip-dedupe | Failed refresh, GlitchTip refreshing, partial list; PostHog-only refresh (tests: `a GlitchTip list that is not current...`, `a PostHog refresh leaves...`) | `glitchtipListCurrent` false for the first three and the board problem stays (`degraded`); true for the PostHog refresh and the board problem is skipped |
| report-rules-018 | monitor-provider-dedupe, deploys-providers | Vercel provider configured and not ok, with a minor platform-health problem on the board (test: `an unreachable provider is one finding...`) | One finding: minor, `provider:vercel`, `vercel API unreachable from the monitor`; with no board problem it is still minor |
| report-rules-019 | monitor-problems, verdict-rule | A major prod stale and a minor testing stale (tests: `a stale deploy keeps the board's severity`, `a testing-tier stale deploy alone is attention`) | Findings keep major and minor, verdict `degraded`; the testing one alone gives `attention` |
| report-rules-020 | issue-keys | Two open issues sharing a name; then one alone (test: `an issue key is the target when two open issues share a name`) | Keys are the targets for the pair; the name `zork` for the lone issue |
| report-rules-021 | integrations-findings, integrations-unconfigured, integrations-section | cron `error`, posthog `warn`, railway unconfigured with `RAILWAY_TOKEN` (test: `integration error is major...`) | Findings major `Cron integration error` (detail `missed`) and minor `PostHog integration warn`; unconfigured `['Railway (unset: RAILWAY_TOKEN)']`; section detail `missed` |
| report-rules-022 | integrations-error-wins | Cloudflare and stats-store both `configured` false and `error` (test: `an integration in error is a finding even when...`) | Two major findings, `unconfigured` undefined, verdict `degraded` |
| report-rules-023 | runtime-severity, runtime-findings, runtime-overflow | 20 groups of 404, a fatal, a 503 with count 5, a 500 with count 4, total 30 (test: `runtime errors: fatal or a frequent 5xx is major...`) | 16 `vercel-runtime` findings; majors listed first `shop: GET /api/cart → 503` then `shop: edge`; the overflow finding `15 more Vercel runtime error groups not listed` is minor and sorts ahead of the group findings of equal severity (`1` before `s`); section keeps 23 groups; verdict `degraded` |
| report-rules-024 | errors-issue-overflow | 17 active fatal issues (test: `a cap that hides a fatal GlitchTip issue is itself major`) | `2 more active GlitchTip issues not listed` is major |
| report-rules-025 | runtime-overflow | 18 fatal groups, total 18 (test: `a cap that hides a major runtime group is itself major`) | `3 more Vercel runtime error groups not listed` is major |
| report-rules-026 | runtime-updated-at, runtime-notes | Default fixtures; then complete false; then a failing streak 2; then `readAt` null (tests: `runtime errors are dated by the read`, `a cut-short, failing or missing runtime read is a note`) | `updatedAt` is the `readAt`; notes `vercel runtime read was cut short; there may be more groups than listed`, `last 2 vercel runtime reads failed (latest 2026-11-06T11:55:00.000Z); these groups are from the read at 2026-11-06T11:50:00Z`, `vercel runtime errors not read yet` with `updatedAt` null |
| report-rules-027 | runtime-unconfigured, complete-rule | `configured` false (test: `runtime errors with no Vercel token are unconfigured`) | `unconfigured` `['vercel']`, `complete` true |
| report-rules-028 | monitor-never-cycled, verdict-rule | `lastCycleAt` null, not stale (test: `the monitor having never cycled is a note`) | No findings, note `monitor has not completed a probe cycle`, `verdict` `unknown` |
| report-rules-029 | analytics-notes | Vercel analytics `failed` 2 (test: `vercel analytics projects that could not be read are a note`) | Notes `['vercel web analytics: 2 projects could not be read']` |
| report-rules-030 | deploys-log-fields | Logs for a (`tail`, 9 lines) and b (`error`) (test: `failing deploys carry their log tail or why there is none`) | `a` has `logTail ['x','y']` and `logLines` 9 with no `logError`; `b` has `logError` `no build log` |
| report-rules-031 | finding-order, counts-rule | Critical http problem, failed integrations read, Shop at 90% (test: `findings sort by severity, then source, then title`) | Order critical `monitor:http`, major `report`, minor `uptime`; counts 1, 1, 1 |
| report-rules-032 | build-coverage-keys, section-null-rule | Uptime read failed `db` (test: `every source is covered...`) | Coverage keys in the seven-source order; a section is null exactly when its coverage is not ok |
| report-rules-033 | first-line, first-line-width | `firstLine('  \n')`; `firstLine('a\nb')`; a 200-character line | null; `a`; 159 characters plus `…` |
| report-rules-034 | monitor-stale | `stale` true with `lastCycleAt` null | Note `monitor data is stale: no cycle has completed since the loop started` |
| report-rules-035 | deploys-config-degraded | Feed `configDegraded` with no reason | Note `monitor config fell back to the static list: reason unknown` |
| report-rules-036 | uptime-findings | Services at 99.5 (exactly), 99.49 and null uptime | Only the 99.49 service is a finding: `<name>: 99.49% up over <days>d` |
| report-rules-037 | newest-per-target | Two deployments of one target, an older failed and a newer success | `newestPerTarget` returns only the newer one |
| report-rules-038 | finding-shape, monitor-problems | One board problem (`http`, state `down`, name `Shop`, environment `production`) whose `detail`, `since`, `sourceUrl`, `liveUrl` are all empty or null, with no open issue for its target | One finding with exactly the keys `severity`, `source` (`monitor:http`) and `title` (`Shop production: http down`); no `detail`, `since`, `link` or `issueKey` key |
| report-rules-039 | site-troubled, errors-site-findings | Three PostHog sites with 100 requests and 3 errors plus 2 failures (5.00%), 101 requests and 5 errors plus failures (4.95%), and 20 requests and 1 failure (5.00%) | The first and third are troubled and raise findings; the second is not |
| report-rules-040 | errors-issue-findings, errors-issue-overflow | Exactly 15 active GlitchTip issues; then 16 | The first gives 15 `glitchtip` findings and no overflow finding; the second gives 15 plus one minor finding titled `1 more active GlitchTip issues not listed` |
## Edge Cases

- **Null and empty inputs** (MUST): an empty `problems` list, no services, no checks, no groups and null optional fields give empty sections and no findings; `firstLine` returns null for empty text; a missing `detail` leaves the field off the finding.
- **Boundary values** (MUST): uptime exactly 99.5 is not a finding; a runtime 5xx with count 4 is minor and with count 5 is major; a site at exactly 5% failure is troubled; exactly 15 active issues give no overflow finding and 16 do.
- **Zero requests** (MUST): a site with no requests is troubled when its errors plus failures are above 0, and not otherwise.
- **Hidden-group severity** (MUST): when the runtime report's own cap already dropped groups (`total` above the group count), the overflow severity is judged only from the groups present past `RUNTIME_GROUP_CAP`, since the dropped ones sort after every listed one; with none present it is minor.
- **Site cap** (MUST): only the first `SITE_ROW_CAP` rows by trouble are considered for findings, so a troubled site below that cut-off raises no finding, though it stays in the section.
- **Error states** (MUST): a failed source never throws; it becomes a failed coverage entry and a major finding, and the other digests are unaffected.
- **Missing deploys read** (MUST): with the deploys read failed, the monitor digest receives no provider list and keeps every platform-health problem.
- **Missing monitor read** (MUST): with the monitor read failed, the deploys digest lists no failing deploys and a provider finding is minor.
- **Time zone and clock** (MUST): the module reads no clock; `generatedAt` is the supplied `now`, and the only other date it renders is the failing runtime read's `atMs` as an ISO string.
- **Concurrent access**: not applicable; every function is synchronous and pure over its arguments, so there is nothing to interleave.
- **Offline or disconnected state**: not applicable; the module does no I/O. A source that was unreachable arrives as a failed read, which is covered by the failed-source requirement.
- **Duplicate names** (MUST): two open issues with the same name get their targets as keys, so a key never matches two issues.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `now` | `Date` | supplied by the caller | The report's `generatedAt` |
| `monitorVersion` | string or null | supplied by the caller | Echoed into the report |
| `monitor`, `deploys`, `integrations`, `errors`, `runtimeErrors`, `analytics`, `uptime` | `SourceRead` | supplied by the caller | One payload or failure per source |
| `UPTIME_FLOOR` | constant | 99.5 | Uptime percent below which a service is a finding |
| `ERROR_ISSUE_CAP` | constant | 15 | GlitchTip issues listed as findings |
| `RUNTIME_GROUP_CAP` | constant | 15 | Vercel runtime groups listed as findings |
| `SITE_ROW_CAP` | constant | 10 | PostHog sites considered for findings |
| `RUNTIME_5XX_MAJOR_COUNT` | constant | 5 | Count at which a 5xx group is major |
| `FAILURE_RATE_HIGH` | constant in the dashboard views | 0.05 | Failure rate line used by `siteTroubled`, defined in `telemetry/dashboard/views.ts` and pinned by `constants-values` |

## Deep Linking

Not applicable: the module builds no routes or URLs of its own; it passes through the `link` values it is given and builds one `https://<domain>` link for a runtime group.

## Localization

Not applicable: no localization exists in this module. Every note, finding title and detail is a hardcoded English string, and the report carries them as given.

## Accessibility Options

Not applicable: the module has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the module reads no feature flag.

## Analytics

Not applicable: the module sends no analytics event. It summarises analytics dashboard data as report content, which is a different thing.

## Privacy

- **Data collected**: None collected. It passes through commit message first lines, build error text, GlitchTip issue titles, runtime error messages, hostnames and usage totals from its inputs.
- **Storage**: None; the module is pure and keeps nothing.
- **Transmission**: None by this module; the caller returns the report.
- **Retention**: None.

Free text from the sources is cut to a first line but is not redacted.

## Logging

Not applicable: the module has no log call. Failures are returned as coverage entries and findings.

## Platform Notes

- **SwiftUI**: The source is TypeScript. Port each digest as a pure function over `Codable` structs, and `SourceRead<T>` as `Result<T, ReportSourceError>` or an enum with `ok` and `failed` cases. Use `sorted(by:)` with explicit comparators; text comparison must be by UTF-16 code unit to match `byText`, so avoid `localizedCompare`.
- **Compose**: Port as top-level pure Kotlin functions over `@Serializable` data classes, with a sealed interface for `SourceRead`. Use `sortedWith(compareBy ...)` and compare strings with `compareTo`, which is by UTF-16 code unit like the source.
- **React/Web**: The source platform. The file is `src/report/report-rules.ts` in the status-server package, tested by `test/report-rules.test.ts`, with types in `types.ts` beside it. `Array.prototype.sort` is stable. `digestRuntimeErrors` adds an explicit index tie-break, so its ranking does not depend on that, but the sort of low-uptime services by percent has no tie-break and keeps input order for equal percents; use a stable sort in any port.
- **AppKit / UIKit**: Same as SwiftUI; the rules are UI-free and can live in a shared Swift package. Do the build off the main actor if the inputs are large.
- **WinUI 3**: Write the rules as static methods on a `ReportRules` class over C# `record` types, with `SourceRead<T>` as an abstract record with `Ok` and `Failed` subtypes. Use `OrderBy(...).ThenBy(...)` (stable) with `StringComparer.Ordinal` to match the source's code-unit text comparison, `DateTimeOffset.Parse` for `createdAt` ordering, `DateTimeOffset.FromUnixTimeMilliseconds(atMs).ToString("o")` for the failing-read time, and `ToString("F2", CultureInfo.InvariantCulture)` for the uptime percent (JavaScript's `toFixed(2)` is the source's rounding).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/report/report-rules.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The rules module is pure, with `now` as an input and every source passed in as data or a failure.
**Rationale**: Each rule can then be tested with fixtures and no clock, and the reading half can change without touching the judgement.
**Approved**: pending

**Decision**: A missing source, an errored section or a stalled monitor makes `complete` false, but an unconfigured provider does not.
**Rationale**: "No findings" must read as "don't know" when something was not read; a standing fact like a missing credential would otherwise make `complete` permanently false and teach readers to ignore it.
**Approved**: pending

**Decision**: Monitor findings come only from board problems, with the board's own severity, and a service with no problem is counted but never graded here.
**Rationale**: The board holds some services back on purpose (HTTP monitoring off, a degraded probe inside its confirm window, a testing-tier stale deploy kept minor); raising them here would grade them sooner and harder than the board does.
**Approved**: pending

**Decision**: A GlitchTip error is counted once: the board's per-project errors problem is dropped only while the issue list is current (read, no failed refresh, no GlitchTip refresh running, read to the end).
**Rationale**: A cached list from before a new crash would otherwise hide that crash. A PostHog refresh says nothing about the list, so it does not count, or every crash would appear twice.
**Approved**: pending

**Decision**: An unreachable provider is one finding, at the board's severity (else minor), and replaces the board's problem for it.
**Rationale**: The deploys the provider watches are not down, so the report must not invent a worse grade than the board's.
**Approved**: pending

**Decision**: Failing deploys come from the board's `failed` deploy problems, not from the newest row per target in the deploy feed.
**Rationale**: The feed's newest row may be a canceled or queued build, a preview the board ignores, or missing because newer rows pushed the failure out of its window.
**Approved**: pending

**Decision**: A cap that hides items raises its own overflow finding at the severity of the worst hidden item, and major or fatal items are ranked ahead of the cap.
**Rationale**: A cap must never turn a fatal into a minor or hide one. For runtime groups the store may already have dropped groups past its own cap; those sort after every listed one, so they are no worse than the last listed.
**Approved**: pending

**Decision**: A site is troubled at 5% failure (`FAILURE_RATE_HIGH`), and a site with errors but no requests is troubled.
**Rationale**: One aborted request in a month of traffic is not worth a finding, but errors with no requests to weigh them against still count.
**Approved**: pending

**Decision**: `digestAnalytics` raises no findings, only notes and a section; `digestUptime` raises minor findings only.
**Rationale**: Traffic is information, not an incident, and uptime below the floor is worth attention but not degraded status.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

The module is pure and separate from reading, so separation of concerns is met. Every conformance vector has a passing test in `test/report-rules.test.ts`, helper edge cases included (`firstLine` widths, the config-degraded note, the exact uptime floor, `newestPerTarget`), so unit-test coverage is passed. A failed source is returned as data and never thrown, which meets explicit error handling, and the report still builds from the other sources, which meets graceful degradation.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (report-rules.test.ts, 40 of 40 vectors); unit-test coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Removed the transport sentence from the WinUI note, pinned FAILURE_RATE_HIGH 0.05 and its source module in constants-values, linked the gather and wire-types recipes and added the wire-types and dashboard-views recipes to depends-on, fixed the monitor-problems title format, and added vectors 038 to 040 for finding shape and the 5% and 15-issue boundaries. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
