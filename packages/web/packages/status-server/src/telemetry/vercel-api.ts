import { noteRateLimited, rateLimitedUntil } from "@adh-sdk/deploy-platform/cooldown";

// The Vercel REST client the telemetry readers share: Web Analytics (dashboard/vercel-section.ts)
// and runtime logs (fetchers/vercel-runtime.ts). It uses the token the deploy poll uses, so it
// shares that token's quota and honors the shared 429 cooldown.

export const VERCEL_API = "https://api.vercel.com";
const CALL_TIMEOUT_MS = 20_000;
const MAX_PROJECT_PAGES = 20;

export interface VercelEnv {
  VERCEL_API_TOKEN?: string;
  VERCEL_TEAM_ID?: string;
}

export interface ListedProject {
  id?: string;
  name?: string;
  webAnalytics?: { enabledAt?: number | null; disabledAt?: number | null } | null;
  targets?: { production?: { id?: string | null; alias?: string[] | null } | null } | null;
}

/** Vercel is cooling down after a 429. Ends a whole read: every further call would 429 too. */
export class VercelRateLimited extends Error {}

/**
 * One Vercel call, answered with the raw response so a caller can stream its body.
 *
 * Every call checks the shared cooldown first, not just a load's first call. Several workers run
 * at once, so after one 429 the rest would otherwise keep firing at a throttled API, and each of
 * their 429s pushes the cooldown, which the deploy poll also honors, further out.
 *
 * `signal` adds to the per-call timeout; it does not replace it. `init` makes it a POST of a JSON
 * body, with any extra headers.
 */
export async function vercelRequest(
  env: VercelEnv,
  path: string,
  params: Record<string, string>,
  signal?: AbortSignal,
  init: { json?: unknown; headers?: Record<string, string> } = {},
): Promise<Response> {
  const cooling = rateLimitedUntil("vercel");
  if (cooling) throw new VercelRateLimited(`Vercel rate limited until ${new Date(cooling).toISOString()}`);
  const url = new URL(path, VERCEL_API);
  if (env.VERCEL_TEAM_ID) url.searchParams.set("teamId", env.VERCEL_TEAM_ID);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const timeout = AbortSignal.timeout(CALL_TIMEOUT_MS);
  const post = init.json !== undefined;
  const res = await fetch(url, {
    method: post ? "POST" : "GET",
    headers: {
      Authorization: `Bearer ${env.VERCEL_API_TOKEN}`,
      ...(post ? { "Content-Type": "application/json" } : {}),
      ...init.headers,
    },
    ...(post ? { body: JSON.stringify(init.json) } : {}),
    signal: signal ? AbortSignal.any([timeout, signal]) : timeout,
  });
  if (res.status === 429) {
    noteRateLimited("vercel", res.headers.get("retry-after"));
    throw new VercelRateLimited("Vercel rate limited");
  }
  if (!res.ok) throw new VercelHttpError(path, res.status, await res.text().catch(() => ""));
  return res;
}

/** A Vercel call that answered with an error status other than 429. */
export class VercelHttpError extends Error {
  constructor(
    readonly path: string,
    readonly status: number,
    readonly body: string,
  ) {
    super(`Vercel ${path} HTTP ${status}`);
  }
}

/** {@link vercelRequest}, parsed as JSON. */
export async function vercelGet(
  env: VercelEnv,
  path: string,
  params: Record<string, string>,
  signal?: AbortSignal,
): Promise<unknown> {
  return (await vercelRequest(env, path, params, signal)).json();
}

/** Every project the token can see, walking the pages. */
export async function listProjects(env: VercelEnv, signal?: AbortSignal): Promise<ListedProject[]> {
  const out: ListedProject[] = [];
  let until: string | undefined;
  for (let page = 0; page < MAX_PROJECT_PAGES; page++) {
    const body = (await vercelGet(env, "/v9/projects", { limit: "100", ...(until ? { until } : {}) }, signal)) as {
      projects?: ListedProject[];
      pagination?: { next?: number | null };
    };
    out.push(...(body.projects ?? []));
    if (!body.pagination?.next) break;
    until = String(body.pagination.next);
  }
  return out;
}

/**
 * The first production alias that a person would call the site's domain. These belong to the latest
 * production deployment, so a queued deployment leaves only `*.vercel.app` here. That makes this a
 * cheap first filter and a fallback, not the answer: `loadVercelTraffic` asks the domains API.
 */
export function productionDomain(p: ListedProject): string | null {
  return p.targets?.production?.alias?.find((a) => !a.endsWith(".vercel.app")) ?? null;
}

/**
 * Every site is three Vercel projects, `x-production`, `x-staging` and `x-testing`, and analytics
 * only runs on the first. The other two are not sites to report on, so they are dropped before
 * anything is counted or queried.
 *
 * It has to be the end of the name: `testing-production` is the production site of a site about
 * testing.
 */
export function isProductionProject(p: ListedProject): boolean {
  return !/-(staging|testing)$/i.test(p.name ?? "") && !isNonProductionHost(productionDomain(p));
}

export function isNonProductionHost(domain: string | null): boolean {
  return /^(staging|testing)\./i.test(domain ?? "");
}
