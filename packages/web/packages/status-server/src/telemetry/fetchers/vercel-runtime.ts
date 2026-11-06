import { mapLimit } from "@adh-sdk/deploy-platform/util";
import type { Fetcher, FetchResult } from "../ports";
import { toRuntimeEntry, readJsonLines, type RawRuntimeLog } from "../runtime-errors";
import type { RuntimeLogEntry } from "../types";
import {
  isProductionProject,
  listProjects,
  productionDomain,
  VercelRateLimited,
  vercelGet,
  vercelRequest,
  type ListedProject,
  type VercelEnv,
} from "../vercel-api";

// Vercel runtime logs, for the errors a site's server side throws and the browser never sees
// (GlitchTip only hears from the browser). For every production project it reads the runtime-logs
// stream of the CURRENT production deployment and keeps error/fatal lines and 5xx responses.
//
//   GET /v1/projects/{projectId}/deployments/{deploymentId}/runtime-logs
//
// The answer is `application/stream+json`, one object per line, with no server-side filter, and
// it can stay open to follow new lines. So each deployment gets a time budget and is then cut
// off, inside an overall budget for the whole read. Hitting a budget is the normal end, not a
// failure. PURE w.r.t. storage: the store counts each line once, however often it is re-read.

export interface VercelRuntimeOptions {
  /** How long one deployment's stream is read. */
  deploymentBudgetMs?: number;
  /** How long the whole read may take. */
  overallBudgetMs?: number;
  concurrency?: number;
}

const DEPLOYMENT_BUDGET_MS = 8_000;
const OVERALL_BUDGET_MS = 45_000;
const CONCURRENCY = 4;

type Project = ListedProject & { id: string; name: string };

/** The project's current production deployment: from the project, else its newest READY one. */
async function productionDeploymentId(env: VercelEnv, p: Project): Promise<string | null> {
  const listed = p.targets?.production?.id;
  if (listed) return listed;
  const body = (await vercelGet(env, "/v6/deployments", {
    projectId: p.id,
    target: "production",
    state: "READY",
    limit: "1",
  })) as { deployments?: { uid?: string }[] };
  return body.deployments?.[0]?.uid ?? null;
}

/** One deployment's kept lines, read until its stream ends or a budget runs out. */
async function readDeployment(
  env: VercelEnv,
  p: Project,
  deploymentId: string,
  budgetMs: number,
  overall: AbortSignal,
): Promise<RuntimeLogEntry[]> {
  const budget = AbortSignal.any([AbortSignal.timeout(budgetMs), overall]);
  const res = await vercelRequest(
    env,
    `/v1/projects/${encodeURIComponent(p.id)}/deployments/${encodeURIComponent(deploymentId)}/runtime-logs`,
    {},
    budget,
  );
  if (!res.body) return [];
  const at = { project: p.name, deploymentId, domain: productionDomain(p) };
  const out: RuntimeLogEntry[] = [];
  await readJsonLines(res.body, budget, (value) => {
    if (!value || typeof value !== "object") return;
    const entry = toRuntimeEntry(value as RawRuntimeLog, at);
    if (entry) out.push(entry);
  });
  return out;
}

const isAbort = (err: unknown): boolean =>
  err instanceof Error && (err.name === "AbortError" || err.name === "TimeoutError");

export function vercelRuntimeFetcher(env: VercelEnv, opts: VercelRuntimeOptions = {}): Fetcher<RuntimeLogEntry> {
  const deploymentBudgetMs = opts.deploymentBudgetMs ?? DEPLOYMENT_BUDGET_MS;
  const overallBudgetMs = opts.overallBudgetMs ?? OVERALL_BUDGET_MS;
  const concurrency = opts.concurrency ?? CONCURRENCY;
  return {
    async fetch(): Promise<FetchResult<RuntimeLogEntry>> {
      if (!env.VERCEL_API_TOKEN) return { ok: true, items: [] };
      const overall = AbortSignal.timeout(overallBudgetMs);
      try {
        const projects = (await listProjects(env)).filter((p): p is Project =>
          Boolean(p.id && p.name && isProductionProject(p)),
        );
        let failed = 0;
        // Set inside the workers; the cast keeps TS from narrowing it to `null` out here.
        let limited = null as VercelRateLimited | null;
        const read = await mapLimit(projects, concurrency, async (p) => {
          // Out of overall budget, or throttled: the rest are not asked, which is not a failure
          // of theirs.
          if (overall.aborted || limited) return [];
          try {
            const deploymentId = await productionDeploymentId(env, p);
            if (!deploymentId) return [];
            return await readDeployment(env, p, deploymentId, deploymentBudgetMs, overall);
          } catch (err) {
            if (err instanceof VercelRateLimited) {
              limited = err;
              return [];
            }
            // A budget that ran out before the stream even answered.
            if (isAbort(err)) return [];
            failed++;
            console.error(`[telemetry] Vercel runtime logs for ${p.name} failed`, err);
            return [];
          }
        });
        if (limited) throw limited;
        if (projects.length > 0 && failed === projects.length) {
          return { ok: false, items: [] };
        }
        return { ok: true, items: read.flat(), complete: failed === 0 };
      } catch (err) {
        console.error("[telemetry] Vercel runtime logs read failed", err);
        return { ok: false, items: [] };
      }
    },
  };
}
