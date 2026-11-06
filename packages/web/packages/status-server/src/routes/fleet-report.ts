import { Hono } from 'hono';
import type { Tier } from '../middleware/auth';
import { gatherReport, parseReportParams, type ReportSources } from '../report/report-gather';

// ---------------------------------------------------------------------------
// GET /report — the whole fleet's health in one agent-ready payload (src/report/types.ts).
// View tier, like /snapshot: it sits behind the app-wide requireAuth. Every judgement is made
// in src/report/report-rules.ts; this route only validates the query and hands it over. The
// MCP tool `get_report` answers with the same payload from the same params.
// ---------------------------------------------------------------------------

export function reportRoutes(sources: ReportSources): Hono<{ Variables: { tier: Tier } }> {
  const app = new Hono<{ Variables: { tier: Tier } }>();

  app.get('/report', async (c) => {
    const params = parseReportParams({
      range: c.req.query('range'),
      days: c.req.query('days'),
      wait: c.req.query('wait'),
      logs: c.req.query('logs'),
    });
    return c.json(await gatherReport(sources, params), 200, { 'Cache-Control': 'no-store' });
  });

  return app;
}
