import { afterEach, describe, expect, it, vi } from 'vitest';
import { envConfig } from '../src/config';
import type { Storage } from '../src/storage/ports';
import { createDashboardSet } from '../src/telemetry/dashboard/dashboard-set';
import { loadErrorIssues, resolvedCounter, summarizeIssues, toErrorIssues } from '../src/telemetry/dashboard/errors-sections';
import {
  loadSiteErrorDetail,
  shapeDimensions,
  shapeFailedRequests,
  shapeTraffic,
} from '../src/telemetry/dashboard/posthog-sections';
import { rangeWindow } from '../src/telemetry/dashboard/ranges';
import * as dashboardTypes from '../src/telemetry/dashboard/types';
import type {
  RuntimeErrorGroup as DashboardRuntimeErrorGroup,
  RuntimeErrorsReport as DashboardRuntimeErrorsReport,
} from '../src/telemetry/dashboard/types';
import { loadVercelTraffic } from '../src/telemetry/dashboard/vercel-section';
import type { RuntimeErrorGroup, RuntimeErrorsReport } from '../src/telemetry/types';

// The wire shapes in dashboard/types.ts, exercised through the code that builds them. The runtime
// constants and the type parity with status-web are in status-web's dashboard-types-parity.test.ts.

const NOW = Date.parse('2026-11-04T15:30:20.000Z');
const HOUR = 3_600_000;

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const NO_PROVIDERS = {};
const POSTHOG = { POSTHOG_HOST: 'https://ph', POSTHOG_API_KEY: 'k', POSTHOG_PROJECT_ID: '1' };
const GLITCHTIP = { GLITCHTIP_URL: 'https://gt', GLITCHTIP_API_TOKEN: 't', GLITCHTIP_ORG: 'o' };
/** The set never touches storage unless Vercel is configured, and these cases never configure it. */
const NO_STORAGE = {} as Storage;
const setFor = (env: Record<string, string>) => createDashboardSet(envConfig(env), NO_STORAGE);
const EMPTY = { data: null, error: null, updatedAt: null };
/** A slow, empty answer: a refresh is in flight when the test looks, and finishes before it ends, so no
 *  query is left queued behind the shared PostHog lock for a later test to wait on. */
const slowEmpty = () =>
  vi.stubGlobal('fetch', () => new Promise((resolve) => setTimeout(() => resolve({ ok: true, status: 200, json: async () => ({ results: [] }) }), 5)));

describe('the analytics response', () => {
  it('dash-types-004 with no provider configured, every section is empty and nothing refreshes', () => {
    const res = setFor(NO_PROVIDERS).analytics('7d');
    expect(res.range).toBe('7d');
    expect(res.configured).toEqual({ posthog: false, vercel: false });
    expect(res.refreshing).toBe(false);
    expect(Object.keys(res.sections).sort()).toEqual(['dimensions', 'health', 'paths', 'traffic', 'vercel', 'vitals']);
    for (const section of Object.values(res.sections)) expect(section).toEqual(EMPTY);
  });

  it('dash-types-005 refreshing is true while the PostHog dashboard refreshes and Vercel is idle', async () => {
    slowEmpty();
    const set = setFor(POSTHOG);
    const res = set.analytics('7d');
    expect(res.configured).toEqual({ posthog: true, vercel: false });
    expect(res.refreshing).toBe(true);
    await set.settleAnalytics('7d', 5_000);
  });

  it('dash-types-012 generatedAt is an ISO 8601 date-time on both responses', async () => {
    const iso = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
    const set = setFor(NO_PROVIDERS);
    const analytics = set.analytics('24h');
    const errors = await set.errors(NOW);
    expect(analytics.generatedAt).toMatch(iso);
    expect(Number.isNaN(Date.parse(analytics.generatedAt))).toBe(false);
    expect(errors.generatedAt).toBe('2026-11-04T15:30:20.000Z');
  });
});

describe('the errors response', () => {
  it('dash-types-006 refreshing is true when site health refreshes and GlitchTip is idle', async () => {
    slowEmpty();
    const set = setFor(POSTHOG);
    const res = await set.errors(NOW);
    expect(res.refreshing).toBe(true);
    expect(res.refreshingSources).toEqual({ glitchtip: false, posthog: true });
    await set.settleErrors(5_000);
  });

  it('dash-types-007 without Vercel configured, the runtime section is the empty state', async () => {
    const res = await setFor(NO_PROVIDERS).errors(NOW);
    expect(res.configured.vercel).toBe(false);
    expect(res.sections.runtime).toEqual(EMPTY);
  });
});

describe('the PostHog sections', () => {
  const sevenDays = rangeWindow('7d', NOW);

  it('dash-types-008 a 7d traffic section has seven buckets and seven values in every series', () => {
    const t = shapeTraffic(
      [
        ['a.com', '2026-11-03T00:00:00Z', 1, 1],
        ['b.com', '2026-11-04T00:00:00Z', 2, 2],
      ],
      sevenDays.buckets,
    );
    expect(t.buckets ?? sevenDays.buckets).toHaveLength(7);
    expect(t.pageviews).toHaveLength(7);
    expect(t.sessions).toHaveLength(7);
    expect(t.sites).toHaveLength(2);
    for (const site of t.sites) expect(site.series).toHaveLength(7);
  });

  it('dash-types-010 a request with no response has status 0', () => {
    expect(shapeFailedRequests([['a.com', 0, null, '/x', 1, null]])[0]?.status).toBe(0);
  });

  it('dash-types-015 a 24h traffic section has 25 values per series, the quiet hours being 0', () => {
    const w = rangeWindow('24h', NOW);
    const t = shapeTraffic([['a.com', w.buckets[3]!, 4, 2]], w.buckets);
    expect(w.buckets).toHaveLength(25);
    expect(t.pageviews).toHaveLength(25);
    expect(t.sessions).toHaveLength(25);
    expect(t.sites[0]!.series).toHaveLength(25);
    expect(t.pageviews.filter((v) => v === 0)).toHaveLength(24);
    expect(t.pageviews[3]).toBe(4);
    expect(t.sites[0]!.series[0]).toBe(0);
  });

  it('dash-types-020 hitting the error-detail row cap sets truncated, and the rows kept are the commonest', async () => {
    const queries: string[] = [];
    const atCap = Array.from({ length: 5_000 }, () => ['a.com', 500, 'GET', '/x', 1, null]);
    vi.stubGlobal('fetch', async (_url: string, init: { body: string }) => {
      const query = (JSON.parse(init.body) as { query: { query: string } }).query.query;
      queries.push(query);
      return { ok: true, status: 200, json: async () => ({ results: query.includes('properties.path') ? atCap : [] }) };
    });
    const detail = await loadSiteErrorDetail(POSTHOG, rangeWindow('30d', NOW));
    expect(detail.truncated).toBe(true);
    expect(detail.requests).toHaveLength(5_000);
    // Rows come back highest count first, so what the cap cuts is the rarest.
    for (const q of queries.filter((q) => q.includes('count()'))) expect(q).toMatch(/ORDER BY \d+ DESC LIMIT 5000$/);
  });

  it('dash-types-021 hitting the dimension row cap sets truncated', () => {
    const rows = Array.from({ length: 3 }, () => ['a.com', 'Mobile', 'Safari', 'US', 'x.com', 1]);
    const d = shapeDimensions(rows, 3);
    expect(d.truncated).toBe(true);
    expect(d.rows).toHaveLength(3);
    expect(shapeDimensions(rows.slice(0, 2), 3).truncated).toBe(false);
  });
});

describe('the Vercel section', () => {
  const ENV = { VERCEL_API_TOKEN: 't', VERCEL_TEAM_ID: 'team' };
  const w = rangeWindow('7d', NOW);

  /** Answers every Vercel call through `handler`. The per-project domains lookup is answered empty. */
  function stubVercel(handler: (u: URL) => { status?: number; body?: unknown }): void {
    vi.stubGlobal('fetch', async (input: URL | string) => {
      const url = new URL(String(input));
      const { status = 200, body = {} } = url.pathname.endsWith('/domains') ? {} : handler(url);
      return { ok: status < 400, status, headers: new Headers(), json: async () => body, text: async () => '' };
    });
  }
  const enabled = (id: string, name: string) => ({ id, name, webAnalytics: { enabledAt: 1 } });

  it('dash-types-009 a project with analytics off has a roster entry with null counts, not zero', async () => {
    stubVercel((u) => (u.pathname === '/v9/projects' ? { body: { projects: [{ id: 'o1', name: 'dt-off-production' }] } } : {}));
    const s = await loadVercelTraffic(ENV, w);
    expect(s.roster).toEqual([{ project: 'dt-off-production', domain: null, analyticsOn: false, pageviews: null, visitors: null }]);
  });

  it('dash-types-016 a failed paths breakdown leaves the pageview count whole and marks the project incomplete', async () => {
    stubVercel((u) => {
      if (u.pathname === '/v9/projects') return { body: { projects: [enabled('i1', 'dt-incomplete-production')] } };
      if (u.pathname.endsWith('/count')) return { body: { data: { pageviews: 5, visitors: 2 } } };
      if (u.searchParams.get('by') === 'requestPath') return { status: 500 };
      return { body: { data: [] } };
    });
    const s = await loadVercelTraffic(ENV, w);
    expect(s.projects[0]).toMatchObject({ project: 'dt-incomplete-production', pageviews: 5, incomplete: true, paths: [] });
    expect(s.incomplete).toBe(1);
  });

  it('dash-types-017 a project whose count cannot be read is failed, and is left out of the totals', async () => {
    stubVercel((u) => {
      if (u.pathname === '/v9/projects') {
        return { body: { projects: [enabled('g1', 'dt-good-production'), enabled('b1', 'dt-bad-production')] } };
      }
      if (u.searchParams.get('projectId') === 'b1') return { status: 503 };
      if (u.pathname.endsWith('/count')) return { body: { data: { pageviews: 5, visitors: 2 } } };
      return { body: { data: [] } };
    });
    const s = await loadVercelTraffic(ENV, w);
    expect(s.failed).toBe(1);
    expect(s.totals).toEqual({ pageviews: 5, visitors: 2 });
    expect(s.projects.map((p) => p.project)).toEqual(['dt-good-production']);
    // The roster still names the unreadable project, with no count.
    expect(s.roster.find((r) => r.project === 'dt-bad-production')).toMatchObject({ pageviews: null, visitors: null });
  });
});

describe('the Errors sections', () => {
  const recent = new Date(NOW - HOUR).toISOString();
  const old = new Date(NOW - 48 * HOUR).toISOString();
  const judging = { nowMs: NOW, frozen: false, allowlist: null };
  const issue = (id: string, over: Record<string, unknown>) => ({
    id,
    title: id,
    level: 'error',
    count: 1,
    lastSeen: recent,
    project: { slug: 'app' },
    ...over,
  });

  it('dash-types-011 an unreadable resolved count and an unfinished list walk give resolved null and complete false', () => {
    const s = summarizeIssues([], rangeWindow('30d', NOW), { resolved: null, complete: false });
    expect(s.summary.resolved).toBeNull();
    expect(s.summary.complete).toBe(false);
  });

  it('dash-types-011 loadErrorIssues passes both through from a cut-short GlitchTip read', async () => {
    vi.stubGlobal('fetch', async (url: string) => ({
      ok: !url.includes('is:resolved'),
      status: url.includes('is:resolved') ? 503 : 200,
      headers: new Headers(),
      json: async () => [],
    }));
    const s = await loadErrorIssues(GLITCHTIP, null, resolvedCounter(GLITCHTIP), NOW);
    expect(s.summary.resolved).toBeNull();
  });

  it('dash-types-018 only an error-level issue seen in the last day is active, unless the feed is frozen', () => {
    const rows = [
      issue('e', { level: 'error' }),
      issue('w', { level: 'warning' }),
      issue('n', { level: null }),
      issue('stale', { level: 'error', lastSeen: old }),
    ];
    expect(toErrorIssues(rows, judging).map((i) => [i.id, i.active])).toEqual([
      ['e', true],
      ['w', false],
      ['n', false],
      ['stale', false],
    ]);
    expect(toErrorIssues(rows, { ...judging, frozen: true }).find((i) => i.id === 'stale')!.active).toBe(true);
  });

  it('dash-types-019 byType groups unresolved issues by exception class with their issue and event counts', () => {
    const issues = toErrorIssues(
      [
        issue('1', { count: 4, metadata: { type: 'TypeError' } }),
        issue('2', { count: 6, metadata: { type: 'TypeError' } }),
        issue('3', { count: 1, metadata: { type: 'SyntaxError' } }),
      ],
      judging,
    );
    const { byType } = summarizeIssues(issues, rangeWindow('30d', NOW), { resolved: 0, complete: true }).summary;
    expect(byType).toContainEqual({ name: 'TypeError', issues: 2, events: 10 });
    expect(byType).toContainEqual({ name: 'SyntaxError', issues: 1, events: 1 });
    expect(byType).toHaveLength(2);
  });
});

describe('the module itself', () => {
  type Exact<A, B> = [A] extends [B] ? ([B] extends [A] ? true : never) : never;

  it('dash-types-013 RuntimeErrorGroup and RuntimeErrorsReport resolve as types, the same ones as ../types', () => {
    const same: [
      Exact<DashboardRuntimeErrorGroup, RuntimeErrorGroup>,
      Exact<DashboardRuntimeErrorsReport, RuntimeErrorsReport>,
    ] = [true, true];
    expect(same).toEqual([true, true]);
  });

  it('dash-types-014 only the four lists exist at run time', () => {
    expect(Object.keys(dashboardTypes).sort()).toEqual(['ANALYTICS_RANGES', 'DIMENSIONS', 'VERCEL_BREAKDOWNS', 'VITALS']);
  });
});
