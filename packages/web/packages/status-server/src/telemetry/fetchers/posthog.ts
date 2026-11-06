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

/** The last HogQL request queued on this thread; the next one starts after it settles. */
let hogqlTail: Promise<unknown> = Promise.resolve();

// The PROCESS-wide half of "one at a time". `hogqlTail` orders the queries of one thread, but
// the monitor's worker thread loads its own copy of this module, so its KPI poll had a queue
// of its own and ran beside the API thread's dashboard sections: two queues, concurrent HogQL,
// the 503s this rule exists to prevent. The cooldowns hit the same thread boundary and solved
// it the same way (`@adh-sdk/deploy-platform/cooldown`): one SharedArrayBuffer, created on the
// API thread and handed to the worker as `workerData`.
//
// The one slot holds a LEASE — the epoch ms the holder's turn ends, 0 when free — rather than
// a held/free flag, because the monitor client terminates a wedged worker outright, and a flag
// set by a thread that no longer exists would never clear: every later query on either thread
// would wait forever. A lease outlives its holder by at most one query's timeout. BigInt64 so
// the reads and writes can go through Atomics (Float64 is not allowed).
let hogqlLease = new BigInt64Array(new SharedArrayBuffer(8));

/** How long past a query's own timeout its lease is held: the abort has to land and unwind. */
const HOGQL_LEASE_GRACE_MS = 1_000;
/** How often a thread waiting on the other thread's query looks again. Queries take seconds. */
const HOGQL_LEASE_POLL_MS = 50;

/** The state to hand a worker thread (workerData), so both threads take turns on one lease. */
export function hogqlLockState(): SharedArrayBuffer {
  return hogqlLease.buffer as SharedArrayBuffer;
}

/** Adopt the state passed from the parent thread. Called once, at worker boot; without it the
 *  worker keeps a private lease and queries PostHog alongside the API thread. */
export function attachHogqlLockState(buffer: SharedArrayBuffer | undefined): void {
  if (buffer) hogqlLease = new BigInt64Array(buffer);
}

/** Wait until the lease is free (or its holder's turn has run out), then take it. */
async function acquireHogqlLease(leaseMs: number): Promise<bigint> {
  for (;;) {
    const now = Date.now();
    const held = Atomics.load(hogqlLease, 0);
    if (held === 0n || held <= BigInt(now)) {
      const mine = BigInt(now + leaseMs);
      // Only one thread's exchange can still find `held` there; the other looks again.
      if (Atomics.compareExchange(hogqlLease, 0, held, mine) === held) return mine;
      continue;
    }
    await new Promise((resolve) => setTimeout(resolve, HOGQL_LEASE_POLL_MS));
  }
}

/** Give the lease back, unless it lapsed and the other thread already holds it. */
function releaseHogqlLease(mine: bigint): void {
  Atomics.compareExchange(hogqlLease, 0, mine, 0n);
}

/**
 * One HogQL query → its rows. Failures are RETURNED, not logged, so each caller decides how
 * loud a degraded provider should be.
 *
 * One at a time, for the whole process: the API 503s under concurrent load, and the callers
 * (the dashboards' sections, the Errors detail, the KPI poll) do not know about each other, so
 * the rule is kept here rather than trusted to each of them. Each thread queues its own queries
 * on `hogqlTail`, and the head of that queue then takes the shared lease, so the API thread and
 * the monitor's worker take turns as well. `timeoutMs` starts when the query does, not while it
 * waits its turn.
 */
export function hogqlRows(env: PosthogEnv, query: string, timeoutMs: number): Promise<HogqlResult> {
  const run = hogqlTail.then(async () => {
    const lease = await acquireHogqlLease(timeoutMs + HOGQL_LEASE_GRACE_MS);
    try {
      return await hogqlRowsNow(env, query, timeoutMs);
    } finally {
      releaseHogqlLease(lease);
    }
  });
  hogqlTail = run;
  return run;
}

async function hogqlRowsNow(env: PosthogEnv, query: string, timeoutMs: number): Promise<HogqlResult> {
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
