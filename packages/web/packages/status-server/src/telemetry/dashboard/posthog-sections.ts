import { hogqlRows, toMetricValue, type PosthogEnv } from "../fetchers/posthog";
import { alignToBuckets, type RangeWindow } from "./ranges";
import type {
  DimensionsSection,
  PathRow,
  SiteErrorDays,
  SiteErrorDetailSection,
  SiteErrorRow,
  SiteFailedRequestRow,
  SiteHealthRow,
  TrafficSection,
  VitalsRow,
} from "./types";

// The PostHog half of the dashboards: one HogQL query per section, each with a pure shaper.
//
// Every value interpolated into a query below comes from a closed enum or a Date, never from a
// request string. Queries select named properties only: `SELECT properties` is what times out.

const QUERY_TIMEOUT_MS = 45_000;
const TRAFFIC_ROW_LIMIT = 5_000;
const DIMENSION_ROW_LIMIT = 5_000;
const PATH_ROW_LIMIT = 5_000;
const SITE_ROW_LIMIT = 200;
const ERROR_DETAIL_ROW_LIMIT = 5_000;

const HOST = "properties.$host";

// Only production sites report analytics; the host filters keep out a stray local or preview hit.
const PRODUCTION_HOSTS = `${HOST} NOT LIKE 'testing.%' AND ${HOST} NOT LIKE 'staging.%' AND ${HOST} NOT LIKE '%localhost%' AND ${HOST} NOT LIKE '%127.0.0.1%' AND ${HOST} NOT LIKE '%.vercel.app'`;

function since(w: RangeWindow): string {
  const at = w.since.toISOString().slice(0, 19).replace("T", " ");
  return `timestamp >= toDateTime('${at}')`;
}

const count = (v: unknown): number => toMetricValue(v) ?? 0;
const label = (v: unknown, fallback: string): string => (typeof v === "string" && v !== "" ? v : fallback);

async function rows(env: PosthogEnv, query: string): Promise<unknown[][]> {
  const r = await hogqlRows(env, query, QUERY_TIMEOUT_MS);
  if (!r.ok) throw new Error(`PostHog: ${r.error}`);
  return r.rows;
}

// ── traffic ────────────────────────────────────────────────────────────────

/** Rows are [host, bucket, pageviews, sessions]. */
export function shapeTraffic(raw: unknown[][], buckets: string[]): TrafficSection {
  const byHost = new Map<string, unknown[][]>();
  for (const row of raw) {
    const host = label(row[0], "(unknown)");
    byHost.set(host, [...(byHost.get(host) ?? []), row]);
  }
  const sites = [...byHost.entries()]
    .map(([host, hostRows]) => {
      const series = alignToBuckets(buckets, hostRows.map((r): [unknown, number] => [r[1], count(r[2])]));
      const sessions = alignToBuckets(buckets, hostRows.map((r): [unknown, number] => [r[1], count(r[3])]));
      return {
        host,
        series,
        pageviews: series.reduce((a, b) => a + b, 0),
        sessions: sessions.reduce((a, b) => a + b, 0),
      };
    })
    .sort((a, b) => b.pageviews - a.pageviews || a.host.localeCompare(b.host));
  const pageviews = alignToBuckets(buckets, raw.map((r): [unknown, number] => [r[1], count(r[2])]));
  const sessions = alignToBuckets(buckets, raw.map((r): [unknown, number] => [r[1], count(r[3])]));
  return {
    buckets,
    totals: { pageviews: pageviews.reduce((a, b) => a + b, 0), sessions: sessions.reduce((a, b) => a + b, 0) },
    pageviews,
    sessions,
    sites,
  };
}

export async function loadTraffic(env: PosthogEnv, w: RangeWindow): Promise<TrafficSection> {
  const bucket = w.unit === "hour" ? "toStartOfHour(timestamp)" : "toStartOfDay(timestamp)";
  const raw = await rows(
    env,
    `SELECT ${HOST}, ${bucket}, count(), uniq(properties.$session_id) FROM events ` +
      `WHERE event = '$pageview' AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1, 2 ORDER BY 2 LIMIT ${TRAFFIC_ROW_LIMIT}`,
  );
  return shapeTraffic(raw, w.buckets);
}

// ── dimensions ─────────────────────────────────────────────────────────────

/** Rows are [host, device, browser, country, referrer, pageviews]. */
export function shapeDimensions(raw: unknown[][], limit: number = DIMENSION_ROW_LIMIT): DimensionsSection {
  return {
    rows: raw.map((r) => ({
      host: label(r[0], "(unknown)"),
      device: label(r[1], "Unknown"),
      browser: label(r[2], "Unknown"),
      country: label(r[3], "Unknown"),
      referrer: label(r[4], "$direct"),
      pageviews: count(r[5]),
    })),
    truncated: raw.length >= limit,
  };
}

export async function loadDimensions(env: PosthogEnv, w: RangeWindow): Promise<DimensionsSection> {
  const raw = await rows(
    env,
    `SELECT ${HOST}, properties.$device_type, properties.$browser, properties.$geoip_country_code, properties.$referring_domain, count() ` +
      `FROM events WHERE event = '$pageview' AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1, 2, 3, 4, 5 ORDER BY 6 DESC LIMIT ${DIMENSION_ROW_LIMIT}`,
  );
  return shapeDimensions(raw);
}

// ── paths ──────────────────────────────────────────────────────────────────

export async function loadPaths(env: PosthogEnv, w: RangeWindow): Promise<PathRow[]> {
  const raw = await rows(
    env,
    `SELECT ${HOST}, properties.$pathname, count() FROM events ` +
      `WHERE event = '$pageview' AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1, 2 ORDER BY 3 DESC LIMIT ${PATH_ROW_LIMIT}`,
  );
  return raw.map((r) => ({ host: label(r[0], "(unknown)"), path: label(r[1], "/"), pageviews: count(r[2]) }));
}

// ── vitals ─────────────────────────────────────────────────────────────────

/** Rows are [host, samples, lcp, inp, cls, fcp], each vital at p75. */
export function shapeVitals(raw: unknown[][]): VitalsRow[] {
  return raw.map((r) => ({
    host: label(r[0], "(unknown)"),
    samples: count(r[1]),
    lcp: toMetricValue(r[2]),
    inp: toMetricValue(r[3]),
    cls: toMetricValue(r[4]),
    fcp: toMetricValue(r[5]),
  }));
}

export async function loadVitals(env: PosthogEnv, w: RangeWindow): Promise<VitalsRow[]> {
  const p75 = (name: string): string => `quantile(0.75)(toFloat(properties.$web_vitals_${name}_value))`;
  const raw = await rows(
    env,
    `SELECT ${HOST}, count(), ${p75("LCP")}, ${p75("INP")}, ${p75("CLS")}, ${p75("FCP")} FROM events ` +
      `WHERE event = '$web_vitals' AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1 ORDER BY 2 DESC LIMIT ${SITE_ROW_LIMIT}`,
  );
  return shapeVitals(raw);
}

// ── per-site health ────────────────────────────────────────────────────────

/** Rows are [host, errors, requests, failures, p95Ms]. */
export function shapeHealth(raw: unknown[][]): SiteHealthRow[] {
  return raw.map((r) => ({
    host: label(r[0], "(unknown)"),
    errors: count(r[1]),
    requests: count(r[2]),
    failures: count(r[3]),
    p95Ms: toMetricValue(r[4]),
  }));
}

/**
 * The only per-site error signal there is: GlitchTip's events are pruned, so its issues cannot
 * be attributed to a site. A status of 0 means the request never got a response.
 */
export async function loadSiteHealth(env: PosthogEnv, w: RangeWindow): Promise<SiteHealthRow[]> {
  const isRequest = "event = 'http_request'";
  const status = "toFloat(properties.status)";
  const raw = await rows(
    env,
    `SELECT ${HOST}, countIf(event = 'error_reported'), countIf(${isRequest}), ` +
      `countIf(${isRequest} AND (${status} >= 500 OR ${status} = 0)), ` +
      `quantileIf(0.95)(toFloat(properties.duration_ms), ${isRequest}) FROM events ` +
      `WHERE event IN ('error_reported', 'http_request') AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1 ORDER BY 3 DESC LIMIT ${SITE_ROW_LIMIT}`,
  );
  return shapeHealth(raw);
}

// ── one site's errors and failed requests ─────────────────────────────────

const optional = (v: unknown): string | null => (typeof v === "string" && v !== "" ? v : null);

/** Rows are [host, bucket, errors, failures]. */
export function shapeErrorDays(raw: unknown[][], buckets: string[]): SiteErrorDays[] {
  const byHost = new Map<string, unknown[][]>();
  for (const row of raw) {
    const host = label(row[0], "(unknown)");
    byHost.set(host, [...(byHost.get(host) ?? []), row]);
  }
  return [...byHost.entries()].map(([host, hostRows]) => ({
    host,
    errors: alignToBuckets(buckets, hostRows.map((r): [unknown, number] => [r[1], count(r[2])])),
    failures: alignToBuckets(buckets, hostRows.map((r): [unknown, number] => [r[1], count(r[3])])),
  }));
}

/** Rows are [host, name, feature, step, boundary, page, count, lastSeen]. */
export function shapeSiteErrors(raw: unknown[][]): SiteErrorRow[] {
  return raw.map((r) => ({
    host: label(r[0], "(unknown)"),
    name: label(r[1], "(unnamed)"),
    feature: optional(r[2]),
    step: optional(r[3]),
    boundary: optional(r[4]),
    page: optional(r[5]),
    count: count(r[6]),
    lastSeen: optional(r[7]),
  }));
}

/** Rows are [host, status, method, path, count, lastSeen]. */
export function shapeFailedRequests(raw: unknown[][]): SiteFailedRequestRow[] {
  return raw.map((r) => ({
    host: label(r[0], "(unknown)"),
    status: count(r[1]),
    method: optional(r[2]),
    path: label(r[3], "(unknown)"),
    count: count(r[4]),
    lastSeen: optional(r[5]),
  }));
}

/**
 * The rows behind each site's page. Fetched for every site at once, like the rest of this file, so
 * moving between sites costs no query. A busy site can have hundreds of distinct failing paths, so
 * the cap is high and hitting it is reported.
 */
export async function loadSiteErrorDetail(env: PosthogEnv, w: RangeWindow): Promise<SiteErrorDetailSection> {
  const status = "toFloat(properties.status)";
  const failed = `(${status} >= 500 OR ${status} = 0)`;
  const isFailure = `event = 'http_request' AND ${failed}`;
  // In turn, so the first failure ends the section without spending the other two scans.
  const days = await rows(
    env,
    `SELECT ${HOST}, toStartOfDay(timestamp), countIf(event = 'error_reported'), countIf(${isFailure}) FROM events ` +
      `WHERE event IN ('error_reported', 'http_request') AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1, 2 ORDER BY 2 LIMIT ${ERROR_DETAIL_ROW_LIMIT}`,
  );
  const errors = await rows(
    env,
    `SELECT ${HOST}, properties.error_name, properties.feature, properties.step, properties.boundary, properties.$pathname, count(), max(timestamp) FROM events ` +
      `WHERE event = 'error_reported' AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1, 2, 3, 4, 5, 6 ORDER BY 7 DESC LIMIT ${ERROR_DETAIL_ROW_LIMIT}`,
  );
  const requests = await rows(
    env,
    `SELECT ${HOST}, ${status}, properties.method, properties.path, count(), max(timestamp) FROM events ` +
      `WHERE ${isFailure} AND ${since(w)} AND ${PRODUCTION_HOSTS} GROUP BY 1, 2, 3, 4 ORDER BY 5 DESC LIMIT ${ERROR_DETAIL_ROW_LIMIT}`,
  );
  return {
    buckets: w.buckets,
    days: shapeErrorDays(days, w.buckets),
    errors: shapeSiteErrors(errors),
    requests: shapeFailedRequests(requests),
    truncated: [days, errors, requests].some((found) => found.length >= ERROR_DETAIL_ROW_LIMIT),
  };
}
