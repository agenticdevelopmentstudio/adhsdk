import { BEARER, okJson, ref, errors, type Paths, type Schemas } from '../shared';

// ---------------------------------------------------------------------------
// The Analytics and Errors topics (src/routes/telemetry-dashboards.ts). Shapes are defined in
// src/telemetry/dashboard/types.ts. Each answers immediately with what is known: `refreshing`
// says more is coming, and every section is { data, error, updatedAt } on its own, because the
// providers behind them succeed and fail independently.
// ---------------------------------------------------------------------------

const tag = 'dashboards';
const num = { type: 'number' };
const str = { type: 'string' };
const bool = { type: 'boolean' };
const nullableNum = { type: ['number', 'null'] };
const nullableStr = { type: ['string', 'null'] };
const strs = { type: 'array', items: str };
const nums = { type: 'array', items: num };

function object(properties: Record<string, unknown>): Record<string, unknown> {
  return { type: 'object', required: Object.keys(properties), properties };
}

function list(schema: unknown): Record<string, unknown> {
  return { type: 'array', items: schema };
}

/** One section: its last good answer, why the latest attempt failed, and when it was fetched. */
function section(data: Record<string, unknown>): Record<string, unknown> {
  return object({ data: { anyOf: [data, { type: 'null' }] }, error: nullableStr, updatedAt: nullableStr });
}

export const dashboardSchemas: Schemas = {
  SiteHealthRow: object({ host: str, errors: num, requests: num, failures: num, p95Ms: nullableNum }),
  DashboardMarginal: object({ name: str, pageviews: num }),
  RuntimeErrorGroup: object({
    key: str,
    project: str,
    deploymentId: str,
    domain: nullableStr,
    source: str,
    method: nullableStr,
    path: nullableStr,
    status: nullableNum,
    level: str,
    message: str,
    count: num,
    firstSeen: str,
    lastSeen: str,
    sampleRowId: nullableStr,
  }),
  VitalsRow: object({ host: str, samples: num, lcp: nullableNum, inp: nullableNum, cls: nullableNum, fcp: nullableNum }),
  ErrorIssue: object({
    id: str,
    shortId: nullableStr,
    title: str,
    type: nullableStr,
    source: nullableStr,
    level: nullableStr,
    count: num,
    userCount: num,
    firstSeen: nullableStr,
    lastSeen: nullableStr,
    release: nullableStr,
    project: str,
    permalink: nullableStr,
    active: bool,
  }),
  SiteErrorRow: object({
    host: str,
    name: str,
    feature: nullableStr,
    step: nullableStr,
    boundary: nullableStr,
    page: nullableStr,
    count: num,
    lastSeen: nullableStr,
  }),
  SiteFailedRequestRow: object({ host: str, status: num, method: nullableStr, path: str, count: num, lastSeen: nullableStr }),
  RuntimeErrorsReport: object({
    generatedAt: str,
    window: { type: 'string', enum: ['24h'] },
    total: num,
    groups: list(ref('RuntimeErrorGroup')),
  }),
};

const siteHealth = ref('SiteHealthRow');
const marginals = list(ref('DashboardMarginal'));

const analyticsSections = object({
  traffic: section(
    object({
      buckets: strs,
      totals: object({ pageviews: num, sessions: num }),
      pageviews: nums,
      sessions: nums,
      sites: list(object({ host: str, pageviews: num, sessions: num, series: nums })),
    }),
  ),
  dimensions: section(
    object({
      rows: list(object({ host: str, device: str, browser: str, country: str, referrer: str, pageviews: num })),
      truncated: bool,
    }),
  ),
  paths: section(list(object({ host: str, path: str, pageviews: num }))),
  vitals: section(
    list(ref('VitalsRow')),
  ),
  health: section(list(siteHealth)),
  vercel: section(
    object({
      buckets: strs,
      projectsTotal: num,
      projectsEnabled: num,
      failed: num,
      roster: list(
        object({ project: str, domain: nullableStr, analyticsOn: bool, pageviews: nullableNum, visitors: nullableNum }),
      ),
      totals: object({ pageviews: num, visitors: num }),
      pageviews: nums,
      visitors: nums,
      projects: list(
        object({
          project: str,
          domain: nullableStr,
          pageviews: num,
          visitors: num,
          series: nums,
          countries: marginals,
          referrers: marginals,
          paths: marginals,
          devices: marginals,
        }),
      ),
    }),
  ),
});

const errorsSections = object({
  issues: section(
    object({
      buckets: strs,
      issues: list(ref('ErrorIssue')),
      summary: object({
        active: num,
        backlog: num,
        events: num,
        resolved: nullableNum,
        complete: bool,
        byType: list(object({ name: str, issues: num, events: num })),
        newPerDay: nums,
      }),
    }),
  ),
  sites: section(list(siteHealth)),
  detail: section(
    object({
      buckets: strs,
      days: list(object({ host: str, errors: nums, failures: nums })),
      errors: list(ref('SiteErrorRow')),
      requests: list(ref('SiteFailedRequestRow')),
      truncated: bool,
    }),
  ),
  runtime: section(ref('RuntimeErrorsReport')),
});

export const dashboardPaths: Paths = {
  '/analytics/dashboard': {
    get: {
      tags: [tag],
      summary: 'Per-site and aggregate traffic from PostHog and Vercel Web Analytics',
      security: BEARER,
      parameters: [
        { name: 'range', in: 'query', schema: { type: 'string', enum: ['24h', '7d', '30d'], default: '7d' } },
      ],
      responses: {
        200: okJson(
          'What is known now; poll while `refreshing`',
          object({
            generatedAt: str,
            refreshing: bool,
            range: str,
            configured: object({ posthog: bool, vercel: bool }),
            sections: analyticsSections,
          }),
        ),
        ...errors(400, 401),
      },
    },
  },
  '/errors/dashboard': {
    get: {
      tags: [tag],
      summary:
        'Every unresolved GlitchTip issue, 30-day event history, each site’s errors and failed requests, and the last 24h of Vercel runtime errors',
      security: BEARER,
      responses: {
        200: okJson(
          'What is known now; poll while `refreshing`',
          object({
            generatedAt: str,
            refreshing: bool,
            configured: object({ glitchtip: bool, posthog: bool, vercel: bool }),
            sections: errorsSections,
          }),
        ),
        ...errors(401),
      },
    },
  },
  '/errors/runtime': {
    get: {
      tags: [tag],
      summary: 'Vercel runtime errors of the last 24h, grouped',
      description:
        'Error/fatal log lines and 5xx responses of each production project’s current production deployment, ' +
        'as the monitor cycle last read them. Grouped by project, source, method, normalized path, status and ' +
        'first message line; `count` is lines since `firstSeen` (7-day retention). Worst level first, then most ' +
        'frequent. `total` counts every group in the window; `groups` is capped at 200.',
      security: BEARER,
      responses: {
        200: okJson('Groups last seen in the window', ref('RuntimeErrorsReport')),
        ...errors(401),
      },
    },
  },
};
