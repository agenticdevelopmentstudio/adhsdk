
The `selfCheckView` suite in `packages/web/packages/status-server/test/read-views.test.ts` covers vectors 001 (test "is null when everything is ok"), 005 and 007 (test "surfaces missing env (deduped) as a non-error warning"), 006 (test "an error-severity missing env goes red and counts as an error"), 003 and 008 (test "keeps reachability issues as chips but excludes the internal cron check"), 009 (test "collapses correlated provider failures into the Connectivity chip only") and 004 (test "a warning alone is not a red error"). The remaining vectors are traced directly to the function body.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-self-check-001 | null-when-clean | `selfCheckView([])` | `null` |
| status-server-monitor-self-check-002 | null-when-clean | `selfCheckView([ok("vercel"), ok("railway")])` where both have `state: "ok"` | `null` |
| status-server-monitor-self-check-003 | issue-selection, has-error, issue-count, result-shape | `[ok("vercel"), err("railway")]` where `err` has `state: "error"`, no `missingEnv` | `{ missingEnv: [], missingEnvError: false, issues: [<railway>], hasError: true, issueCount: 1 }` |
| status-server-monitor-self-check-004 | warn-is-issue, has-error | `[warn("posthog")]` with `state: "warn"`, no `missingEnv` | `issues` has one entry, `hasError: false`, `issueCount: 1` |
| status-server-monitor-self-check-005 | missing-env-collection, missing-env-not-an-issue, missing-env-error-flag, severity-follows-state | `[{ id: "cloudflare", state: "warn", missingEnv: ["CLOUDFLARE_ACCOUNT_ID"] }]` | `{ missingEnv: ["CLOUDFLARE_ACCOUNT_ID"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
| status-server-monitor-self-check-006 | missing-env-error-flag, has-error | Same check as 005 but `state: "error"` | `missingEnvError: true`, `hasError: true`, `issues: []`, `issueCount: 1` |
| status-server-monitor-self-check-007 | missing-env-dedupe | Two checks with `missingEnv: ["A", "B"]` and `missingEnv: ["B", "C"]` | `missingEnv` is `["A", "B", "C"]`; `issueCount` is `3` |
| status-server-monitor-self-check-008 | cron-excluded | `[{ id: "cron", state: "error" }]` | `null` (the cron check is never an issue) |
| status-server-monitor-self-check-009 | correlated-excluded | `[{ id: "vercel", state: "warn", correlated: true }, { id: "connectivity", state: "warn" }]` | `issues` contains only the `connectivity` check; `issueCount: 1` |
| status-server-monitor-self-check-010 | issue-selection, missing-env-not-an-issue | `[{ id: "x", state: "error", missingEnv: [] }]` (empty array) | The check is an issue (empty `missingEnv` does not exclude it): `issues.length === 1`, `hasError: true` |
| status-server-monitor-self-check-011 | purity, issue-identity | Call with a frozen array of frozen checks, one non-ok | No throw; `result.issues[0] === input[i]` |

