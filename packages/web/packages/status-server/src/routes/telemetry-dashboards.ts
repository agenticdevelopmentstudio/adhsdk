import { Hono } from 'hono';
import { glitchtipConfigured, posthogConfigured, vercelConfigured, type StatusConfig } from '../config/port';
import type { Tier } from '../middleware/auth';
import { loadErrorIssues } from '../telemetry/dashboard/errors-sections';
import {
  loadDimensions,
  loadPaths,
  loadSiteHealth,
  loadTraffic,
  loadVitals,
} from '../telemetry/dashboard/posthog-sections';
import { ANALYTICS_RANGES, rangeWindow, type AnalyticsRange } from '../telemetry/dashboard/ranges';
import { emptySections, sectionedDashboard } from '../telemetry/dashboard/sectioned-dashboard';
import {
  ANALYTICS_ENVIRONMENTS,
  type AnalyticsDashboardResponse,
  type AnalyticsEnvironment,
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
type GlitchtipSections = Omit<ErrorsSectionData, 'sites'>;
type SitesSections = Pick<ErrorsSectionData, 'sites'>;

const POSTHOG_SECTIONS = ['traffic', 'dimensions', 'paths', 'vitals', 'health'] as const;
const VERCEL_SECTIONS = ['vercel'] as const;
const GLITCHTIP_SECTIONS = ['issues'] as const;
const SITES_SECTIONS = ['sites'] as const;

function isOneOf<T extends string>(allowed: readonly T[], value: string): value is T {
  return (allowed as readonly string[]).includes(value);
}

export function dashboardRoutes(config: StatusConfig): Hono<{ Variables: { tier: Tier } }> {
  const app = new Hono<{ Variables: { tier: Tier } }>();
  const creds = config.credentials;

  // Providers refresh independently: a slow PostHog must not hold back GlitchTip or Vercel.
  const posthog = sectionedDashboard<`${AnalyticsRange}|${AnalyticsEnvironment}`, PosthogSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: POSTHOG_SECTIONS,
    loaders: (key) => {
      const [range, env] = key.split('|') as [AnalyticsRange, AnalyticsEnvironment];
      const w = rangeWindow(range, Date.now());
      return {
        traffic: () => loadTraffic(creds, env, w),
        dimensions: () => loadDimensions(creds, env, w),
        paths: () => loadPaths(creds, env, w),
        vitals: () => loadVitals(creds, env, w),
        health: () => loadSiteHealth(creds, env, w),
      };
    },
  });
  const vercel = sectionedDashboard<AnalyticsRange, VercelSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: VERCEL_SECTIONS,
    loaders: (range) => ({ vercel: () => loadVercelTraffic(creds, rangeWindow(range, Date.now())) }),
  });
  const glitchtip = sectionedDashboard<'all', GlitchtipSections>({
    ttlMs: ERRORS_TTL_MS,
    sections: GLITCHTIP_SECTIONS,
    loaders: () => ({
      issues: () => loadErrorIssues(creds),
    }),
  });
  const errorSites = sectionedDashboard<'all', SitesSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: SITES_SECTIONS,
    loaders: () => ({
      sites: () => loadSiteHealth(creds, 'production', rangeWindow('30d', Date.now())),
    }),
  });

  app.get('/analytics/dashboard', (c) => {
    const range = c.req.query('range') ?? '7d';
    const env = c.req.query('env') ?? 'production';
    if (!isOneOf(ANALYTICS_RANGES, range)) return c.json({ error: 'invalid range' }, 400);
    if (!isOneOf(ANALYTICS_ENVIRONMENTS, env)) return c.json({ error: 'invalid env' }, 400);

    const posthogOn = posthogConfigured(config);
    const vercelOn = vercelConfigured(config);
    // Vercel's API is production-only, so asking it about staging would spend quota to mislead.
    const vercelApplies = vercelOn && env === 'production';
    const ph = posthogOn ? posthog.read(`${range}|${env}`) : null;
    const vc = vercelApplies ? vercel.read(range) : null;

    const body: AnalyticsDashboardResponse = {
      generatedAt: new Date().toISOString(),
      refreshing: Boolean(ph?.refreshing || vc?.refreshing),
      range,
      env,
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
