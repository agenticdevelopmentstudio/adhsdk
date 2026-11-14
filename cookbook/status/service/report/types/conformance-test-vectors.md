
The type module has no test of its own; each vector is traced to the producers' tests (`report-rules.test.ts`, `report-gather.test.ts`, `report.int.test.ts`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| report-types-001 | verdict-mapping, complete-rule | Every source read, no notes, no findings | `verdict` `healthy`, `complete` true, `counts` all zero |
| report-types-002 | complete-rule | A provider with no credentials | Listed in that source's `unconfigured`; `complete` stays true |
| report-types-003 | null-section-invariant, verdict-mapping | One source fails to read | Its section is null, `coverage[source].ok` false with `error`, a major finding titled `could not read <source>`, verdict not `healthy` |
| report-types-004 | complete-rule | A dashboard still refreshing at the deadline | A note in that source's coverage, `complete` false |
| report-types-005 | finding-order, verdict-mapping | One critical and one minor finding | Critical listed first, verdict `down` |
| report-types-006 | finding-order | Two minor findings from sources `uptime` and `glitchtip` | `glitchtip` before `uptime` |
| report-types-007 | params-defaults | `parseReportParams({})` | `{ range: '24h', days: 7, wait: 20, logs: false }` |
| report-types-008 | params-ranges | `range=30d&days=14&wait=0&logs=1` | `{ range: '30d', days: 14, wait: 0, logs: true }` |
| report-types-009 | params-rejection | `range=1y` | HTTP 400, `range must be one of 24h, 7d, 30d` |
| report-types-010 | params-rejection | `logs=true` | HTTP 400, `logs must be 0 or 1` |
| report-types-011 | params-rejection | `days=0`, `days=366`, `wait=61`, `days=1.5` | HTTP 400, `days must be an integer 1-365` or `wait must be an integer 0-60` |
| report-types-012 | log-fields | `logs=1` with failing deploys | Each listed failing deploy carries `logTail` (at most 40 lines) and `logLines`; a failed read gives `logError` instead |
| report-types-013 | log-fields | `logs` absent | No `logTail`, `logLines` or `logError` on any deploy |

