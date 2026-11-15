// Conformance vectors for monitor/worker.ts (status-server-monitor-worker-001..015).
// node:worker_threads and every collaborator are replaced, so worker.ts is evaluated in
// this thread as if it had been spawned; the real-thread round trip is worker-boot.int.test.ts.
import { readFileSync } from 'node:fs';
import { EventEmitter } from 'node:events';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

type Reply = { seq: number; ok: boolean; error?: string };

const mocks = vi.hoisted(() => ({
  state: { port: null as unknown, workerData: undefined as unknown },
  openLibsql: vi.fn(),
  tuneDbForConcurrency: vi.fn(),
  createLibsqlStorage: vi.fn(),
  connectStorage: vi.fn(),
  runMonitorCycle: vi.fn(),
  attachCooldownState: vi.fn(),
  attachHogqlLockState: vi.fn(),
}));

vi.mock('node:worker_threads', () => ({
  get parentPort() {
    return mocks.state.port;
  },
  get workerData() {
    return mocks.state.workerData;
  },
}));
vi.mock('../src/libsql/client', () => ({
  openLibsql: mocks.openLibsql,
  tuneDbForConcurrency: mocks.tuneDbForConcurrency,
}));
vi.mock('../src/libsql', () => ({ createLibsqlStorage: mocks.createLibsqlStorage }));
vi.mock('../src/storage/remote', () => ({ connectStorage: mocks.connectStorage }));
vi.mock('../src/monitor/cycle-runner', () => ({ runMonitorCycle: mocks.runMonitorCycle }));
vi.mock('@adh-sdk/deploy-platform/cooldown', () => ({ attachCooldownState: mocks.attachCooldownState }));
vi.mock('../src/telemetry/fetchers/posthog', () => ({ attachHogqlLockState: mocks.attachHogqlLockState }));

class FakePort extends EventEmitter {
  postMessage = vi.fn<(msg: Reply) => void>();
}

const config = { name: 'cfg' } as never;
const storage = { name: 'storage' };
const conn = { url: 'file::memory:' };

/** Evaluate worker.ts afresh with the given thread context; resolves once it has booted. */
async function boot(workerData: unknown, port: FakePort | null = new FakePort()): Promise<FakePort | null> {
  vi.resetModules();
  mocks.state.port = port;
  mocks.state.workerData = workerData;
  await import('../src/monitor/worker');
  return port;
}

/** Post one CycleRequest and wait for its reply. */
async function request(port: FakePort, seq: number, fullSync = false): Promise<Reply> {
  const before = port.postMessage.mock.calls.length;
  port.emit('message', { seq, fullSync });
  await vi.waitFor(() => expect(port.postMessage.mock.calls.length).toBe(before + 1));
  return port.postMessage.mock.calls[before]![0];
}

const source = readFileSync(new URL('../src/monitor/worker.ts', import.meta.url), 'utf8');
/** worker.ts with `//` line comments removed, so a static read sees code, not prose. */
const code = source
  .split('\n')
  .map((l) => l.replace(/\/\/.*$/, ''))
  .join('\n');
const count = (needle: string | RegExp): number =>
  typeof needle === 'string' ? code.split(needle).length - 1 : (code.match(needle) ?? []).length;

beforeEach(() => {
  for (const m of Object.values(mocks)) if (typeof m === 'function') (m as ReturnType<typeof vi.fn>).mockReset();
  mocks.openLibsql.mockReturnValue({ name: 'db' });
  mocks.tuneDbForConcurrency.mockResolvedValue(undefined);
  mocks.createLibsqlStorage.mockReturnValue(storage);
  mocks.runMonitorCycle.mockResolvedValue(undefined);
});
afterEach(() => {
  mocks.state.port = null;
  mocks.state.workerData = undefined;
});

describe('monitor/worker.ts', () => {
  it('status-server-monitor-worker-001: loaded with no parentPort it throws the spawn-via-worker_threads error', async () => {
    await expect(boot({ db: conn, config }, null)).rejects.toThrow(
      'monitor worker must be spawned via worker_threads (see worker-client.ts)',
    );
  });

  it('status-server-monitor-worker-002: no db or storage in workerData throws before openLibsql', async () => {
    await expect(boot({ config })).rejects.toThrow(
      'monitor worker spawned without workerData.storage or workerData.db.url (see MonitorWorkerData)',
    );
    expect(mocks.openLibsql).not.toHaveBeenCalled();
  });

  it('status-server-monitor-worker-003: no config in workerData throws before openLibsql', async () => {
    await expect(boot({ db: conn })).rejects.toThrow('monitor worker spawned without workerData.config (see MonitorWorkerData)');
    expect(mocks.openLibsql).not.toHaveBeenCalled();
  });

  it('status-server-monitor-worker-004: a cycle request is answered { seq, ok: true } with storage and config passed on unchanged', async () => {
    const port = (await boot({ db: conn, config }))!;
    const reply = await request(port, 1, false);
    expect(reply).toEqual({ seq: 1, ok: true });
    expect(mocks.runMonitorCycle).toHaveBeenCalledTimes(1);
    expect(mocks.runMonitorCycle).toHaveBeenCalledWith(storage, { fullSync: false, config });
    await request(port, 2, true);
    expect(mocks.runMonitorCycle).toHaveBeenLastCalledWith(storage, { fullSync: true, config });
  });

  it('status-server-monitor-worker-005: a failing cycle replies { seq, ok: false, error } and the worker keeps serving', async () => {
    const port = (await boot({ db: conn, config }))!;
    mocks.runMonitorCycle.mockRejectedValueOnce(new Error('no such table: health_checks'));
    expect(await request(port, 1)).toEqual({ seq: 1, ok: false, error: 'no such table: health_checks' });
    expect(await request(port, 2)).toEqual({ seq: 2, ok: true });
  });

  it('status-server-monitor-worker-006: workerData without cooldowns boots and completes a cycle', async () => {
    const port = (await boot({ db: conn, config }))!;
    expect(mocks.attachCooldownState).toHaveBeenCalledWith(undefined);
    expect(await request(port, 1)).toEqual({ seq: 1, ok: true });
  });

  it('status-server-monitor-worker-007: storage is built once at boot and reused by every cycle', async () => {
    const port = (await boot({ db: conn, config }))!;
    expect(mocks.createLibsqlStorage).toHaveBeenCalledTimes(1);
    await request(port, 1);
    await request(port, 2);
    expect(mocks.createLibsqlStorage).toHaveBeenCalledTimes(1);
    expect(mocks.openLibsql).toHaveBeenCalledTimes(1);
    expect(mocks.runMonitorCycle.mock.calls.map((c) => c[0])).toEqual([storage, storage]);
  });

  it('status-server-monitor-worker-008: nothing in the file closes the connection or checkpoints the WAL', () => {
    expect(code).not.toMatch(/\bclose\b/);
    expect(code).not.toMatch(/checkpointWal/);
  });

  it('status-server-monitor-worker-009: migrations are not run here — migrateDb is not imported and ../libsql/client supplies only openLibsql, tuneDbForConcurrency and LibsqlConnection', () => {
    expect(code).not.toMatch(/migrateDb/);
    const clientImports = [...source.matchAll(/import\s*\{([^}]*)\}\s*from\s*"\.\.\/libsql\/client"/g)].flatMap((m) =>
      m[1]!.split(',').map((n) => n.trim().replace(/^type\s+/, '')),
    );
    expect(clientImports.sort()).toEqual(['LibsqlConnection', 'openLibsql', 'tuneDbForConcurrency']);
  });

  it('status-server-monitor-worker-010: credentials stay in memory — no console call, and no postMessage argument mentions them', () => {
    expect(code).not.toMatch(/console\./);
    const posts = [...code.matchAll(/port\.postMessage\(([\s\S]*?)\)\s*;/g)].map((m) => m[1]!);
    expect(posts.length).toBeGreaterThan(0);
    for (const body of posts) expect(body).not.toMatch(/\b(conn|config|authToken|credentials|secrets)\b/);
  });

  it('status-server-monitor-worker-011: openLibsql then tuneDbForConcurrency are each called once, inside openOwnStorage, which runs before the listener is registered', () => {
    expect(count(/\bopenLibsql\(/g)).toBe(1);
    expect(count(/\btuneDbForConcurrency\(/g)).toBe(1);
    expect(count('await tuneDbForConcurrency')).toBe(1);
    expect(code.indexOf('openLibsql(')).toBeLessThan(code.indexOf('tuneDbForConcurrency('));
    const callSite = code.indexOf('await openOwnStorage(');
    expect(callSite).toBeGreaterThan(-1);
    expect(callSite).toBeLessThan(code.indexOf('port.on('));
  });

  it('status-server-monitor-worker-012: cooldown state is attached before the single message listener', () => {
    expect(count('port.on("message"')).toBe(1);
    expect(count(/port\.on\(/g)).toBe(1);
    expect(code.indexOf('attachCooldownState(cooldowns)')).toBeGreaterThan(-1);
    expect(code.indexOf('attachCooldownState(cooldowns)')).toBeLessThan(code.indexOf('port.on("message"'));
  });

  it('status-server-monitor-worker-013: workerData is read exactly once, in the single destructuring statement', () => {
    // Identifier uses only (error-message text such as `workerData.db.url` is followed by a dot): the import and the one read.
    expect(count(/\bworkerData\b(?!\.)/g)).toBe(2);
    const reads = [...code.matchAll(/=\s*\(workerData \?\? \{\}\)/g)];
    expect(reads).toHaveLength(1);
    expect(code).toContain(
      'const { db: conn, storage: storagePort, config, cooldowns, hogqlLock } = (workerData ?? {}) as Partial<MonitorWorkerData<LibsqlConnection>>;',
    );
  });

  it('status-server-monitor-worker-014: a non-Error rejection is relayed through String(err)', async () => {
    const port = (await boot({ db: conn, config }))!;
    mocks.runMonitorCycle.mockRejectedValueOnce('boom');
    expect(await request(port, 1)).toEqual({ seq: 1, ok: false, error: 'boom' });
  });

  it('status-server-monitor-worker-015: workerData {} fails the db/storage check, which runs before the config check', async () => {
    await expect(boot({})).rejects.toThrow(
      'monitor worker spawned without workerData.storage or workerData.db.url (see MonitorWorkerData)',
    );
  });
});
