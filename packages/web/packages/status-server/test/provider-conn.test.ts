import { describe, it, expect, vi, afterEach } from 'vitest';
import { providerConn, enumerateDeployProjects } from '../src/monitor/provider-conn';
import type { Storage } from '../src/storage/ports';
import type { StatusConfig } from '../src/config/port';

type Row = Record<string, unknown>;

function integration(over: Row): Row {
  return {
    id: 'i',
    label: 'l',
    config: {},
    secretRef: null,
    isActive: true,
    createdAt: new Date(0),
    updatedAt: new Date(0),
    ...over,
  };
}

function metaRow(over: Row): Row {
  return {
    platform: 'vercel',
    projectName: 'site',
    domain: 'x.example.com',
    gitRepo: null,
    gitBranch: null,
    rootDirectory: null,
    framework: null,
    ...over,
  };
}

function stubs(opts: { integrations?: Row[] | Error; meta?: Row[] | Error; secrets?: Record<string, string> } = {}) {
  const listIntegrations = vi.fn(async () => {
    if (opts.integrations instanceof Error) throw opts.integrations;
    return opts.integrations ?? [];
  });
  const listProjectMeta = vi.fn(async () => {
    if (opts.meta instanceof Error) throw opts.meta;
    return opts.meta ?? [];
  });
  const storage = { config: { listIntegrations }, deploy: { listProjectMeta } } as unknown as Storage;
  const config = { secrets: opts.secrets ?? {} } as unknown as StatusConfig;
  return { storage, config, listIntegrations, listProjectMeta };
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
});

describe('provider-conn conformance vectors', () => {
  it('status-server-monitor-provider-conn-001: inactive integrations are filtered out before token lookup', async () => {
    const { storage, config } = stubs({
      integrations: [
        integration({ id: 'i1', platform: 'vercel', label: 'v', config: { teamId: 'team_1' }, tokenEnvVar: 'VERCEL_API_TOKEN' }),
        integration({ id: 'i2', platform: 'railway', label: 'r', tokenEnvVar: 'RAILWAY_API_TOKEN', isActive: false }),
      ],
      secrets: { VERCEL_API_TOKEN: 'tok_v', RAILWAY_API_TOKEN: 'tok_r' },
    });
    const conn = await providerConn(storage, config);
    expect(conn.vercel).toEqual({ token: 'tok_v', teamId: 'team_1' });
    expect(conn.railway).toEqual({ token: undefined, projects: undefined });
  });

  it('status-server-monitor-provider-conn-002: tokens come from config.secrets, never process.env', async () => {
    vi.stubEnv('CRUNCHY_API_TOKEN', 'env_tok_c');
    const { storage, config } = stubs({
      integrations: [integration({ platform: 'crunchy', tokenEnvVar: 'CRUNCHY_API_TOKEN' })],
      secrets: { CRUNCHY_API_TOKEN: 'tok_c' },
    });
    const conn = await providerConn(storage, config);
    expect(conn.crunchy.token).toBe('tok_c');
  });

  it('status-server-monitor-provider-conn-003: meta-derived projects surface with no live reads', async () => {
    const { storage, config } = stubs({
      integrations: [],
      meta: [metaRow({ projectName: 'site-a', domain: 'a.example.com' })],
    });
    const result = await enumerateDeployProjects(storage, config);
    expect(result.projects).toHaveLength(1);
    expect(result.projects[0]).toMatchObject({ platform: 'vercel', projectName: 'site-a', domain: 'a.example.com' });
    expect(result.verifiedPlatforms).toEqual([]);
  });

  it('status-server-monitor-provider-conn-004: a rejecting listIntegrations stops before listProjectMeta is read', async () => {
    const err = new Error('integrations unavailable');
    const { storage, config, listProjectMeta } = stubs({ integrations: err });
    await expect(enumerateDeployProjects(storage, config)).rejects.toBe(err);
    expect(listProjectMeta).not.toHaveBeenCalled();
  });

  it('status-server-monitor-provider-conn-005: a rejecting listProjectMeta surfaces after providerConn completed', async () => {
    const err = new Error('meta unavailable');
    const { storage, config, listIntegrations } = stubs({ integrations: [], meta: err });
    await expect(enumerateDeployProjects(storage, config)).rejects.toBe(err);
    expect(listIntegrations).toHaveBeenCalledTimes(1);
  });

  it('status-server-monitor-provider-conn-006: empty storage degrades to an empty enumeration', async () => {
    const { storage, config } = stubs({ integrations: [], meta: [] });
    await expect(enumerateDeployProjects(storage, config)).resolves.toEqual({
      projects: [],
      verifiedPlatforms: [],
      verifiedDomains: [],
    });
  });

  it('status-server-monitor-provider-conn-007: a null tokenEnvVar yields no token even when a secret exists', async () => {
    const { storage, config } = stubs({
      integrations: [integration({ platform: 'vercel', tokenEnvVar: null })],
      secrets: { VERCEL_API_TOKEN: 'tok_v' },
    });
    const conn = await providerConn(storage, config);
    expect(conn.vercel.token).toBeUndefined();
  });

  it('status-server-monitor-provider-conn-008: providerConn does not cache between calls', async () => {
    const { storage, config, listIntegrations } = stubs({ integrations: [], secrets: { VERCEL_API_TOKEN: 'tok_v' } });
    const first = await providerConn(storage, config);
    expect(first.vercel.token).toBeUndefined();
    listIntegrations.mockResolvedValueOnce([integration({ platform: 'vercel', tokenEnvVar: 'VERCEL_API_TOKEN' })]);
    const second = await providerConn(storage, config);
    expect(second.vercel.token).toBe('tok_v');
  });

  it('status-server-monitor-provider-conn-009: providerConn performs no network I/O of its own', async () => {
    const fetchSpy = vi.fn(() => {
      throw new Error('fetch must not be called');
    });
    vi.stubGlobal('fetch', fetchSpy);
    const { storage, config } = stubs({
      integrations: [
        integration({ platform: 'vercel', config: { teamId: 't' }, tokenEnvVar: 'VERCEL_API_TOKEN' }),
        integration({ platform: 'cloudflare', config: { accountId: 'a', workerScripts: ['w'] }, tokenEnvVar: 'CF_TOKEN' }),
      ],
      secrets: { VERCEL_API_TOKEN: 'tok_v', CF_TOKEN: 'tok_cf' },
    });
    const conn = await providerConn(storage, config);
    expect(conn.vercel).toEqual({ token: 'tok_v', teamId: 't' });
    expect(conn.cloudflare).toEqual({ token: 'tok_cf', accountId: 'a', workerScripts: ['w'] });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('status-server-monitor-provider-conn-010: project-meta git and framework fields flow through unchanged', async () => {
    const { storage, config } = stubs({
      integrations: [],
      meta: [
        metaRow({ projectName: 'site-b', domain: 'b.example.com', gitRepo: 'org/repo-b', gitBranch: 'main', framework: 'next' }),
      ],
    });
    const result = await enumerateDeployProjects(storage, config);
    const entry = result.projects.find((p) => p.projectName === 'site-b');
    expect(entry).toMatchObject({ gitRepo: 'org/repo-b', gitBranch: 'main', framework: 'next' });
  });
});
