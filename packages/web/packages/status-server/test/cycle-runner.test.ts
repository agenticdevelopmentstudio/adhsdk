import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { runMonitorCycle } from '../src/monitor/cycle-runner';
import { runCycle } from '../src/monitor/sync';
import { fetchPeers } from '../src/peers/fetch';
import { collectTelemetry } from '../src/telemetry/server';
import { pingHeartbeat } from '../src/monitor/heartbeat';
import { flushAlerts, notifyIssueAlert, _resetAlerts } from '../src/monitor/alerts';
import type { StatusConfig } from '../src/config/port';
import type { Storage } from '../src/storage/ports';

vi.mock('../src/monitor/sync', () => ({ runCycle: vi.fn() }));
vi.mock('../src/peers/fetch', () => ({ fetchPeers: vi.fn() }));
vi.mock('../src/telemetry/server', () => ({ collectTelemetry: vi.fn() }));
vi.mock('../src/monitor/heartbeat', () => ({ pingHeartbeat: vi.fn() }));
// Real alert queue + flush (vector 004 delivers a real webhook POST); wrapped so calls are observable.
vi.mock('../src/monitor/alerts', async () => {
  const actual = await vi.importActual<typeof import('../src/monitor/alerts')>('../src/monitor/alerts');
  return { ...actual, flushAlerts: vi.fn(actual.flushAlerts) };
});

const runCycleMock = vi.mocked(runCycle);
const fetchPeersMock = vi.mocked(fetchPeers);
const telemetryMock = vi.mocked(collectTelemetry);
const pingMock = vi.mocked(pingHeartbeat);
const flushMock = vi.mocked(flushAlerts);

const runMaintenance = vi.fn();
const snapshotIfDue = vi.fn();
const storage = { maintenance: { runMaintenance, snapshotIfDue } } as unknown as Storage;

const HEARTBEAT = 'https://hc.example.com/ping/abc';
const mkConfig = (over: Partial<StatusConfig> = {}): StatusConfig =>
  ({ alertWebhookUrl: null, heartbeatUrl: HEARTBEAT, ...over }) as StatusConfig;

let log: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  runCycleMock.mockReset().mockResolvedValue(undefined as never);
  fetchPeersMock.mockReset().mockResolvedValue(undefined as never);
  telemetryMock.mockReset().mockResolvedValue(undefined as never);
  pingMock.mockReset().mockResolvedValue(undefined);
  flushMock.mockClear();
  runMaintenance.mockReset().mockResolvedValue({ deleted: 0, done: true });
  snapshotIfDue.mockReset().mockResolvedValue({ created: false });
  log = vi.spyOn(console, 'log').mockImplementation(() => {});
  _resetAlerts();
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  _resetAlerts();
});

describe('cycle-runner conformance vectors', () => {
  it('status-server-monitor-cycle-runner-001 probe-only tick skips deploys and never pings', async () => {
    await runMonitorCycle(storage, { fullSync: false, config: mkConfig() });
    expect(runCycleMock).toHaveBeenCalledTimes(1);
    expect(runCycleMock.mock.calls[0]![2]).toEqual({ skipDeploys: true });
    expect(pingMock).not.toHaveBeenCalled();
    expect(fetchPeersMock).not.toHaveBeenCalled();
    expect(runMaintenance).not.toHaveBeenCalled();
  });

  it('status-server-monitor-cycle-runner-002 full sync runs deploys, then pings once', async () => {
    await runMonitorCycle(storage, { fullSync: true, config: mkConfig() });
    expect(runCycleMock.mock.calls[0]![2]).toEqual({ skipDeploys: false });
    expect(pingMock).toHaveBeenCalledTimes(1);
    expect(pingMock).toHaveBeenCalledWith(HEARTBEAT);
  });

  it('status-server-monitor-cycle-runner-003 a failing core sweep rejects and skips the full-sync phase', async () => {
    runCycleMock.mockRejectedValue(new Error('no such table'));
    await expect(runMonitorCycle(storage, { fullSync: true, config: mkConfig() })).rejects.toThrow('no such table');
    expect(pingMock).not.toHaveBeenCalled();
    expect(fetchPeersMock).not.toHaveBeenCalled();
    expect(telemetryMock).not.toHaveBeenCalled();
    expect(runMaintenance).not.toHaveBeenCalled();
  });

  it('status-server-monitor-cycle-runner-004 alerts flush in the finally even when the sweep rejects', async () => {
    const posts: { url: string; method?: string }[] = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (u: string | URL, init?: RequestInit) => {
        const post: { url: string; method?: string } = { url: String(u) };
        if (init?.method) post.method = init.method;
        posts.push(post);
        return new Response('ok');
      }),
    );
    runCycleMock.mockRejectedValue(new Error('boom'));
    notifyIssueAlert({ kind: 'opened', target: 't', name: 'site', environment: null, state: 'down', detail: null });
    const config = mkConfig({ alertWebhookUrl: 'https://hooks.example/x' });
    await expect(runMonitorCycle(storage, { fullSync: true, config })).rejects.toThrow('boom');
    expect(flushMock).toHaveBeenCalledTimes(1);
    expect(posts).toEqual([{ url: 'https://hooks.example/x', method: 'POST' }]);
  });

  it('status-server-monitor-cycle-runner-005 logs the pruned count without a suffix when done', async () => {
    runMaintenance.mockResolvedValue({ deleted: 42, done: true });
    await runMonitorCycle(storage, { fullSync: true, config: mkConfig() });
    expect(log).toHaveBeenCalledWith('[maintenance] pruned 42 retention rows');
  });

  it('status-server-monitor-cycle-runner-006 appends "more next cycle" when not done', async () => {
    runMaintenance.mockResolvedValue({ deleted: 100000, done: false });
    await runMonitorCycle(storage, { fullSync: true, config: mkConfig() });
    expect(log).toHaveBeenCalledWith('[maintenance] pruned 100000 retention rows — more next cycle');
  });

  it('status-server-monitor-cycle-runner-007 logs nothing when nothing was deleted', async () => {
    runMaintenance.mockResolvedValue({ deleted: 0, done: true });
    await runMonitorCycle(storage, { fullSync: true, config: mkConfig() });
    const maintenanceLogs = log.mock.calls.filter((c: unknown[]) => String(c[0]).startsWith('[maintenance]'));
    expect(maintenanceLogs).toEqual([]);
  });

  it('status-server-monitor-cycle-runner-008 a maintenance failure aborts the snapshot and the heartbeat', async () => {
    runMaintenance.mockRejectedValue(new Error('disk full'));
    await expect(runMonitorCycle(storage, { fullSync: true, config: mkConfig() })).rejects.toThrow('disk full');
    expect(snapshotIfDue).not.toHaveBeenCalled();
    expect(pingMock).not.toHaveBeenCalled();
  });

  it('status-server-monitor-cycle-runner-009 threads config unchanged to every collaborator', async () => {
    const config = mkConfig({ alertWebhookUrl: 'https://hooks.example/x', heartbeatUrl: null });
    await runMonitorCycle(storage, { fullSync: true, config });
    expect(runCycleMock.mock.calls[0]![1]).toBe(config);
    expect(telemetryMock.mock.calls[0]![1]).toBe(config);
    expect(flushMock).toHaveBeenCalledTimes(1);
    expect(flushMock.mock.calls[0]).toEqual(['https://hooks.example/x']);
    expect(pingMock).toHaveBeenCalledTimes(1);
    expect(pingMock.mock.calls[0]).toEqual([null]);
  });

  it('status-server-monitor-cycle-runner-010 maintenance calls take no arguments', async () => {
    await runMonitorCycle(storage, { fullSync: true, config: mkConfig() });
    expect(runMaintenance).toHaveBeenCalledTimes(1);
    expect(runMaintenance.mock.calls[0]).toEqual([]);
    expect(snapshotIfDue).toHaveBeenCalledTimes(1);
    expect(snapshotIfDue.mock.calls[0]).toEqual([]);
  });

  it('status-server-monitor-cycle-runner-011 resolves void on success, with every step strictly ordered', async () => {
    const order: string[] = [];
    const step = (name: string) => async (): Promise<void> => {
      order.push(`${name}:start`);
      await Promise.resolve();
      order.push(`${name}:end`);
    };
    runCycleMock.mockImplementation(step('runCycle') as never);
    flushMock.mockImplementationOnce(step('flushAlerts'));
    fetchPeersMock.mockImplementation(step('fetchPeers') as never);
    telemetryMock.mockImplementation(step('collectTelemetry') as never);
    runMaintenance.mockImplementation(async (): Promise<{ deleted: number; done: boolean }> => {
      await step('runMaintenance')();
      return { deleted: 0, done: true };
    });
    snapshotIfDue.mockImplementation(async (): Promise<{ created: boolean }> => {
      await step('snapshotIfDue')();
      return { created: false };
    });
    pingMock.mockImplementation(step('pingHeartbeat'));

    const result = await runMonitorCycle(storage, { fullSync: true, config: mkConfig() });
    expect(result).toBeUndefined();
    const names = ['runCycle', 'flushAlerts', 'fetchPeers', 'collectTelemetry', 'runMaintenance', 'snapshotIfDue', 'pingHeartbeat'];
    expect(order).toEqual(names.flatMap((n) => [`${n}:start`, `${n}:end`]));
  });

  it('status-server-monitor-cycle-runner-012 imports no connection-opening symbol', () => {
    const src = readFileSync(fileURLToPath(new URL('../src/monitor/cycle-runner.ts', import.meta.url)), 'utf8');
    const imports = src.split('\n').filter((l) => /^import\b/.test(l));
    expect(imports.length).toBeGreaterThan(0);
    for (const l of imports) {
      expect(l).not.toMatch(/openLibsql|LibsqlConnection|createLibsqlStorage/);
    }
    const modules = imports.map((l) => /from\s+["']([^"']+)["']/.exec(l)![1]);
    expect(modules).toEqual([
      '../config/port',
      '../storage/ports',
      './sync',
      '../peers/fetch',
      '../telemetry/server',
      './heartbeat',
      './alerts',
    ]);
  });
});
