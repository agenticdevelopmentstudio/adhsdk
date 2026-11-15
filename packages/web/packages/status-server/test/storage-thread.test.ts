import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { MessagePort } from 'node:worker_threads';
import { startStorageThread } from '../src/libsql/storage-thread';
import type { Storage } from '../src/storage/ports';

// The spawn glue alone, against a fake Worker that answers like storage-worker.ts does
// (it serves every attached port through the real createStorageServer); the real thread
// under bare node is covered by storage-thread.int.test.ts.

type Script = { kind: 'ready' } | { kind: 'not-ready'; error: string } | { kind: 'early-error'; message: string };

interface FakeWorkerShape {
  emit(event: string, ...args: unknown[]): boolean;
  readonly threadId: number;
  readonly entry: string;
  readonly options: { workerData?: unknown };
  readonly posted: { msg: { attach: MessagePort }; transfer: unknown[] }[];
  readonly terminate: ReturnType<typeof vi.fn>;
  exit(code: number): void;
}

const h = vi.hoisted(() => ({
  script: { kind: 'ready' } as Script,
  resolved: [] as string[],
  workers: [] as unknown[],
  storage: {} as unknown,
}));

vi.mock('node:module', async (orig) => {
  const actual = await orig<typeof import('node:module')>();
  return {
    ...actual,
    createRequire: () => ({
      resolve: (spec: string): string => {
        h.resolved.push(spec);
        return '/built/libsql/storage-worker.js';
      },
    }),
  };
});

vi.mock('node:worker_threads', async (orig) => {
  const actual = await orig<typeof import('node:worker_threads')>();
  const { EventEmitter } = await import('node:events');
  const remote = await import('../src/storage/remote');
  let nextThread = 1;
  class FakeWorker extends EventEmitter {
    threadId = nextThread++;
    posted: { msg: { attach: MessagePort }; transfer: unknown[] }[] = [];
    served: MessagePort[] = [];
    server: { serve(port: MessagePort): void } | undefined;
    terminate = vi.fn();
    constructor(
      public entry: string,
      public options: { workerData?: unknown },
    ) {
      super();
      h.workers.push(this);
      const script = h.script;
      setImmediate(() => {
        if (script.kind === 'ready') this.emit('message', { ready: true });
        else if (script.kind === 'not-ready') this.emit('message', { ready: false, error: script.error });
        else this.emit('error', new Error(script.message));
      });
    }
    postMessage(msg: { attach: MessagePort }, transfer: unknown[]): void {
      this.posted.push({ msg, transfer });
      this.served.push(msg.attach);
      // One server for the whole worker, as storage-worker.ts has: one queue for every port.
      this.server ??= remote.createStorageServer(h.storage as Storage);
      this.server.serve(msg.attach);
    }
    exit(code: number): void {
      for (const port of this.served) port.close();
      this.emit('exit', code);
    }
  }
  return { ...actual, Worker: FakeWorker };
});

const sleep = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));
const lastWorker = (): FakeWorkerShape => h.workers[h.workers.length - 1] as FakeWorkerShape;

type Db = { rows: Map<string, string>; log: string[] };
let db: Db;

function makeStorage(): unknown {
  db = { rows: new Map(), log: [] };
  return {
    kv: {
      put: async (k: string, v: string): Promise<void> => {
        db.rows.set(k, v);
      },
      get: async (k: string): Promise<string | undefined> => db.rows.get(k),
      slow: async (name: string, ms: number): Promise<void> => {
        db.log.push(`${name}:start`);
        await sleep(ms);
        db.log.push(`${name}:end`);
      },
      fail: async (): Promise<void> => {
        const driver = Object.assign(new Error('UNIQUE constraint failed: users.email'), {
          code: 'SQLITE_CONSTRAINT',
        });
        throw new Error('Failed query: insert into users', { cause: driver });
      },
    },
  };
}

interface Kv {
  put(k: string, v: string): Promise<void>;
  get(k: string): Promise<string | undefined>;
  slow(name: string, ms: number): Promise<void>;
  fail(): Promise<void>;
}
const kv = (s: Storage): Kv => (s as unknown as { kv: Kv }).kv;

beforeEach(() => {
  h.script = { kind: 'ready' };
  h.resolved.length = 0;
  h.workers.length = 0;
  h.storage = makeStorage();
});

afterEach(() => {
  for (const w of h.workers as FakeWorkerShape[]) w.exit(0);
});

describe('startStorageThread', () => {
  it('sthread-001 spawns one worker with the connection as workerData and resolves { storage, connect }', async () => {
    const thread = await startStorageThread({ url: 'file:status.db' }, { onExit: vi.fn() });
    expect(h.workers).toHaveLength(1);
    expect(lastWorker().options.workerData).toEqual({ db: { url: 'file:status.db' } });
    expect(Object.keys(thread).sort()).toEqual(['connect', 'storage']);
    expect(typeof thread.connect).toBe('function');
  });

  it('sthread-002 rejects when the worker replies { ready: false }', async () => {
    h.script = { kind: 'not-ready', error: 'no such table' };
    await expect(startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() })).rejects.toThrow(
      'storage thread failed to start: no such table',
    );
  });

  it('sthread-003 rejects with the error a worker emits before any message', async () => {
    h.script = { kind: 'early-error', message: 'boom' };
    await expect(startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() })).rejects.toThrow('boom');
  });

  it('sthread-004 a failed start leaves the worker alone (no terminate)', async () => {
    h.script = { kind: 'not-ready', error: 'no such table' };
    await expect(startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() })).rejects.toThrow();
    expect(lastWorker().terminate).not.toHaveBeenCalled();
  });

  it('sthread-005 a worker error after start calls onExit with the crash reason', async () => {
    const onExit = vi.fn();
    await startStorageThread({ url: 'file:x.db' }, { onExit });
    expect(onExit).not.toHaveBeenCalled();
    lastWorker().emit('error', new Error('oom'));
    expect(onExit).toHaveBeenCalledTimes(1);
    expect(onExit).toHaveBeenCalledWith('storage thread crashed: oom');
  });

  it('sthread-006 a worker exit after start calls onExit with the exit code', async () => {
    const onExit = vi.fn();
    await startStorageThread({ url: 'file:x.db' }, { onExit });
    lastWorker().emit('exit', 1);
    expect(onExit).toHaveBeenCalledWith('storage thread exited (1)');
  });

  it('sthread-007 a crash that emits error then exit calls onExit twice', async () => {
    const onExit = vi.fn();
    await startStorageThread({ url: 'file:x.db' }, { onExit });
    lastWorker().emit('error', new Error('oom'));
    lastWorker().emit('exit', 1);
    expect(onExit.mock.calls).toEqual([['storage thread crashed: oom'], ['storage thread exited (1)']]);
  });

  it('sthread-008 onExit is not called for a failed start that then exits', async () => {
    h.script = { kind: 'not-ready', error: 'no such table' };
    const onExit = vi.fn();
    await expect(startStorageThread({ url: 'file:x.db' }, { onExit })).rejects.toThrow();
    lastWorker().emit('exit', 1);
    expect(onExit).not.toHaveBeenCalled();
  });

  it('sthread-009 connect() makes a fresh channel each call and transfers one port per attach request', async () => {
    const thread = await startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() });
    const w = lastWorker();
    const before = w.posted.length; // the host thread's own attach
    const a = thread.connect();
    const b = thread.connect();
    expect(a).not.toBe(b);
    expect(w.posted).toHaveLength(before + 2);
    for (const p of w.posted.slice(before)) {
      expect(p.transfer).toHaveLength(1);
      expect(p.transfer[0]).toBe(p.msg.attach);
    }
    // A second thread's client reads what the first wrote.
    const { connectStorage } = await import('../src/storage/remote');
    const other = await connectStorage(b);
    await kv(thread.storage).put('k', 'v');
    expect(await kv(other).get('k')).toBe('v');
    a.close();
  });

  it('sthread-010 calls from two ports run one after the other in arrival order', async () => {
    const thread = await startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() });
    const { connectStorage } = await import('../src/storage/remote');
    const other = await connectStorage(thread.connect());
    await Promise.all([kv(thread.storage).slow('a', 30), kv(other).slow('b', 0)]);
    expect(db.log).toEqual(['a:start', 'a:end', 'b:start', 'b:end']);
  });

  it('sthread-011 storage exposes the listed store methods as functions', async () => {
    const thread = await startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() });
    const k = kv(thread.storage);
    for (const name of ['put', 'get', 'slow', 'fail'] as const) expect(typeof k[name]).toBe('function');
  });

  it('sthread-012 a call after the worker exits rejects with "storage connection closed"', async () => {
    const thread = await startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() });
    lastWorker().exit(1);
    await sleep(20);
    await expect(kv(thread.storage).get('k')).rejects.toThrow('storage connection closed');
  });

  it('sthread-013 a thrown store error keeps message, code and cause for the caller', async () => {
    const thread = await startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() });
    const err = (await kv(thread.storage)
      .fail()
      .catch((e: unknown) => e)) as Error & { cause?: Error & { code?: string } };
    expect(err.message).toBe('Failed query: insert into users');
    expect(err.cause?.message).toBe('UNIQUE constraint failed: users.email');
    expect(err.cause?.code).toBe('SQLITE_CONSTRAINT');
  });

  it('sthread-014 the worker entry is resolved through the package exports to the built file', async () => {
    await startStorageThread({ url: 'file:x.db' }, { onExit: vi.fn() });
    expect(h.resolved).toEqual(['@adh-sdk/status-server/storage-worker']);
    expect(lastWorker().entry).toBe('/built/libsql/storage-worker.js');
    const pkgPath = fileURLToPath(new URL('../package.json', import.meta.url));
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf8')) as { exports: Record<string, { default: string }> };
    expect(pkg.exports['./storage-worker']!.default).toBe('./dist/libsql/storage-worker.js');
  });
});
