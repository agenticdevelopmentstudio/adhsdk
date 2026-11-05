import { noteRateLimited, rateLimitedUntil } from "@adh-sdk/deploy-platform/cooldown";
import { fetchProjectPrimaryDomain } from "@adh-sdk/deploy-platform/providers";
import { mapLimit } from "@adh-sdk/deploy-platform/util";
import { alignToBuckets, type RangeWindow } from "./ranges";
import type { Marginal, VercelProjectTraffic, VercelRosterEntry, VercelTrafficSection } from "./types";

// Vercel Web Analytics, read through the REST API with the same token the deploy poll uses, so
// it shares that token's quota and honors the shared 429 cooldown.
//
//   https://vercel.com/docs/analytics/web-analytics-api
//
// The API is per project, and only production projects are read at all. Counts run for every
// one with analytics on, and the costlier breakdowns only for those that had traffic: most have
// none.

const API = "https://api.vercel.com";
const CALL_TIMEOUT_MS = 20_000;
const CONCURRENCY = 6;
const MAX_PROJECT_PAGES = 20;
/** The API's maximum. It defaults to 10, which would cut a 30-day series short. */
const AGGREGATE_LIMIT = "100";

export interface VercelEnv {
  VERCEL_API_TOKEN?: string;
  VERCEL_TEAM_ID?: string;
}

interface ListedProject {
  id?: string;
  name?: string;
  webAnalytics?: { enabledAt?: number | null; disabledAt?: number | null } | null;
  targets?: { production?: { alias?: string[] | null } | null } | null;
}

class VercelRateLimited extends Error {}

/**
 * Every call checks the shared cooldown first, not just the load's first call. Up to CONCURRENCY
 * workers run at once, so after one 429 the rest would otherwise keep firing at a throttled API,
 * and each of their 429s pushes the cooldown, which the deploy poll also honors, further out.
 */
async function vercelGet(env: VercelEnv, path: string, params: Record<string, string>): Promise<unknown> {
  const cooling = rateLimitedUntil("vercel");
  if (cooling) throw new VercelRateLimited(`Vercel rate limited until ${new Date(cooling).toISOString()}`);
  const url = new URL(path, API);
  if (env.VERCEL_TEAM_ID) url.searchParams.set("teamId", env.VERCEL_TEAM_ID);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${env.VERCEL_API_TOKEN}` },
    signal: AbortSignal.timeout(CALL_TIMEOUT_MS),
  });
  if (res.status === 429) {
    noteRateLimited("vercel", res.headers.get("retry-after"));
    throw new VercelRateLimited("Vercel rate limited");
  }
  if (!res.ok) throw new Error(`Vercel ${path} HTTP ${res.status}`);
  return res.json();
}

async function listProjects(env: VercelEnv): Promise<ListedProject[]> {
  const out: ListedProject[] = [];
  let until: string | undefined;
  for (let page = 0; page < MAX_PROJECT_PAGES; page++) {
    const body = (await vercelGet(env, "/v9/projects", { limit: "100", ...(until ? { until } : {}) })) as {
      projects?: ListedProject[];
      pagination?: { next?: number | null };
    };
    out.push(...(body.projects ?? []));
    if (!body.pagination?.next) break;
    until = String(body.pagination.next);
  }
  return out;
}

export function analyticsEnabled(p: ListedProject): boolean {
  return Boolean(p.webAnalytics?.enabledAt) && !p.webAnalytics?.disabledAt;
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

function isNonProductionHost(domain: string | null): boolean {
  return /^(staging|testing)\./i.test(domain ?? "");
}

/** The API takes dates for whole days. Hourly needs instants or it can't tell the hours apart. */
function windowParams(w: RangeWindow): Record<string, string> {
  if (w.unit === "hour") return { since: w.since.toISOString(), until: w.until.toISOString() };
  return { since: w.since.toISOString().slice(0, 10), until: w.until.toISOString().slice(0, 10) };
}

async function aggregate(
  env: VercelEnv,
  projectId: string,
  by: string,
  w: RangeWindow,
): Promise<Record<string, unknown>[]> {
  const body = (await vercelGet(env, "/v1/query/web-analytics/visits/aggregate", {
    projectId,
    by,
    limit: AGGREGATE_LIMIT,
    ...windowParams(w),
  })) as { data?: Record<string, unknown>[] };
  return body.data ?? [];
}

/**
 * One `by=country`-style response. The row's dimension value sits under the `by` name. Past its
 * limit Vercel folds the rest into a row named "Others", which is not a page or a country and
 * cannot be summed across projects as if it were the same thing, so it is left out of a top list.
 */
export function shapeMarginal(rows: Record<string, unknown>[], by: string): Marginal[] {
  return rows
    .filter((r) => r[by] !== "Others")
    .map((r) => ({
      name: typeof r[by] === "string" && r[by] !== "" ? (r[by] as string) : "(none)",
      pageviews: Number(r.pageviews) || 0,
    }))
    .sort((a, b) => b.pageviews - a.pageviews);
}

export async function loadVercelTraffic(env: VercelEnv, w: RangeWindow): Promise<VercelTrafficSection> {
  const candidates = (await listProjects(env)).filter(
    (p): p is ListedProject & { id: string; name: string } => Boolean(p.id && p.name && isProductionProject(p)),
  );
  const domains = new Map(
    await mapLimit(candidates, CONCURRENCY, async (p) => {
      const domain = await fetchProjectPrimaryDomain(env.VERCEL_API_TOKEN ?? "", env.VERCEL_TEAM_ID, p.name);
      return [p.id, domain ?? productionDomain(p)] as const;
    }),
  );
  const domainOf = (p: { id: string }): string | null => domains.get(p.id) ?? null;
  const listed = candidates.filter((p) => !isNonProductionHost(domainOf(p)));
  const enabled = listed.filter(analyticsEnabled);

  let failed = 0;
  const counts = await mapLimit(enabled, CONCURRENCY, async (p) => {
    try {
      const body = (await vercelGet(env, "/v1/query/web-analytics/visits/count", {
        projectId: p.id,
        ...windowParams(w),
      })) as { data?: { pageviews?: number; visitors?: number } };
      return { p, pageviews: body.data?.pageviews ?? 0, visitors: body.data?.visitors ?? 0 };
    } catch (err) {
      if (err instanceof VercelRateLimited) throw err;
      failed++;
      return null;
    }
  });
  if (enabled.length > 0 && failed === enabled.length) throw new Error("every Vercel analytics call failed");

  let incomplete = 0;
  const withTraffic = counts.flatMap((c) => (c && c.pageviews > 0 ? [c] : []));
  const projects = await mapLimit(withTraffic, CONCURRENCY, async ({ p, pageviews, visitors }) => {
    const [series, countries, referrers, paths, devices] = await Promise.allSettled([
      aggregate(env, p.id, w.unit, w),
      aggregate(env, p.id, "country", w),
      aggregate(env, p.id, "referrerHostname", w),
      aggregate(env, p.id, "requestPath", w),
      aggregate(env, p.id, "deviceType", w),
    ]);
    const all = [series, countries, referrers, paths, devices];
    // A 429 ends the load, as it does in the counts phase; allSettled would otherwise hide it.
    const limited = all.find((r) => r.status === "rejected" && r.reason instanceof VercelRateLimited);
    if (limited?.status === "rejected") throw limited.reason;
    // Not `failed`: this project's count is in the totals. What is short is its series and lists.
    const short = all.some((r) => r.status === "rejected");
    if (short) incomplete++;
    const ok = (r: PromiseSettledResult<Record<string, unknown>[]>): Record<string, unknown>[] =>
      r.status === "fulfilled" ? r.value : [];
    const seriesRows = ok(series);
    const traffic: VercelProjectTraffic = {
      project: p.name,
      domain: domainOf(p),
      pageviews,
      visitors,
      series: alignToBuckets(w.buckets, seriesRows.map((r): [unknown, number] => [r.timestamp, Number(r.pageviews) || 0])),
      countries: shapeMarginal(ok(countries), "country"),
      referrers: shapeMarginal(ok(referrers), "referrerHostname"),
      paths: shapeMarginal(ok(paths), "requestPath"),
      devices: shapeMarginal(ok(devices), "deviceType"),
      incomplete: short,
    };
    return { traffic, seriesRows };
  });

  const sumOver = (field: "pageviews" | "visitors"): number[] =>
    alignToBuckets(
      w.buckets,
      projects.flatMap(({ seriesRows }) => seriesRows.map((r): [unknown, number] => [r.timestamp, Number(r[field]) || 0])),
    );

  const countOf = new Map(counts.flatMap((c) => (c ? [[c.p.id, c] as const] : [])));
  const roster = listed
    .map((p): VercelRosterEntry => {
      const c = countOf.get(p.id);
      return {
        project: p.name,
        domain: domainOf(p),
        analyticsOn: analyticsEnabled(p),
        pageviews: c?.pageviews ?? null,
        visitors: c?.visitors ?? null,
      };
    })
    .sort((a, b) => (b.pageviews ?? -1) - (a.pageviews ?? -1) || a.project.localeCompare(b.project));

  return {
    buckets: w.buckets,
    projectsTotal: listed.length,
    projectsEnabled: enabled.length,
    failed,
    incomplete,
    roster,
    totals: {
      pageviews: withTraffic.reduce((a, c) => a + c.pageviews, 0),
      visitors: withTraffic.reduce((a, c) => a + c.visitors, 0),
    },
    pageviews: sumOver("pageviews"),
    visitors: sumOver("visitors"),
    projects: projects.map((p) => p.traffic).sort((a, b) => b.pageviews - a.pageviews),
  };
}
