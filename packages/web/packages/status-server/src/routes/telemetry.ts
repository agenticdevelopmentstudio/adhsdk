import { Hono } from 'hono';
import type { StatusConfig } from '../config/port';
import type { Storage } from '../storage/ports';
import type { Tier } from '../middleware/auth';
import { buildAnalyticsFetcher, buildErrorsFetcher } from '../telemetry/server';
import type { Fetcher } from '../telemetry/ports';
import { cachedSingleFlight } from '@agentic-toolkit/deploy-platform/util';
import type { AnalyticsMetricDTO, ErrorDTO, TelemetrySnapshot } from '../telemetry/types';

// ---------------------------------------------------------------------------
// The TELEMETRY read API — the production-visibility band (errors + analytics).
//
//   /telemetry   LIVE snapshot — polls GlitchTip + PostHog directly (NOT the DB).
//                GlitchTip is cached 30s and awaited; PostHog is cached 5 min and
//                never held up for: see `analyticsForSnapshot`. ?fresh=1 bypasses
//                both caches and waits for both. A failed poll serves the last good
//                stream rather than blanking it.
//   /errors      the SQLite-backed errors stream (errorsStore.load)
//   /analytics   the SQLite-backed analytics stream, reduced to the latest value
//                per (metric, window, scope) (analyticsStore.load)
//
// These sit behind the app-wide requireAuth (VIEW/ADMIN/cookie — the frontend
// proxy attaches the cookie). They are NOT /snapshot, so PEER_TOKEN does NOT
// apply, which is correct: peers exchange health snapshots, not telemetry.
// ---------------------------------------------------------------------------

const ERRORS_CACHE_TTL_MS = 30_000;
/** Headline traffic KPIs over 24h and 7d: nobody needs these to the second. */
const ANALYTICS_CACHE_TTL_MS = 5 * 60_000;
/** How long a cold start waits for PostHog before answering without it. */
const ANALYTICS_COLD_WAIT_MS = 3_000;

export function telemetryRoutes(
  storage: Storage,
  config: StatusConfig,
  // Injectable for tests (a fetcher built once at call time can't be varied
  // per-case otherwise); production wiring passes nothing.
  deps: { errorsFetcher?: Fetcher<ErrorDTO>; analyticsFetcher?: Fetcher<AnalyticsMetricDTO> } = {},
): Hono<{ Variables: { tier: Tier } }> {
  const errorsFetcher = deps.errorsFetcher ?? buildErrorsFetcher(config);
  const analyticsFetcher = deps.analyticsFetcher ?? buildAnalyticsFetcher(config);
  const app = new Hono<{ Variables: { tier: Tier } }>();

  // Last stream that ACTUALLY polled ok, per provider — a failed poll serves this
  // instead of blanking the band (an empty-because-failed stream is indistinguishable
  // from a healthy "no errors" to the client, so substitute the last good read).
  const lastGood: { errors: ErrorDTO[] | null; analytics: AnalyticsMetricDTO[] | null } = {
    errors: null,
    analytics: null,
  };

  // TTL + single-flight (the shared primitive), one per provider because they have nothing
  // in common: concurrent cache misses — a burst of page loads, several panes — share ONE
  // provider poll instead of each fanning out its own, which is what turned one slow
  // provider into a page-load-multiplied wall of "[telemetry] … failed" log lines. A
  // ?fresh=1 during an in-flight build joins it: a poll started moments ago IS fresh.
  const cachedErrors = cachedSingleFlight(ERRORS_CACHE_TTL_MS, async () => {
    const r = await errorsFetcher.fetch();
    if (r.ok) lastGood.errors = r.items;
    return lastGood.errors ?? [];
  });
  const cachedAnalytics = cachedSingleFlight(ANALYTICS_CACHE_TTL_MS, async () => {
    const r = await analyticsFetcher.fetch();
    if (r.ok) lastGood.analytics = r.items;
    return lastGood.analytics ?? [];
  });

  // PostHog takes 2–30s to answer, and the GlitchTip half of this snapshot is what the
  // Overview's error card and the board wait on. Awaiting both let the slow half hold up the
  // fast half: `/telemetry` was logging 18s stalls. So a normal read serves what we already
  // have and lets the refresh land for the next poll; only a cold start waits, briefly.
  async function analyticsForSnapshot(fresh: boolean): Promise<AnalyticsMetricDTO[]> {
    const refresh = cachedAnalytics(fresh);
    if (fresh) return refresh;
    const known = lastGood.analytics;
    if (known) {
      void refresh.catch(() => undefined);
      return known;
    }
    let timer: ReturnType<typeof setTimeout> | undefined;
    const coldWait = new Promise<AnalyticsMetricDTO[]>((resolve) => {
      timer = setTimeout(() => resolve([]), ANALYTICS_COLD_WAIT_MS);
    });
    try {
      return await Promise.race([refresh, coldWait]);
    } finally {
      clearTimeout(timer);
    }
  }

  app.get('/telemetry', async (c) => {
    const fresh = c.req.query('fresh') === '1';
    const [errors, analytics] = await Promise.all([cachedErrors(fresh), analyticsForSnapshot(fresh)]);
    const snapshot: TelemetrySnapshot = { generatedAt: new Date().toISOString(), errors, analytics };
    return c.json(snapshot, 200, { 'Cache-Control': 'no-store' });
  });

  app.get('/errors', async (c) => {
    const errors = await storage.telemetry.errors.load();
    return c.json({ errors }, 200, { 'Cache-Control': 'public, max-age=30' });
  });

  app.get('/analytics', async (c) => {
    const metrics = await storage.telemetry.analytics.load();
    return c.json({ metrics }, 200, { 'Cache-Control': 'public, max-age=30' });
  });

  return app;
}
