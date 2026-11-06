import type { IntegrationCheck, SelfCheckView } from "./types";

/**
 * What the dashboard's self-check bar shows, judged from the integration checks — published
 * on `GET /integrations` as `selfCheck` so the bar and the KPI pill render a verdict instead
 * of each filtering the checks with its own copy of the rule. (Moved here from status-web's
 * `computeSelfCheck`.) Null when there is nothing to show.
 *
 *  - missing env vars are collected (deduped, in check order) and shown in one env chip, so
 *    a check that reports them is not chipped again as an issue;
 *  - the internal "cron" check is wallboard noise and never chipped;
 *  - a `correlated` provider failure is collapsed into the backend's Connectivity chip;
 *  - severity follows the checks' own state: an unset variable is never forced red.
 */
export function selfCheckView(checks: readonly IntegrationCheck[]): SelfCheckView | null {
  const missingEnvChecks = checks.filter((c) => c.missingEnv?.length);
  const missingEnv = [...new Set(missingEnvChecks.flatMap((c) => c.missingEnv!))];
  const missingEnvError = missingEnvChecks.some((c) => c.state === "error");
  const issues = checks.filter((c) => c.state !== "ok" && c.id !== "cron" && !c.missingEnv?.length && !c.correlated);

  if (missingEnv.length === 0 && issues.length === 0) return null;

  const hasError = missingEnvError || issues.some((c) => c.state === "error");
  return { missingEnv, missingEnvError, issues, hasError, issueCount: issues.length + missingEnv.length };
}
