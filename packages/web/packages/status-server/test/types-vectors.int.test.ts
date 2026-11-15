// Conformance vectors for monitor/types.ts (types-001..011). The file declares wire shapes
// only, so each vector is exercised through the producer that builds the shape.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import * as schema from '../src/libsql/schema';
import { createApp } from '../src/app';
import { createLibsqlStorage } from '../src/libsql';
import { testDeps } from './helpers/storage';
import { sessionHeaders } from './helpers/auth';
import { freshDb as bootDb } from './helpers/db';
import { testConfig } from './helpers/config';
import type { Db } from '../src/libsql/client';
import { rollupMetricsSql } from '../src/libsql/stores/maintenance-store';
import { providerDeployToDTO, type ProviderDeploy } from '../src/monitor/provider-deploy';
import { uptimePercent, dayStatus } from '../src/monitor/uptime';
import { runIntegrationsCheck, _resetSelfCheckStability } from '../src/monitor/integrations';
import { createSelfCheckStabilizer, CONFIRM_WINDOW_MS } from '../src/monitor/self-check-stability';
import type { IntegrationCheck, ServiceStatusDTO } from '../src/monitor/types';

async function parse(res: Response): Promise<Record<string, any>> {
  return (await res.json()) as Record<string, any>;
}

/** One active group → site → endpoint. Returns the endpoint id (the probe slug). */
async function seedOneEndpoint(db: Db, url: string): Promise<string> {
  const g = (await db.insert(schema.siteGroups).values({ slug: 'g', name: 'G' }).returning())[0]!;
  const s = (await db.insert(schema.monitoredSites).values({ siteGroupId: g.id, slug: 's', name: 'S' }).returning())[0]!;
  const ep = (await db.insert(schema.monitoredEndpoints).values({ siteId: s.id, url }).returning())[0]!;
  return ep.id;
}

const deploy = (o: Partial<ProviderDeploy> = {}): ProviderDeploy => ({
  id: 'vc_1',
  platform: 'vercel',
  projectName: 'proj',
  buildPhase: 'built',
  deployPhase: 'deployed',
  environment: 'production',
  commitHash: null,
  commitMessage: null,
  branch: 'main',
  commitRepo: null,
  url: null,
  createdAt: new Date('2026-07-12T00:00:00.000Z'),
  ...o,
});

describe('wire shapes built by the read routes', () => {
  let db: Db;
  let app: ReturnType<typeof createApp>;
  let slug: string;
  let viewAuth: { Cookie: string };

  beforeEach(async () => {
    db = await bootDb();
    viewAuth = await sessionHeaders(db, 'viewer');
    slug = await seedOneEndpoint(db, 'https://example.com');
    app = createApp(testDeps(db));
  });

  it('types-001: an endpoint with no persisted check is status "unknown" with every other check field an explicit null', async () => {
    const body = await parse(await app.request('/status', { headers: viewAuth }));
    const svc = body.services[0] as ServiceStatusDTO;
    expect(svc.slug).toBe(slug);
    expect(svc.status).toBe('unknown');
    expect(svc.responseTimeMs).toBeNull();
    expect(svc.statusCode).toBeNull();
    expect(svc.error).toBeNull();
    expect(svc.lastCheckedAt).toBeNull();
    for (const k of ['slug', 'group', 'name', 'url', 'environment', 'platform', 'deployProject', 'status', 'responseTimeMs', 'statusCode', 'error', 'lastCheckedAt']) {
      expect(svc, `field ${k} omitted`).toHaveProperty(k);
    }
  });

  it('types-002: a persisted healthy check surfaces as { slug, status: "healthy", responseTimeMs: 42 }', async () => {
    await db.insert(schema.healthChecks).values({ serviceSlug: slug, status: 'healthy', responseTimeMs: 42, statusCode: 200 });
    const body = await parse(await app.request('/status', { headers: viewAuth }));
    expect(body.services[0]).toMatchObject({ slug, status: 'healthy', responseTimeMs: 42, statusCode: 200 });
  });

  it('types-004: two checks (healthy, down) over a 90-day window give days 90, totalChecks 2, uptimePercent 50', async () => {
    await db.insert(schema.healthChecks).values([
      { serviceSlug: slug, status: 'healthy' },
      { serviceSlug: slug, status: 'down' },
    ]);
    await db.run(rollupMetricsSql([slug]));
    const body = await parse(await app.request('/uptime?days=90', { headers: viewAuth }));
    expect(body.days).toBe(90);
    expect(body.services[0]).toMatchObject({ slug, totalChecks: 2, uptimePercent: 50 });
  });

  it('types-005: two checks over 24 hours give service = slug, hours 24, checks of length 2', async () => {
    await db.insert(schema.healthChecks).values([
      { serviceSlug: slug, status: 'healthy', responseTimeMs: 10 },
      { serviceSlug: slug, status: 'degraded', responseTimeMs: 900 },
    ]);
    const body = await parse(await app.request(`/history?slug=${slug}&hours=24`, { headers: viewAuth }));
    expect(body.service).toBe(slug);
    expect(body.hours).toBe(24);
    expect(body.checks).toHaveLength(2);
    for (const c of body.checks) {
      for (const k of ['status', 'responseTimeMs', 'statusCode', 'error', 'checkedAt']) expect(c).toHaveProperty(k);
    }
  });
});

describe('types-003: a zero-check day', () => {
  it('is "healthy" (never "unknown") while its uptime percentage is null', () => {
    const empty = { total: 0, healthy: 0, degraded: 0, down: 0 };
    expect(dayStatus(empty)).toBe('healthy');
    expect(uptimePercent(empty)).toBeNull();
  });
});

describe('deployment record built by providerDeployToDTO', () => {
  afterEach(() => vi.restoreAllMocks());

  it('types-006: an unparseable createdAt is serialized as the epoch, and phaseConfirmedAt falls back the same way', () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const dto = providerDeployToDTO(deploy({ createdAt: new Date('not a date') }), null);
    expect(dto.createdAt).toBe('1970-01-01T00:00:00.000Z');
    expect(dto.phaseConfirmedAt).toBe('1970-01-01T00:00:00.000Z');
    const confirmed = providerDeployToDTO(deploy({ confirmedAt: new Date('also bad') }), null);
    expect(confirmed.phaseConfirmedAt).toBe('1970-01-01T00:00:00.000Z');
  });

  it('types-007: a row with no provider id carries providerProjectId as an explicit null', () => {
    const dto = providerDeployToDTO(deploy(), null);
    expect(dto).toHaveProperty('providerProjectId', null);
    expect(providerDeployToDTO(deploy({ providerProjectId: undefined }), null).providerProjectId).toBeNull();
    expect(providerDeployToDTO(deploy({ providerProjectId: 'prj_1' }), null).providerProjectId).toBe('prj_1');
  });

  it('types-008: a Vercel preview row has tier null whatever its environment field holds', () => {
    expect(providerDeployToDTO(deploy({ environment: null }), null).tier).toBeNull();
    const empty = providerDeployToDTO(deploy({ environment: '' }), null);
    expect(empty.tier).toBeNull();
    expect(empty.environment).toBe('');
    expect(providerDeployToDTO(deploy({ environment: 'production' }), null).tier).not.toBeNull();
  });
});

describe('integration check entries', () => {
  const saved: Record<string, string | undefined> = {};
  const ENV = ['VERCEL_API_TOKEN', 'VERCEL_TEAM_ID', 'CLOUDFLARE_API_TOKEN', 'CLOUDFLARE_ACCOUNT_ID', 'RAILWAY_API_TOKEN', 'GLITCHTIP_URL', 'GLITCHTIP_API_TOKEN', 'GLITCHTIP_ORG', 'POSTHOG_HOST', 'POSTHOG_API_KEY', 'POSTHOG_PROJECT_ID'];

  beforeEach(() => {
    for (const k of ENV) saved[k] = process.env[k];
    for (const k of ENV) delete process.env[k];
    process.env.VERCEL_API_TOKEN = 'v-token';
    process.env.CLOUDFLARE_API_TOKEN = 'cf-token';
    process.env.CLOUDFLARE_ACCOUNT_ID = 'acct';
    process.env.RAILWAY_API_TOKEN = 'r-token';
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    _resetSelfCheckStability();
    for (const k of ENV) {
      if (saved[k] === undefined) delete process.env[k];
      else process.env[k] = saved[k];
    }
  });

  it('types-009: a probe with no HTTP response sets unreachable: true; a check that does not apply omits the field', async () => {
    vi.stubGlobal('fetch', vi.fn(async (): Promise<Response> => {
      throw new Error('This operation was aborted');
    }));
    const storage = createLibsqlStorage(await bootDb());
    const { checks } = await runIntegrationsCheck(storage, testConfig());
    const vercel = checks.find((c) => c.id === 'vercel')!;
    expect(vercel.unreachable).toBe(true);
    const stats = checks.find((c) => c.id === 'stats')!;
    expect(stats).not.toHaveProperty('unreachable');
    expect(stats.unreachable).toBeUndefined();
  });

  it('types-009: a real HTTP error response (401) does not set unreachable', async () => {
    vi.stubGlobal('fetch', vi.fn(async (): Promise<Response> => new Response('nope', { status: 401 })));
    const storage = createLibsqlStorage(await bootDb());
    const { checks } = await runIntegrationsCheck(storage, testConfig());
    const vercel = checks.find((c) => c.id === 'vercel')!;
    expect(vercel.state).toBe('error');
    expect(vercel).not.toHaveProperty('unreachable');
  });

  it('types-010: two providers unreachable in the same confirmed run are both correlated: true; a lone one leaves correlated undefined', () => {
    const down = (id: string): IntegrationCheck => ({ id, label: id, configured: true, ok: false, state: 'error', detail: 'aborted', unreachable: true });
    const t0 = 1_000_000;
    const later = t0 + CONFIRM_WINDOW_MS + 1_000;

    const pair = createSelfCheckStabilizer();
    pair.stabilize([down('cloudflare'), down('posthog')], t0);
    const checks = pair.stabilize([down('cloudflare'), down('posthog')], later);
    expect(checks.find((c) => c.id === 'cloudflare')!.correlated).toBe(true);
    expect(checks.find((c) => c.id === 'posthog')!.correlated).toBe(true);

    const lone = createSelfCheckStabilizer();
    lone.stabilize([down('vercel')], t0);
    const [vercel] = lone.stabilize([down('vercel')], later);
    expect(vercel!.state).toBe('error');
    expect(vercel!.correlated).toBeUndefined();
    expect(vercel).not.toHaveProperty('correlated');
  });

  it('types-011: the integrations response has generatedAt, overall and a checks array containing id "stats"', async () => {
    vi.stubGlobal('fetch', vi.fn(async (): Promise<Response> => new Response('{}', { status: 200 })));
    const storage = createLibsqlStorage(await bootDb());
    const res = await runIntegrationsCheck(storage, testConfig());
    expect(typeof res.generatedAt).toBe('string');
    expect(['ok', 'warn', 'error']).toContain(res.overall);
    expect(Array.isArray(res.checks)).toBe(true);
    expect(res.checks.some((c) => c.id === 'stats')).toBe(true);
    expect(res).toHaveProperty('selfCheck');
  });
});
