import type { Fetcher, FetchResult } from "../ports";
import type { AnalyticsMetricDTO } from "../types";

// PostHog adapter for the Fetcher port. Headline KPIs via PostHog's HogQL query
// API — anonymous + aggregate only, matching the privacy-first capture (no person
// data ever leaves PostHog into here). PURE w.r.t. storage. No-ops (ok, []) until
// POSTHOG_HOST/_API_KEY/_PROJECT_ID are configured.

export interface PosthogEnv {
  POSTHOG_HOST?: string;
  POSTHOG_API_KEY?: string;
  POSTHOG_PROJECT_ID?: string;
}

export type HogqlResult = { ok: true; rows: unknown[][] } | { ok: false; error: string };

/**
 * One HogQL query → its rows. Failures are RETURNED, not logged, so each caller decides how
 * loud a degraded provider should be. Run these one at a time: the API 503s under concurrent
 * load.
 */
export async function hogqlRows(env: PosthogEnv, query: string, timeoutMs: number): Promise<HogqlResult> {
  const { POSTHOG_HOST, POSTHOG_API_KEY, POSTHOG_PROJECT_ID } = env;
  if (!POSTHOG_HOST || !POSTHOG_API_KEY || !POSTHOG_PROJECT_ID) return { ok: false, error: "PostHog is not configured" };
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(`${POSTHOG_HOST.replace(/\/+$/, "")}/api/projects/${POSTHOG_PROJECT_ID}/query/`, {
      method: "POST",
      headers: { Authorization: `Bearer ${POSTHOG_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ query: { kind: "HogQLQuery", query } }),
      signal: controller.signal,
    });
    if (!res.ok) return { ok: false, error: `HTTP ${res.status}` };
    const body = (await res.json()) as { results?: unknown };
    if (!Array.isArray(body.results)) return { ok: false, error: "response had no results" };
    return { ok: true, rows: body.results as unknown[][] };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : String(err) };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * All four KPIs from ONE query, in this column order. They used to be four sequential
 * queries on a 10s timeout each. PostHog answers in 2–30s depending on load, so the batch
 * usually died on the first query (`0/4 queries answered`) and a poll could spend most of
 * 40s doing it, which is what made `/telemetry` stall the Overview.
 */
const KPI_COLUMNS = [
  { metric: "pageviews", window: "24h" },
  { metric: "visitors", window: "24h" },
  { metric: "pageviews", window: "7d" },
  { metric: "visitors", window: "7d" },
] as const;

// visitors is approximate under cookieless capture (distinct id resets per session) — a
// deliberate trade for not tracking people across sessions.
const KPI_QUERY =
  "SELECT countIf(timestamp > now() - INTERVAL 1 DAY), uniqIf(person_id, timestamp > now() - INTERVAL 1 DAY), count(), uniq(person_id) " +
  "FROM events WHERE event = '$pageview' AND timestamp > now() - INTERVAL 7 DAY";

/** Long enough for a loaded PostHog, short enough that the monitor cycle can afford it. */
const KPI_TIMEOUT_MS = 20_000;

/** HogQL numbers can arrive as numbers or strings, and aggregates over nothing as null. */
export function toMetricValue(v: unknown): number | null {
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (typeof v === "string" && v !== "") {
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

export function posthogFetcher(env: PosthogEnv): Fetcher<AnalyticsMetricDTO> {
  return {
    async fetch(): Promise<FetchResult<AnalyticsMetricDTO>> {
      const { POSTHOG_HOST, POSTHOG_API_KEY, POSTHOG_PROJECT_ID } = env;
      if (!POSTHOG_HOST || !POSTHOG_API_KEY || !POSTHOG_PROJECT_ID) return { ok: true, items: [] };

      const result = await hogqlRows(env, KPI_QUERY, KPI_TIMEOUT_MS);
      if (!result.ok) {
        console.warn(`[telemetry] PostHog poll failed (${result.error})`);
        // ok:false so a total outage never overwrites good trend data with an empty set.
        return { ok: false, items: [] };
      }
      const capturedAt = new Date().toISOString();
      const row = result.rows[0] ?? [];
      const items: AnalyticsMetricDTO[] = [];
      KPI_COLUMNS.forEach((c, i) => {
        const value = toMetricValue(row[i]);
        if (value !== null) items.push({ metric: c.metric, window: c.window, scope: "all", value, capturedAt });
      });
      return items.length === 0 ? { ok: false, items: [] } : { ok: true, items };
    },
  };
}
