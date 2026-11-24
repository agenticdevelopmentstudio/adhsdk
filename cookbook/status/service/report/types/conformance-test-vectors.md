
The type module is declarations only; every vector is covered by a test in `report-types.test.ts` that drives the producers (`buildReport`, `gatherReport`, `parseReportParams`), and the route-level 400 body is also asserted by `report.int.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| report-types-001 | verdict-mapping, complete-rule | Every source read, no notes, no findings | `verdict` `healthy`, `complete` true, `counts` all zero |
| report-types-002 | complete-rule | A provider with no credentials | Listed in that source's `unconfigured`; `complete` stays true |
| report-types-003 | null-section-invariant, verdict-mapping | One source fails to read | Its section is null, `coverage[source].ok` false with `error`, a major finding titled `could not read <source>`, verdict not `healthy` |
| report-types-004 | complete-rule | A dashboard still refreshing at the deadline | A note in that source's coverage, `complete` false |
| report-types-005 | finding-order, verdict-mapping | One critical and one minor finding | Critical listed first, verdict `down` |
| report-types-006 | finding-order | Two minor findings with `source` `vercel-runtime` and `glitchtip` | `glitchtip` before `vercel-runtime` |
| report-types-007 | params-defaults | `parseReportParams({})` | `{ range: '24h', days: 7, wait: 20, logs: false }` |
| report-types-008 | params-ranges | `range=30d&days=14&wait=0&logs=1` | `{ range: '30d', days: 14, wait: 0, logs: true }` |
| report-types-009 | params-rejection | `range=1y` | HTTP 400, `range must be one of 24h, 7d, 30d` |
| report-types-010 | params-rejection | `logs=true` | HTTP 400, `logs must be 0 or 1` |
| report-types-011 | params-rejection | `days=0`, `days=366`, `wait=61`, `days=1.5` | HTTP 400, `days must be an integer 1-365` or `wait must be an integer 0-60` |
| report-types-012 | log-fields | `logs=1` with failing deploys | Each listed failing deploy carries `logTail` (at most 40 lines) and `logLines`; a failed read gives `logError` instead |
| report-types-013 | log-fields | `logs` absent | No `logTail`, `logLines` or `logError` on any deploy |
| report-types-014 | schema-constant, severity-set, source-set | Any `ReportResponse`, and the exported constants | `schema` is `status.report/1` (`REPORT_SCHEMA`); `SEVERITIES` is `['critical', 'major', 'minor']`; `REPORT_SOURCES` is the seven source ids in the listed order; `coverage` and `sections` each have exactly those keys |
| report-types-015 | verdict-mapping | A report whose only finding is major; then one whose only finding is minor | `verdict` `degraded`; then `verdict` `attention` |
| report-types-016 | counts-total | One critical, two major and three minor findings | `counts` is `{ critical: 1, major: 2, minor: 3 }` |
| report-types-017 | finding-order | Two minor findings with `source` `uptime` and titles `Shop: 90.00% up over 7d` and `API: 97.00% up over 7d` | The `API` finding is listed before the `Shop` finding |
| report-types-018 | first-line-fields | A failing deploy whose commit message is `fix: thing` plus a body line, and whose provider failure text is `Type error` plus a stack line | `commit` is `fix: thing` and `error` is `Type error` |
| report-types-019 | monitor-section | Two services, `Shop` with status `down` and `Blog` with status `unknown`, no completed cycle, no open issues | `services` 2, `byStatus` `{ down: 1, unknown: 1 }`, `openIssues` 0, `lastCycleAt` null, `stale` false, `unprobed` `['Blog']` |
| report-types-020 | deploys-section | Board problems for failed deploys `d1` (09:00) and `d2` (10:00); the Vercel provider configured and ok | `failing` ids are `['d2', 'd1']`; `providers.vercel` is `{ configured: true, ok: true }` |
| report-types-021 | runtime-errors-section | A Vercel read cut short with 30 groups seen and 23 kept, one fatal and the rest level `error` | `window` `24h`, `complete` false, `total` 30, `groups` has 23 entries with the fatal group first |
| report-types-022 | errors-section-order | Active issues: level `error` count 10, level `fatal` count 3, level `error` count 50; sites `a.dev` (3 errors, 2 failures) and `d.dev` (2 errors, 0 failures); issue list never read | `active` counts in order 3, 50, 10; `sites` lists `a.dev` before `d.dev`; `summary` is null |
| report-types-023 | analytics-section | `range` `7d`; PostHog sites with 10 and 30 pageviews; the Vercel read failed | `range` `7d`; the 30-pageview site is listed first; `vercel.totals` is null |
| report-types-024 | uptime-section | `days` 7; one service at 97.5% and one with no figure | `days` 7, `floor` 99.5, the first `uptimePercent` 97.5, the second null |
| report-types-025 | params-defaults | `parseReportParams({ days: '' })` | `days` is 7 (an empty string is absent) |
