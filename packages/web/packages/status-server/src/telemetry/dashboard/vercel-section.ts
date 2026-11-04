import { noteRateLimited, rateLimitedUntil } from "@adh-sdk/deploy-platform/cooldown";
import { mapLimit } from "@adh-sdk/deploy-platform/util";
import { alignToBuckets, type RangeWindow } from "./ranges";
import type { Marginal, VercelProjectTraffic, VercelTrafficSection } from "./types";

// Vercel Web Analytics, read through the REST API with the same token the deploy poll uses, so
// it shares that token's quota and honors the shared 429 cooldown.
//
//   https://vercel.com/docs/analytics/web-analytics-api
//
// The API is per project and production-only. Counts run for every project with analytics on,
// and the costlier breakdowns only for projects that had traffic: most have none.

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

async function vercelGet(env: VercelEnv, path: string, params: Record<string, string>): Promise<unknown> {
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

/** The first production alias that a person would call the site's domain. */
export function productionDomain(p: ListedProject): string | null {
  return p.targets?.production?.alias?.find((a) => !a.endsWith(".vercel.app")) ?? null;
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

/** One `by=country`-style response. The row's dimension value sits under the `by` name. */
export function shapeMarginal(rows: Record<string, unknown>[], by: string): Marginal[] {
  return rows
    .map((r) => ({
      name: typeof r[by] === "string" && r[by] !== "" ? (r[by] as string) : "(none)",
      pageviews: Number(r.pageviews) || 0,
    }))
    .sort((a, b) => b.pageviews - a.pageviews);
}

export async function loadVercelTraffic(env: VercelEnv, w: RangeWindow): Promise<VercelTrafficSection> {
  const cooling = rateLimitedUntil("vercel");
  if (cooling) throw new Error(`Vercel rate limited until ${new Date(cooling).toISOString()}`);

  const listed = await listProjects(env);
  const enabled = listed.filter((p): p is ListedProject & { id: string; name: string } =>
    Boolean(p.id && p.name && analyticsEnabled(p)),
  );

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
    if (all.some((r) => r.status === "rejected")) failed++;
    const ok = (r: PromiseSettledResult<Record<string, unknown>[]>): Record<string, unknown>[] =>
      r.status === "fulfilled" ? r.value : [];
    const seriesRows = ok(series);
    const traffic: VercelProjectTraffic = {
      project: p.name,
      domain: productionDomain(p),
      pageviews,
      visitors,
      series: alignToBuckets(w.buckets, seriesRows.map((r): [unknown, number] => [r.timestamp, Number(r.pageviews) || 0])),
      countries: shapeMarginal(ok(countries), "country"),
      referrers: shapeMarginal(ok(referrers), "referrerHostname"),
      paths: shapeMarginal(ok(paths), "requestPath"),
      devices: shapeMarginal(ok(devices), "deviceType"),
    };
    return { traffic, seriesRows };
  });

  const sumOver = (field: "pageviews" | "visitors"): number[] =>
    alignToBuckets(
      w.buckets,
      projects.flatMap(({ seriesRows }) => seriesRows.map((r): [unknown, number] => [r.timestamp, Number(r[field]) || 0])),
    );

  return {
    buckets: w.buckets,
    projectsTotal: listed.length,
    projectsEnabled: enabled.length,
    failed,
    totals: {
      pageviews: withTraffic.reduce((a, c) => a + c.pageviews, 0),
      visitors: withTraffic.reduce((a, c) => a + c.visitors, 0),
    },
    pageviews: sumOver("pageviews"),
    visitors: sumOver("visitors"),
    projects: projects.map((p) => p.traffic).sort((a, b) => b.pageviews - a.pageviews),
  };
}
