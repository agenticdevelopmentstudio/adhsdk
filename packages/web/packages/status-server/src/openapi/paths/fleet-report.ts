import { BEARER, okJson, ref, errors, type Paths, type Schemas } from '../shared';

// ---------------------------------------------------------------------------
// GET /report (src/routes/fleet-report.ts). Shapes are defined in src/report/types.ts; every
// rule behind them is in src/report/report-rules.ts.
// ---------------------------------------------------------------------------

const tag = 'report';
const num = { type: 'number' };
const str = { type: 'string' };
const bool = { type: 'boolean' };
const nullableNum = { type: ['number', 'null'] };
const nullableStr = { type: ['string', 'null'] };
const strs = { type: 'array', items: str };
const severity = { type: 'string', enum: ['critical', 'major', 'minor'] };
const checkState = { type: 'string', enum: ['ok', 'warn', 'error'] };

function object(properties: Record<string, unknown>, optional: string[] = []): Record<string, unknown> {
  return { type: 'object', required: Object.keys(properties).filter((k) => !optional.includes(k)), properties };
}

function list(schema: unknown): Record<string, unknown> {
  return { type: 'array', items: schema };
}

const nullable = (schema: unknown): Record<string, unknown> => ({ anyOf: [schema, { type: 'null' }] });

const SOURCES = ['monitor', 'deploys', 'integrations', 'errors', 'runtimeErrors', 'analytics', 'uptime'];

export const reportSchemas: Schemas = {
  ReportCoverage: object(
    { ok: bool, error: str, notes: strs, unconfigured: strs, updatedAt: nullableStr },
    ['error', 'notes', 'unconfigured', 'updatedAt'],
  ),
  ReportFinding: object(
    { severity, source: str, title: str, detail: str, since: str, link: str, issueKey: str },
    ['detail', 'since', 'link', 'issueKey'],
  ),
  ReportFailingDeploy: object(
    {
      id: str,
      platform: str,
      project: str,
      tier: nullableStr,
      branch: nullableStr,
      createdAt: str,
      commit: nullableStr,
      error: nullableStr,
      url: nullableStr,
      logTail: strs,
      logLines: num,
      logError: str,
    },
    ['logTail', 'logLines', 'logError'],
  ),
};

const sections = object({
  monitor: nullable(
    object({
      overall: { type: 'string', enum: ['healthy', 'degraded', 'down'] },
      checkedAt: str,
      lastCycleAt: nullableStr,
      stale: bool,
      services: num,
      byStatus: { type: 'object', additionalProperties: num },
      openIssues: num,
      unprobed: strs,
    }),
  ),
  deploys: nullable(
    object({
      deployTargets: num,
      inFlight: num,
      failing: list(ref('ReportFailingDeploy')),
      staleProd: list(
        object({ projectName: str, environment: str, detail: nullableStr, sourceUrl: nullableStr, liveUrl: nullableStr }),
      ),
      providers: { type: 'object', additionalProperties: object({ configured: bool, ok: bool }) },
    }),
  ),
  integrations: nullable(
    object({
      overall: checkState,
      checks: list(object({ id: str, label: str, configured: bool, state: checkState, detail: nullableStr })),
    }),
  ),
  errors: nullable(
    object({
      summary: nullable(
        object({
          active: num,
          backlog: num,
          events: num,
          resolved: nullableNum,
          complete: bool,
          byType: list(object({ name: str, issues: num, events: num })),
          newPerDay: list(num),
        }),
      ),
      active: list(ref('ErrorIssue')),
      sites: list(ref('SiteHealthRow')),
      siteErrors: list(ref('SiteErrorRow')),
      failedRequests: list(ref('SiteFailedRequestRow')),
    }),
  ),
  runtimeErrors: nullable(
    object({ window: { type: 'string', enum: ['24h'] }, total: num, groups: list(ref('RuntimeErrorGroup')) }),
  ),
  analytics: nullable(
    object({
      range: { type: 'string', enum: ['24h', '7d', '30d'] },
      posthog: object({
        totals: nullable(object({ pageviews: num, sessions: num })),
        sites: list(object({ host: str, pageviews: num, sessions: num })),
      }),
      vercel: object({
        totals: nullable(object({ pageviews: num, visitors: num })),
        projectsTotal: nullableNum,
        projectsEnabled: nullableNum,
        failed: nullableNum,
        projects: list(object({ project: str, domain: nullableStr, pageviews: num, visitors: num })),
      }),
      vitals: list(ref('VitalsRow')),
    }),
  ),
  uptime: nullable(
    object({
      days: num,
      floor: num,
      services: list(object({ slug: str, name: str, uptimePercent: nullableNum, totalChecks: num })),
    }),
  ),
});

export const reportPaths: Paths = {
  '/report': {
    get: {
      tags: [tag],
      summary: 'One-call health digest of every source: verdict, findings, coverage, sections',
      description:
        'Reads the monitor, deploys, integrations, GlitchTip and PostHog errors, Vercel runtime errors, ' +
        'PostHog and Vercel analytics, and uptime in parallel. Every judgement is the server’s: `verdict` is ' +
        'the worst finding (critical→down, major→degraded, minor→attention; none → healthy when `complete`, ' +
        'else unknown). `complete` is false when any source could not be read, a dashboard section failed or ' +
        'was still refreshing at the `wait` deadline, or the monitor stopped probing; providers with no ' +
        'credentials are listed under `coverage[*].unconfigured` and do not clear it. A section is null ' +
        'exactly when its source could not be read. The MCP tool `get_report` returns the same payload.',
      security: BEARER,
      parameters: [
        { name: 'range', in: 'query', schema: { type: 'string', enum: ['24h', '7d', '30d'], default: '24h' } },
        { name: 'days', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 365, default: 7 } },
        { name: 'wait', in: 'query', schema: { type: 'integer', minimum: 0, maximum: 60, default: 20 } },
        { name: 'logs', in: 'query', schema: { type: 'string', enum: ['0', '1'], default: '0' } },
      ],
      responses: {
        200: okJson(
          'ReportResponse',
          object({
            schema: { type: 'string', enum: ['status.report/1'] },
            generatedAt: str,
            monitorVersion: nullableStr,
            verdict: { type: 'string', enum: ['healthy', 'attention', 'degraded', 'down', 'unknown'] },
            complete: bool,
            counts: object({ critical: num, major: num, minor: num }),
            coverage: object(Object.fromEntries(SOURCES.map((s) => [s, ref('ReportCoverage')]))),
            findings: list(ref('ReportFinding')),
            sections,
          }),
        ),
        ...errors(400, 401),
      },
    },
  },
};
