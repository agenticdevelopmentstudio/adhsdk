import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { rateLimitedUntil, _resetProviderCooldowns } from '@adh-sdk/deploy-platform/cooldown';
import {
  composeVercelBuildLog,
  composeVercelDeployError,
  fetchVercelBuildLog,
  fetchVercelDeployError,
  fetchVercelDeployments,
} from '../src/monitor/fetch-vercel';

// Conformance vectors for cookbook/status/service/monitor/fetch-vercel.

beforeEach(() => _resetProviderCooldowns());
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const MIN = 60_000;

function dep(uid: string, agoMs: number): Record<string, unknown> {
  return { uid, name: uid, created: Date.now() - agoMs, state: 'READY', target: 'production' };
}

function jsonRes(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), { status, headers });
}

describe('fetchVercelDeployments vectors', () => {
  it('status-server-monitor-fetch-vercel-001: no token is a no-op that never calls fetch', async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);
    expect(await fetchVercelDeployments({})).toEqual({ ok: true, deploys: [] });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('status-server-monitor-fetch-vercel-002: a 429 opens the cooldown and the next call never fetches', async () => {
    const fetchMock = vi.fn(async () => new Response('slow', { status: 429, headers: { 'retry-after': '30' } }));
    vi.stubGlobal('fetch', fetchMock);
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const first = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' });
    expect(first.ok).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const second = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' });
    expect(second.ok).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('status-server-monitor-fetch-vercel-003: pages past the first 100 via pagination.next', async () => {
    const page1 = { deployments: Array.from({ length: 100 }, (_, i) => dep(`a${i}`, 60_000 + i)), pagination: { next: 123 } };
    const page2 = { deployments: Array.from({ length: 35 }, (_, i) => dep(`b${i}`, 200_000 + i)), pagination: { next: null } };
    const urls: string[] = [];
    const pages = [page1, page2];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (url: string) => {
        urls.push(String(url));
        return jsonRes(pages[urls.length - 1]!);
      }),
    );
    const out = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' });
    expect(out.ok).toBe(true);
    expect(out.deploys).toHaveLength(135);
    expect(urls).toHaveLength(2);
    expect(urls[1]).toContain('until=123');
  });

  it('status-server-monitor-fetch-vercel-004: stops once the 30 minute lookback is covered', async () => {
    const page1 = { deployments: [dep('old', 45 * MIN), dep('new', 1 * MIN)], pagination: { next: 999 } };
    const fetchMock = vi.fn(async () => jsonRes(page1));
    vi.stubGlobal('fetch', fetchMock);
    const out = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' });
    expect(out.ok).toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('status-server-monitor-fetch-vercel-005: the overall budget stops endless pagination with ok false', async () => {
    const fetchMock = vi.fn(async () => {
      await new Promise((r) => setTimeout(r, 5));
      return jsonRes({ deployments: [dep('x', 1 * MIN)], pagination: { next: 1 } });
    });
    vi.stubGlobal('fetch', fetchMock);
    const out = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok', overallBudgetMs: 1 });
    expect(out.ok).toBe(false);
    expect(out.deploys.length).toBeGreaterThanOrEqual(0);
  });

  it('status-server-monitor-fetch-vercel-006: a first-page failure is definitive', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('boom', { status: 500 })));
    vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' })).toEqual({ ok: false, deploys: [] });
  });

  it('status-server-monitor-fetch-vercel-007: a later-page failure keeps the pages already fetched', async () => {
    let n = 0;
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => {
        n += 1;
        if (n === 1) return jsonRes({ deployments: [dep('kept', 1 * MIN)], pagination: { next: 42 } });
        return new Response('boom', { status: 500 });
      }),
    );
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const out = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' });
    expect(out.ok).toBe(false);
    expect(out.deploys.map((d) => d.id)).toEqual(['vc_kept']);
  });

  it('status-server-monitor-fetch-vercel-008: a deployment with an unparseable created is dropped and logged', async () => {
    const bad = { uid: 'bad', name: 'bad', created: 'garbage', state: 'READY', target: 'production' };
    const good = dep('good', 1 * MIN);
    vi.stubGlobal('fetch', vi.fn(async () => jsonRes({ deployments: [bad, good], pagination: { next: null } })));
    const errSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    const out = await fetchVercelDeployments({ VERCEL_API_TOKEN: 'tok' });
    expect(out.deploys.map((d) => d.id)).toEqual(['vc_good']);
    const logged = errSpy.mock.calls.map((c) => String(c[0]));
    expect(logged.some((m) => m.includes('has unparseable created') && m.includes('bad'))).toBe(true);
  });
});

describe('composeVercelDeployError vectors', () => {
  it('status-server-monitor-fetch-vercel-009: prefixes the failing build step', () => {
    expect(composeVercelDeployError({ errorMessage: 'Command "next build" exited with 1', errorStep: 'buildStep' })).toBe(
      '[buildStep] Command "next build" exited with 1',
    );
  });

  it('status-server-monitor-fetch-vercel-010: uses the error message alone when no step is named', () => {
    expect(composeVercelDeployError({ errorMessage: 'boom' })).toBe('boom');
  });

  it('status-server-monitor-fetch-vercel-011: falls back to readyStateReason', () => {
    expect(composeVercelDeployError({ readyStateReason: 'deployment blocked' })).toBe('deployment blocked');
  });

  it('status-server-monitor-fetch-vercel-012: no reason at all is null', () => {
    expect(composeVercelDeployError({ errorMessage: '   ', readyStateReason: '' })).toBeNull();
    expect(composeVercelDeployError({})).toBeNull();
  });
});

describe('composeVercelBuildLog vectors', () => {
  it('status-server-monitor-fetch-vercel-013: joins every event that carries text, in order', () => {
    expect(
      composeVercelBuildLog([{ payload: { text: 'installing' } }, { payload: { text: 'building' } }, { payload: { text: 'failed' } }]),
    ).toBe('installing\nbuilding\nfailed');
  });

  it('status-server-monitor-fetch-vercel-014: skips events with no text', () => {
    expect(
      composeVercelBuildLog([
        { payload: { text: 'first' } },
        {},
        { type: 'deployment-state', payload: null },
        { payload: { text: 'second' } },
      ]),
    ).toBe('first\nsecond');
  });

  it('status-server-monitor-fetch-vercel-015: trims each event trailing newline', () => {
    expect(composeVercelBuildLog([{ payload: { text: 'one\n' } }, { payload: { text: 'two\n' } }])).toBe('one\ntwo');
  });

  it('status-server-monitor-fetch-vercel-016: keeps a 500 line log without truncation', () => {
    const events = Array.from({ length: 500 }, (_, i) => ({ payload: { text: `line ${i}` } }));
    const out = composeVercelBuildLog(events);
    expect(out).toBe(events.map((e) => e.payload.text).join('\n'));
    expect(out!.split('\n')).toHaveLength(500);
  });

  it('status-server-monitor-fetch-vercel-017: nothing carrying text is null', () => {
    expect(composeVercelBuildLog([])).toBeNull();
    expect(composeVercelBuildLog([{ payload: { text: '   ' } }, { payload: { text: '' } }, { payload: null }])).toBeNull();
  });
});

describe('network wrappers vectors', () => {
  it('status-server-monitor-fetch-vercel-018: fetchVercelDeployError answers null on 429 (opening the cooldown) and on 500', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    vi.stubGlobal('fetch', vi.fn(async () => new Response('slow', { status: 429, headers: { 'retry-after': '30' } })));
    expect(await fetchVercelDeployError('d1', { VERCEL_API_TOKEN: 'tok' })).toBeNull();
    expect(rateLimitedUntil('vercel')).toBeTruthy();

    _resetProviderCooldowns();
    vi.stubGlobal('fetch', vi.fn(async () => new Response('boom', { status: 500 })));
    expect(await fetchVercelDeployError('d1', { VERCEL_API_TOKEN: 'tok' })).toBeNull();
    expect(rateLimitedUntil('vercel')).toBeNull();
  });

  it('status-server-monitor-fetch-vercel-019: a non-array events body resolves null rather than throwing', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => jsonRes({ error: 'not an array' })));
    await expect(fetchVercelBuildLog('d1', { VERCEL_API_TOKEN: 'tok' })).resolves.toBeNull();
  });
});
