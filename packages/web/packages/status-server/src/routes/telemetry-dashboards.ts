import { Hono } from 'hono';
import { glitchtipConfigured, posthogConfigured, vercelConfigured, type StatusConfig } from '../config/port';
import type { Tier } from '../middleware/auth';
import { loadErrorIssues, resolvedCounter } from '../telemetry/dashboard/errors-sections';
import {
  loadDimensions,
  loadPaths,
  loadSiteErrorDetail,
  loadSiteHealth,
  loadTraffic,
  loadVitals,
} from '../telemetry/dashboard/posthog-sections';
import { ANALYTICS_RANGES, rangeWindow, type AnalyticsRange } from '../telemetry/dashboard/ranges';
import { emptySections, sectionedDashboard } from '../telemetry/dashboard/sectioned-dashboard';
import {
  type AnalyticsDashboardResponse,
  type AnalyticsSectionData,
  type ErrorsDashboardResponse,
  type ErrorsSectionData,
} from '../telemetry/dashboard/types';
import { loadVercelTraffic } from '../telemetry/dashboard/vercel-section';

// ---------------------------------------------------------------------------
// The Analytics and Errors topics. Both answer IMMEDIATELY with whatever is known and refresh
// behind the response (see sectioned-dashboard.ts), so a client polls while `refreshing`.
//
// Behind the app-wide requireAuth like /telemetry, and never under /public: GlitchTip titles
// and per-site traffic are operator-only.
// ---------------------------------------------------------------------------

/** These describe days of traffic, and a refresh costs a minute of provider time. */
const ANALYTICS_TTL_MS = 10 * 60_000;
const ERRORS_TTL_MS = 60_000;

type PosthogSections = Omit<AnalyticsSectionData, 'vercel'>;
type VercelSections = Pick<AnalyticsSectionData, 'vercel'>;
type SitesSections = Pick<ErrorsSectionData, 'sites' | 'detail'>;
type GlitchtipSections = Omit<ErrorsSectionData, keyof SitesSections>;

const POSTHOG_SECTIONS = ['traffic', 'dimensions', 'paths', 'vitals', 'health'] as const;
const VERCEL_SECTIONS = ['vercel'] as const;
const GLITCHTIP_SECTIONS = ['issues'] as const;
const SITES_SECTIONS = ['sites', 'detail'] as const;

function isOneOf<T extends string>(allowed: readonly T[], value: string): value is T {
  return (allowed as readonly string[]).includes(value);
}

export function dashboardRoutes(config: StatusConfig): Hono<{ Variables: { tier: Tier } }> {
  const app = new Hono<{ Variables: { tier: Tier } }>();
  const creds = config.credentials;

  // Providers refresh independently: a slow PostHog must not hold back GlitchTip or Vercel.
  const posthog = sectionedDashboard<AnalyticsRange, PosthogSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: POSTHOG_SECTIONS,
    loaders: (range) => {
      const w = rangeWindow(range, Date.now());
      return {
        traffic: () => loadTraffic(creds, w),
        dimensions: () => loadDimensions(creds, w),
        paths: () => loadPaths(creds, w),
        vitals: () => loadVitals(creds, w),
        health: () => loadSiteHealth(creds, w),
      };
    },
  });
  const vercel = sectionedDashboard<AnalyticsRange, VercelSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: VERCEL_SECTIONS,
    // One project's timeout shouldn't leave its chart flat for the whole TTL.
    incomplete: (_name, data) => data.failed > 0 || data.incomplete > 0,
    loaders: (range) => ({ vercel: () => loadVercelTraffic(creds, rangeWindow(range, Date.now())) }),
  });
  const resolvedCount = resolvedCounter(creds);
  const glitchtip = sectionedDashboard<'all', GlitchtipSections>({
    ttlMs: ERRORS_TTL_MS,
    sections: GLITCHTIP_SECTIONS,
    loaders: () => ({
      issues: () => loadErrorIssues(creds, config.glitchtipProjects, resolvedCount),
    }),
  });
  const errorSites = sectionedDashboard<'all', SitesSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: SITES_SECTIONS,
    loaders: () => {
      const w = rangeWindow('30d', Date.now());
      return {
        sites: () => loadSiteHealth(creds, w),
        detail: () => loadSiteErrorDetail(creds, w),
      };
    },
  });

  app.get('/analytics/dashboard', (c) => {
    const range = c.req.query('range') ?? '7d';
    if (!isOneOf(ANALYTICS_RANGES, range)) return c.json({ error: 'invalid range' }, 400);

    const posthogOn = posthogConfigured(config);
    const vercelOn = vercelConfigured(config);
    const ph = posthogOn ? posthog.read(range) : null;
    const vc = vercelOn ? vercel.read(range) : null;

    const body: AnalyticsDashboardResponse = {
      generatedAt: new Date().toISOString(),
      refreshing: Boolean(ph?.refreshing || vc?.refreshing),
      range,
      configured: { posthog: posthogOn, vercel: vercelOn },
      sections: {
        ...(ph?.sections ?? emptySections<PosthogSections>(POSTHOG_SECTIONS)),
        ...(vc?.sections ?? emptySections<VercelSections>(VERCEL_SECTIONS)),
      },
    };
    return c.json(body, 200, { 'Cache-Control': 'no-store' });
  });

  app.get('/errors/dashboard', (c) => {
    const glitchtipOn = glitchtipConfigured(config);
    const posthogOn = posthogConfigured(config);
    const gt = glitchtipOn ? glitchtip.read('all') : null;
    const sites = posthogOn ? errorSites.read('all') : null;

    const body: ErrorsDashboardResponse = {
      generatedAt: new Date().toISOString(),
      refreshing: Boolean(gt?.refreshing || sites?.refreshing),
      configured: { glitchtip: glitchtipOn, posthog: posthogOn },
      sections: {
        ...(gt?.sections ?? emptySections<GlitchtipSections>(GLITCHTIP_SECTIONS)),
        ...(sites?.sections ?? emptySections<SitesSections>(SITES_SECTIONS)),
      },
    };
    return c.json(body, 200, { 'Cache-Control': 'no-store' });
  });

  return app;
}
