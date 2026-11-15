
The `selfCheckView` suite in `packages/web/packages/status-server/test/read-views.test.ts` carries a test for every vector below; each test title begins with its vector id, except the older tests for 001 ("is null when everything is ok"), 003 and 008, 004, 005 and 007, 006, and 009, whose titles name the vector ids they cover.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-self-check-001 | null-when-clean | `selfCheckView([])` | `null` |
| status-server-monitor-self-check-002 | null-when-clean | `selfCheckView([ok("vercel"), ok("railway")])` where both have `state: "ok"` | `null` |
| status-server-monitor-self-check-003 | issue-selection, has-error, issue-count, result-shape | `[ok("vercel"), err("railway")]` where `err` has `state: "error"`, no `missingEnv` | `{ missingEnv: [], missingEnvError: false, issues: [<railway>], hasError: true, issueCount: 1 }` |
| status-server-monitor-self-check-004 | warn-is-issue, has-error | `[warn("posthog")]` with `state: "warn"`, no `missingEnv` | `issues` has one entry, `hasError: false`, `issueCount: 1` |
| status-server-monitor-self-check-005 | missing-env-collection, missing-env-not-an-issue, missing-env-error-flag, severity-follows-state | `[{ id: "cloudflare", state: "warn", missingEnv: ["CLOUDFLARE_ACCOUNT_ID"] }]` | `{ missingEnv: ["CLOUDFLARE_ACCOUNT_ID"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
| status-server-monitor-self-check-006 | missing-env-error-flag, has-error | Same check as 005 but `state: "error"` | `missingEnvError: true`, `hasError: true`, `issues: []`, `issueCount: 1` |
| status-server-monitor-self-check-007 | missing-env-dedupe | `[{ id: "a", state: "warn", missingEnv: ["A", "B"] }, { id: "b", state: "warn", missingEnv: ["B", "C"] }]` | `{ missingEnv: ["A", "B", "C"], missingEnvError: false, issues: [], hasError: false, issueCount: 3 }` |
| status-server-monitor-self-check-008 | cron-excluded | `[{ id: "cron", state: "error" }]` | `null` (the cron check is never an issue) |
| status-server-monitor-self-check-009 | correlated-excluded | `[{ id: "vercel", state: "warn", correlated: true }, { id: "connectivity", state: "warn" }]` | `issues` contains only the `connectivity` check; `issueCount: 1` |
| status-server-monitor-self-check-010 | issue-selection, missing-env-not-an-issue | `[{ id: "x", state: "error", missingEnv: [] }]` (empty array) | The check is an issue (empty `missingEnv` does not exclude it): `issues.length === 1`, `hasError: true` |
| status-server-monitor-self-check-011 | purity, issue-identity | Call with a frozen array `[ok("vercel"), err("railway")]` of frozen checks, where the non-ok check is at index 1 | No throw; `result.issues[0] === input[1]` |
| status-server-monitor-self-check-012 | missing-env-collection, missing-env-error-flag | `[{ id: "stats", state: "ok", missingEnv: ["STATS_TOKEN"] }]` (an ok check that reports a missing variable) | `{ missingEnv: ["STATS_TOKEN"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
| status-server-monitor-self-check-013 | missing-env-collection, correlated-excluded, missing-env-not-an-issue | `[{ id: "vercel", state: "warn", correlated: true, missingEnv: ["VERCEL_API_TOKEN"] }]` | `{ missingEnv: ["VERCEL_API_TOKEN"], missingEnvError: false, issues: [], hasError: false, issueCount: 1 }` |
