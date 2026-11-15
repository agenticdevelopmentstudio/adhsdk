import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { EventEmitter } from 'node:events';
import { existsSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { MessageChannel, type MessagePort } from 'node:worker_threads';
import { connectStorage } from '../src/storage/remote';
import { isUniqueViolation } from '../src/storage/ports';
import type { Storage } from '../src/storage/ports';

// storage-worker.ts imported in-process with a stand-in `parentPort` / `workerData`
// (the module is glue that runs at import time), over a real libSQL file in a tmp dir.
// The real thread under bare node, plus a monitor cycle through it, is covered by
// storage-thread.int.test.ts.

class FakeParentPort extends EventEmitter {
  postMessage = vi.fn();
}

const h = vi.hoisted(() => ({
  parentPort: null as unknown,
  workerData: undefined as unknown,
}));

vi.mock('node:worker_threads', async (orig) => {
  const actual = await orig<typeof import('node:worker_threads')>();
  return {
    ...actual,
    get parentPort() {
      return h.parentPort;
    },
    get workerData() {
      return h.workerData;
    },
  };
});

let parent: FakeParentPort;
const sleep = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));
const freshUrl = (): string => `file:${join(mkdtempSync(join(tmpdir(), 'storage-worker-')), 'status.db')}`;

async function load(): Promise<void> {
  await import('../src/libsql/storage-worker');
}

/** Post an attach request and connect a client to the other end. */
async function attach(): Promise<Storage> {
  const { port1, port2 } = new MessageChannel();
  parent.emit('message', { attach: port1 });
  return connectStorage(port2);
}

const newUser = { email: 'a@b.com', displayName: 'A', role: 'viewer' } as const;

beforeEach(() => {
  vi.resetModules();
  parent = new FakeParentPort();
  h.parentPort = parent;
  h.workerData = { db: { url: freshUrl() } };
});

afterEach(() => {
  vi.doUnmock('../src/libsql/client');
  vi.restoreAllMocks();
});

describe('storage worker', () => {
  it('status-server-libsql-storage-worker-001 migrates, replies ready, and serves two attached ports', async () => {
    const url = (h.workerData as { db: { url: string } }).db.url;
    await load();
    expect(parent.postMessage).toHaveBeenCalledTimes(1);
    expect(parent.postMessage).toHaveBeenCalledWith({ ready: true });
    expect(existsSync(url.slice('file:'.length))).toBe(true);
    const a = await attach(); // resolving connectStorage means the port got its { shape } hello
    const b = await attach();
    const user = await a.auth.createUser({ ...newUser });
    expect(user.createdAt).toBeInstanceOf(Date);
    expect((await b.auth.findUserByEmail('a@b.com'))?.id).toBe(user.id);
  });

  it('status-server-libsql-storage-worker-002 a duplicate insert reaches the caller as a unique violation', async () => {
    await load();
    const a = await attach();
    await a.auth.createUser({ ...newUser });
    const dup = (await a.auth.createUser({ ...newUser }).catch((e: unknown) => e)) as Error;
    expect(dup).toBeInstanceOf(Error);
    expect(isUniqueViolation(dup)).toBe(true);
  });

  it.skip('status-server-libsql-storage-worker-003 a monitor cycle runs against the worker with no thread exit', () => {
    // Needs the BUILT dist worker spawned under bare node by MonitorWorkerClient; covered by storage-thread.int.test.ts.
  });

  it('status-server-libsql-storage-worker-004 workerData without a db url throws at import and posts nothing', async () => {
    h.workerData = {};
    await expect(load()).rejects.toThrow('storage worker spawned without workerData.db.url (see StorageWorkerData)');
    expect(parent.postMessage).not.toHaveBeenCalled();
  });

  it('status-server-libsql-storage-worker-005 an empty db url throws the same error', async () => {
    h.workerData = { db: { url: '' } };
    await expect(load()).rejects.toThrow('storage worker spawned without workerData.db.url (see StorageWorkerData)');
    expect(parent.postMessage).not.toHaveBeenCalled();
  });

  it('status-server-libsql-storage-worker-006 importing off a worker thread throws', async () => {
    h.parentPort = null;
    await expect(load()).rejects.toThrow('storage worker must be spawned via worker_threads (see storage-thread.ts)');
  });

  it('status-server-libsql-storage-worker-007 a startup failure replies { ready: false, error } and serves nothing', async () => {
    h.workerData = { db: { url: 'file:/nonexistent-dir/x/status.db' } };
    const exit = vi.spyOn(process, 'exit').mockImplementation((() => undefined) as never);
    await load();
    expect(parent.postMessage).toHaveBeenCalledTimes(1);
    const reply = parent.postMessage.mock.calls[0]![0] as { ready: boolean; error: string };
    expect(reply.ready).toBe(false);
    expect(typeof reply.error).toBe('string');
    expect(reply.error.length).toBeGreaterThan(0);
    // No attach listener was registered, so a later attach request gets no hello.
    const { port1, port2 } = new MessageChannel();
    const received: unknown[] = [];
    port2.on('message', (m: unknown) => received.push(m));
    parent.emit('message', { attach: port1 as MessagePort });
    await sleep(50);
    expect(received).toEqual([]);
    expect(exit).not.toHaveBeenCalled();
    port2.close();
  });

  it('status-server-libsql-storage-worker-008 a non-Error startup throw is reported as its string', async () => {
    const actual = await vi.importActual<typeof import('../src/libsql/client')>('../src/libsql/client');
    vi.doMock('../src/libsql/client', () => ({
      ...actual,
      openLibsql: () => {
        throw 'boom';
      },
    }));
    await load();
    expect(parent.postMessage).toHaveBeenCalledWith({ ready: false, error: 'boom' });
  });

  it('status-server-libsql-storage-worker-009 calls from two ports complete in arrival order', async () => {
    await load();
    const a = await attach();
    const b = await attach();
    // Sent back to back with no await between: b's read can only see the row if a's insert finished first.
    const [created, found] = await Promise.all([a.auth.createUser({ ...newUser }), b.auth.findUserByEmail('a@b.com')]);
    expect(found?.id).toBe(created.id);
  });
});
