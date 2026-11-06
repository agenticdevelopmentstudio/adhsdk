import { Hono } from 'hono';
import type { Tier } from '../middleware/auth';
import type { Storage } from '../storage/ports';
import { loadRuntimeErrorsReport } from '../telemetry/runtime-errors';
import type { DashboardSet } from '../telemetry/dashboard/dashboard-set';
import { ANALYTICS_RANGES } from '../telemetry/dashboard/ranges';

// ---------------------------------------------------------------------------
// The Analytics and Errors topics. Both answer IMMEDIATELY with whatever is known and refresh
// behind the response (see sectioned-dashboard.ts), so a client polls while `refreshing`.
//
// The caches themselves are the app's ONE `DashboardSet` (built in `createApp`), shared with
// `GET /report` and the MCP tools so they never pay for a second refresh of the same answer.
//
// Behind the app-wide requireAuth like /telemetry, and never under /public: GlitchTip titles
// and per-site traffic are operator-only.
// ---------------------------------------------------------------------------

function isOneOf<T extends string>(allowed: readonly T[], value: string): value is T {
  return (allowed as readonly string[]).includes(value);
}

export function dashboardRoutes(
  dashboards: DashboardSet,
  storage: Storage,
): Hono<{ Variables: { tier: Tier } }> {
  const app = new Hono<{ Variables: { tier: Tier } }>();

  app.get('/analytics/dashboard', (c) => {
    const range = c.req.query('range') ?? '7d';
    if (!isOneOf(ANALYTICS_RANGES, range)) return c.json({ error: 'invalid range' }, 400);
    return c.json(dashboards.analytics(range), 200, { 'Cache-Control': 'no-store' });
  });

  app.get('/errors/dashboard', async (c) =>
    c.json(await dashboards.errors(), 200, { 'Cache-Control': 'no-store' }),
  );

  // Vercel runtime errors of the last 24h, grouped: what the server side of every production site
  // threw or answered 5xx. Read from the store the monitor cycle fills; empty until Vercel is
  // configured and the first read lands.
  app.get('/errors/runtime', async (c) => {
    const body = await loadRuntimeErrorsReport(storage.telemetry.runtimeErrors);
    return c.json(body, 200, { 'Cache-Control': 'no-store' });
  });

  return app;
}
