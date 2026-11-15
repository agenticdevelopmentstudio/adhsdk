import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { attachCooldownState, noteRateLimited } from '@adh-sdk/deploy-platform/cooldown';
import type { ProviderConn } from '@adh-sdk/deploy-platform/conn';
import type { Storage } from '../src/storage/ports';

vi.mock('../src/monitor/fetch-vercel', () => ({ fetchVercelDeployError: vi.fn() }));
vi.mock('../src/monitor/fetch-railway', () => ({ fetchRailwayBuildLogTail: vi.fn() }));

import { enrichDeployErrors } from '../src/monitor/enrich-deploy-errors';
import { fetchVercelDeployError } from '../src/monitor/fetch-vercel';
import { fetchRailwayBuildLogTail } from '../src/monitor/fetch-railway';

const vercelFetch = vi.mocked(fetchVercelDeployError);
const railwayFetch = vi.mocked(fetchRailwayBuildLogTail);

function conn(over: { vercel?: string; railway?: string } = {}): ProviderConn {
  return {
    vercel: { token: over.vercel, teamId: undefined },
    cloudflare: { token: undefined, accountId: undefined, workerScripts: undefined },
    railway: { token: over.railway, projects: undefined },
    crunchy: { token: undefined },
  } as ProviderConn;
}

function makeStorage(rows: Array<{ id: string; platform: string }> | Error) {
  const listFailedWithoutError = vi.fn(async () => {
    if (rows instanceof Error) throw rows;
    return rows;
  });
  const setErrorText = vi.fn(async () => {});
  const storage = { deploy: { listFailedWithoutError, setErrorText } } as unknown as Storage;
  return { storage, listFailedWithoutError, setErrorText };
}

let errorSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  attachCooldownState(new SharedArrayBuffer(4 * 8)); // fresh, empty cooldown registry
  vercelFetch.mockReset();
  railwayFetch.mockReset();
  errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

describe('enrichDeployErrors conformance vectors', () => {
  it('status-server-monitor-enrich-deploy-errors-001: no token on either platform short-circuits', async () => {
    const { storage, listFailedWithoutError, setErrorText } = makeStorage([]);
    await expect(enrichDeployErrors(storage, conn())).resolves.toBeUndefined();
    expect(listFailedWithoutError).not.toHaveBeenCalled();
    expect(setErrorText).not.toHaveBeenCalled();
  });

  it('status-server-monitor-enrich-deploy-errors-002: a cooling-down provider is filtered out before the query', async () => {
    noteRateLimited('vercel', '300');
    const { storage, listFailedWithoutError } = makeStorage([]);
    await enrichDeployErrors(storage, conn({ vercel: 'tok' }));
    expect(listFailedWithoutError).not.toHaveBeenCalled();
  });

  it('status-server-monitor-enrich-deploy-errors-003: a failing candidate query is logged and swallowed', async () => {
    const err = new Error('db down');
    const { storage, setErrorText } = makeStorage(err);
    await expect(enrichDeployErrors(storage, conn({ vercel: 'tok' }))).resolves.toBeUndefined();
    expect(errorSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy.mock.calls[0]![0]).toBe('[enrich] failed-deploy query failed:');
    expect(setErrorText).not.toHaveBeenCalled();
  });

  it('status-server-monitor-enrich-deploy-errors-004: no candidates means no fetch and no write', async () => {
    const { storage, setErrorText } = makeStorage([]);
    await enrichDeployErrors(storage, conn({ vercel: 'tok' }));
    expect(vercelFetch).not.toHaveBeenCalled();
    expect(railwayFetch).not.toHaveBeenCalled();
    expect(setErrorText).not.toHaveBeenCalled();
  });

  it('status-server-monitor-enrich-deploy-errors-005: a Vercel row is fetched without its vc_ prefix and its text persisted', async () => {
    vercelFetch.mockResolvedValue('Command "next build" exited with 1');
    const { storage, listFailedWithoutError, setErrorText } = makeStorage([{ id: 'vc_abc123', platform: 'vercel' }]);
    await enrichDeployErrors(storage, conn({ vercel: 'tok' }));
    expect(listFailedWithoutError).toHaveBeenCalledWith(expect.objectContaining({ platforms: ['vercel'], limit: 8 }));
    expect(vercelFetch.mock.calls[0]![0]).toBe('abc123');
    expect(setErrorText).toHaveBeenCalledTimes(1);
    expect(setErrorText).toHaveBeenCalledWith('vc_abc123', 'Command "next build" exited with 1');
  });

  it('status-server-monitor-enrich-deploy-errors-006: a Railway row is fetched without its ry_ prefix and its text persisted', async () => {
    railwayFetch.mockResolvedValue('error: build failed');
    const { storage, setErrorText } = makeStorage([{ id: 'ry_xyz789', platform: 'railway' }]);
    await enrichDeployErrors(storage, conn({ railway: 'tok' }));
    expect(railwayFetch.mock.calls[0]![0]).toBe('xyz789');
    expect(setErrorText).toHaveBeenCalledTimes(1);
    expect(setErrorText).toHaveBeenCalledWith('ry_xyz789', 'error: build failed');
  });

  it('status-server-monitor-enrich-deploy-errors-007: a null fetch result persists nothing and logs nothing', async () => {
    vercelFetch.mockResolvedValue(null);
    const { storage, setErrorText } = makeStorage([{ id: 'vc_def456', platform: 'vercel' }]);
    await enrichDeployErrors(storage, conn({ vercel: 'tok' }));
    expect(setErrorText).not.toHaveBeenCalled();
    expect(errorSpy).not.toHaveBeenCalled();
  });

  it('status-server-monitor-enrich-deploy-errors-008: a per-row fetch failure is logged and swallowed', async () => {
    railwayFetch.mockRejectedValue(new Error('network down'));
    const { storage, setErrorText } = makeStorage([{ id: 'ry_bad', platform: 'railway' }]);
    await expect(enrichDeployErrors(storage, conn({ railway: 'tok' }))).resolves.toBeUndefined();
    expect(errorSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy.mock.calls[0]![0]).toBe('[enrich] ry_bad error fetch/store failed:');
    expect(setErrorText).not.toHaveBeenCalled();
  });

  it('status-server-monitor-enrich-deploy-errors-009: at most four fetches are in flight at once', async () => {
    let inFlight = 0;
    let peak = 0;
    vercelFetch.mockImplementation(async () => {
      inFlight++;
      peak = Math.max(peak, inFlight);
      await new Promise((r) => setTimeout(r, 10));
      inFlight--;
      return 'boom';
    });
    const rows = Array.from({ length: 8 }, (_, i) => ({ id: `vc_${i}`, platform: 'vercel' }));
    const { storage, setErrorText } = makeStorage(rows);
    await enrichDeployErrors(storage, conn({ vercel: 'tok' }));
    expect(vercelFetch).toHaveBeenCalledTimes(8);
    expect(setErrorText).toHaveBeenCalledTimes(8);
    expect(peak).toBeGreaterThan(1);
    expect(peak).toBeLessThanOrEqual(4);
  });

  it('status-server-monitor-enrich-deploy-errors-010: the per-call signal aborts at 8000ms and the call resolves', async () => {
    vi.useFakeTimers();
    let signal: AbortSignal | undefined;
    railwayFetch.mockImplementation(
      (_id: string, _token: string, s?: AbortSignal) =>
        new Promise<string | null>((_resolve, reject) => {
          signal = s;
          s?.addEventListener('abort', () => reject(new Error('aborted')));
        }),
    );
    const { storage, setErrorText } = makeStorage([{ id: 'ry_slow', platform: 'railway' }]);
    const done = enrichDeployErrors(storage, conn({ railway: 'tok' }));
    await vi.advanceTimersByTimeAsync(7_999);
    expect(signal?.aborted).toBe(false);
    await vi.advanceTimersByTimeAsync(1);
    expect(signal?.aborted).toBe(true);
    await expect(done).resolves.toBeUndefined();
    expect(errorSpy.mock.calls[0]![0]).toBe('[enrich] ry_slow error fetch/store failed:');
    expect(setErrorText).not.toHaveBeenCalled();
  });
});
