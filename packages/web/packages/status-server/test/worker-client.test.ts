// Conformance vectors for monitor/worker-client.ts (status-server-monitor-worker-client-001..014).
// node:worker_threads is replaced by a scripted fake so no real thread is spawned.
import { readFileSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => {
  // Hoisted so the vi.mock factories below can see it.
  const { EventEmitter: Emitter } = require('node:events') as typeof import('node:events');
  class FakeWorker extends Emitter {
    static instances: FakeWorker[] = [];
    posted: Array<{ seq: number; fullSync: boolean }> = [];
    terminate = vi.fn(async () => 0);
    constructor(public entry: string, public options: { workerData: Record<string, unknown> }) {
      super();
      FakeWorker.instances.push(this);
    }
    postMessage(msg: { seq: number; fullSync: boolean }): void {
      this.posted.push(msg);
    }
    reply(msg: { seq: number; ok: boolean; error?: string }): void {
      this.emit('message', msg);
    }
  }
  return {
    FakeWorker,
    resolve: vi.fn((spec: string) => `/resolved/${spec}`),
    cooldowns: vi.fn(),
    hogql: vi.fn(),
  };
});
const FakeWorker = mocks.FakeWorker;
void EventEmitter;

vi.mock('node:worker_threads', () => ({ Worker: mocks.FakeWorker }));
vi.mock('node:module', () => ({ createRequire: () => ({ resolve: mocks.resolve }) }));
vi.mock('@adh-sdk/deploy-platform/cooldown', () => ({ cooldownState: mocks.cooldowns }));
vi.mock('../src/telemetry/fetchers/posthog', () => ({ hogqlLockState: mocks.hogql }));

import { MonitorWorkerClient } from '../src/monitor/worker-client';

const config = { name: 'cfg' } as never;
const make = (cycleTimeoutMs = 1000) =>
  new MonitorWorkerClient<{ conn: true }>({ cycleTimeoutMs, workerData: { db: { conn: true }, config } });
const last = () => FakeWorker.instances[FakeWorker.instances.length - 1]!;
const pendingSize = (c: unknown) => (c as { pending: Map<number, unknown> }).pending.size;

/** Settle state of a promise without awaiting it forever. */
function track(p: Promise<void>) {
  const state: { status: 'pending' | 'resolved' | 'rejected'; value?: unknown; error?: Error } = { status: 'pending' };
  p.then(
    (value) => { state.status = 'resolved'; state.value = value; },
    (error: Error) => { state.status = 'rejected'; state.error = error; },
  );
  return state;
}
const flush = () => vi.advanceTimersByTimeAsync(0);

beforeEach(() => {
  FakeWorker.instances = [];
  mocks.resolve.mockClear();
  mocks.cooldowns.mockReset().mockReturnValue(new SharedArrayBuffer(8));
  mocks.hogql.mockReset().mockReturnValue(new SharedArrayBuffer(8));
  vi.useFakeTimers();
});
afterEach(() => vi.useRealTimers());

describe('MonitorWorkerClient', () => {
  it('status-server-monitor-worker-client-001: spawns exactly once on the first call and stores the worker', async () => {
    const client = make();
    expect(FakeWorker.instances).toHaveLength(0);
    const p = client.runCycle(false);
    expect(FakeWorker.instances).toHaveLength(1);
    expect((client as unknown as { worker: unknown }).worker).toBe(last());
    last().reply({ seq: 1, ok: true });
    await p;
    const p2 = client.runCycle(false);
    expect(FakeWorker.instances).toHaveLength(1); // reused
    last().reply({ seq: 2, ok: true });
    await p2;
  });

  it('status-server-monitor-worker-client-002: sequence numbers are 1 then 2, one message per call', async () => {
    const client = make();
    const p1 = client.runCycle(true);
    last().reply({ seq: 1, ok: true });
    await p1;
    const p2 = client.runCycle(false);
    last().reply({ seq: 2, ok: true });
    await p2;
    expect(last().posted).toEqual([{ seq: 1, fullSync: true }, { seq: 2, fullSync: false }]);
  });

  it('status-server-monitor-worker-client-003: a timeout rejects, terminates, clears and respawns', async () => {
    const client = make(50);
    const state = track(client.runCycle(false));
    const first = last();
    await vi.advanceTimersByTimeAsync(50);
    expect(state.status).toBe('rejected');
    expect(state.error!.message).toBe('monitor cycle exceeded 50ms — worker terminated; next cycle respawns it');
    expect(first.terminate).toHaveBeenCalledTimes(1);
    expect(pendingSize(client)).toBe(0);
    const p2 = client.runCycle(false);
    expect(FakeWorker.instances).toHaveLength(2);
    expect(last()).not.toBe(first);
    last().reply({ seq: 2, ok: true });
    await p2;
  });

  it('status-server-monitor-worker-client-004: an ok reply resolves with no value', async () => {
    const client = make();
    const state = track(client.runCycle(false));
    last().reply({ seq: 1, ok: true });
    await flush();
    expect(state.status).toBe('resolved');
    expect(state.value).toBeUndefined();
  });

  it('status-server-monitor-worker-client-005: a not-ok reply rejects with its error text', async () => {
    const client = make();
    const state = track(client.runCycle(false));
    last().reply({ seq: 1, ok: false, error: 'boom' });
    await flush();
    expect(state.status).toBe('rejected');
    expect(state.error!.message).toBe('boom');
  });

  it('status-server-monitor-worker-client-006: a not-ok reply without error rejects "monitor cycle failed"', async () => {
    const client = make();
    const state = track(client.runCycle(false));
    last().reply({ seq: 1, ok: false });
    await flush();
    expect(state.status).toBe('rejected');
    expect(state.error!.message).toBe('monitor cycle failed');
  });

  it('status-server-monitor-worker-client-007: a reply for an unknown sequence is ignored', async () => {
    const client = make();
    const state = track(client.runCycle(false));
    expect(() => last().reply({ seq: 999, ok: true })).not.toThrow();
    await flush();
    expect(state.status).toBe('pending');
    expect(pendingSize(client)).toBe(1);
    last().reply({ seq: 1, ok: true });
    await flush();
    expect(state.status).toBe('resolved');
  });

  it('status-server-monitor-worker-client-008: a worker error rejects every in-flight cycle and clears the worker', async () => {
    const client = make();
    const a = track(client.runCycle(false));
    const b = track(client.runCycle(false));
    expect(last().posted.map((m) => m.seq)).toEqual([1, 2]); // no single-flight guard
    last().emit('error', new Error('kaboom'));
    await flush();
    expect(a.status).toBe('rejected');
    expect(b.status).toBe('rejected');
    expect(a.error!.message).toBe('monitor worker crashed: kaboom');
    expect(b.error!.message).toBe('monitor worker crashed: kaboom');
    const p = client.runCycle(false);
    expect(FakeWorker.instances).toHaveLength(2);
    last().reply({ seq: 3, ok: true });
    await p;
  });

  it('status-server-monitor-worker-client-009: exit after a sibling timeout rejects the other pending cycle with the exit message', async () => {
    const client = make(50);
    const a = track(client.runCycle(false));
    await vi.advanceTimersByTimeAsync(30);
    const b = track(client.runCycle(false)); // its own window runs to t=80
    const w = last();
    await vi.advanceTimersByTimeAsync(20); // t=50: seq 1 times out
    expect(a.status).toBe('rejected');
    expect(a.error!.message).toMatch(/^monitor cycle exceeded 50ms/);
    expect(b.status).toBe('pending');
    w.emit('exit', 1);
    await flush();
    expect(b.status).toBe('rejected');
    expect(b.error!.message).toBe('monitor worker exited (1)');
  });

  it('status-server-monitor-worker-client-010: error then exit with nothing pending throws nothing', async () => {
    const client = make();
    const state = track(client.runCycle(false));
    const w = last();
    w.emit('error', new Error('x'));
    await flush();
    expect(state.status).toBe('rejected');
    expect(pendingSize(client)).toBe(0);
    expect(() => w.emit('exit', 1)).not.toThrow();
  });

  it('status-server-monitor-worker-client-011: the entry is resolved via the package exports and handed to Worker', async () => {
    // A real dist round trip needs a built package and a real thread (worker-boot.int.test.ts);
    // here the resolution mechanism is pinned: a bare package specifier, never a relative path.
    const client = make();
    const p = client.runCycle(false);
    expect(mocks.resolve).toHaveBeenCalledWith('@adh-sdk/status-server/worker');
    expect(last().entry).toBe('/resolved/@adh-sdk/status-server/worker');
    last().reply({ seq: 1, ok: true });
    await p;
    const src = readFileSync(new URL('../src/monitor/worker-client.ts', import.meta.url), 'utf8');
    expect(src).not.toMatch(/new Worker\(\s*(new URL|["'`]\.)/);
  });

  it('status-server-monitor-worker-client-012: every respawn attaches the same cooldown buffer', async () => {
    const shared = new SharedArrayBuffer(16);
    mocks.cooldowns.mockReturnValue(shared);
    const client = make();
    for (let i = 0; i < 2; i++) {
      const state = track(client.runCycle(false));
      last().emit('error', new Error('crash'));
      await flush();
      expect(state.status).toBe('rejected');
    }
    expect(FakeWorker.instances).toHaveLength(2);
    expect(FakeWorker.instances[0]!.options.workerData.cooldowns).toBe(shared);
    expect(FakeWorker.instances[1]!.options.workerData.cooldowns).toBe(shared);
    expect(FakeWorker.instances[0]!.options.workerData.db).toEqual({ conn: true });
  });

  it('status-server-monitor-worker-client-013: the connection is an opaque type parameter, no concrete import', () => {
    const src = readFileSync(new URL('../src/monitor/worker-client.ts', import.meta.url), 'utf8');
    expect(src).toMatch(/class MonitorWorkerClient<Conn = unknown>/);
    expect(src).not.toMatch(/from\s+["'][^"']*libsql/);
    // The doc comment names the type; no import line may.
    const imports = src.split('\n').filter((l) => /^import\s/.test(l)).join('\n');
    expect(imports).not.toMatch(/LibsqlConnection/);
  });

  it('status-server-monitor-worker-client-014: a reply clears the timer so no timeout fires later', async () => {
    const client = make(100);
    const state = track(client.runCycle(false));
    await vi.advanceTimersByTimeAsync(10);
    last().reply({ seq: 1, ok: true });
    await vi.advanceTimersByTimeAsync(500);
    expect(state.status).toBe('resolved');
    expect(last().terminate).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });
});
