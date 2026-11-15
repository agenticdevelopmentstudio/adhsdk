import { readFileSync } from 'node:fs';
import { describe, it, expect, vi, afterEach } from 'vitest';
import { MessageChannel, type MessagePort } from 'node:worker_threads';
import { connectStorage, createStorageServer } from '../src/storage/remote';
import type { Storage } from '../src/storage/ports';

// The transport alone, over an in-thread MessageChannel, against a fake Storage: the
// real libSQL one is covered by storage-thread.int.test.ts.
async function over(fake: object): Promise<Storage> {
  const { port1, port2 } = new MessageChannel();
  createStorageServer(fake as Storage).serve(port1);
  return connectStorage(port2);
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe('storage over a MessagePort', () => {
  it('storage-remote-001 round-trips args and results, Dates included', async () => {
    const storage = await over({
      health: { echo: async (a: unknown, b: unknown) => ({ a, b, at: new Date(0) }) },
    });
    const out = await (storage.health as unknown as { echo: (a: unknown, b: unknown) => Promise<unknown> }).echo(1, ['x']);
    expect(out).toEqual({ a: 1, b: ['x'], at: new Date(0) });
  });

  it('storage-remote-002 reaches nested stores like telemetry.errors', async () => {
    const storage = await over({ telemetry: { errors: { load: async () => [{ id: 'e1' }] } } });
    expect(await storage.telemetry.errors.load()).toEqual([{ id: 'e1' }]);
  });

  it('storage-remote-003 keeps an error message, code and cause chain', async () => {
    const storage = await over({
      auth: {
        createUser: async () => {
          const driver = Object.assign(new Error('UNIQUE constraint failed: users.email'), { code: 'SQLITE_CONSTRAINT_UNIQUE' });
          throw new Error('Failed query: insert into users', { cause: driver });
        },
      },
    });
    const err = await storage.auth.createUser({} as never).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(Error);
    expect((err as Error).message).toBe('Failed query: insert into users');
    const cause = (err as Error).cause as Error & { code?: string };
    expect(cause.message).toBe('UNIQUE constraint failed: users.email');
    expect(cause.code).toBe('SQLITE_CONSTRAINT_UNIQUE');
  });

  it('storage-remote-004 runs calls one at a time, in arrival order, across ports', async () => {
    const log: string[] = [];
    const fake = {
      health: {
        slow: async () => {
          log.push('slow:start');
          await sleep(30);
          log.push('slow:end');
        },
        fast: async () => {
          log.push('fast');
        },
      },
    } as unknown as Storage;
    const server = createStorageServer(fake);
    const a = new MessageChannel();
    const b = new MessageChannel();
    server.serve(a.port1);
    server.serve(b.port1);
    const [sa, sb] = await Promise.all([connectStorage(a.port2), connectStorage(b.port2)]);
    type T = { slow: () => Promise<void>; fast: () => Promise<void> };
    await Promise.all([(sa.health as unknown as T).slow(), (sb.health as unknown as T).fast()]);
    expect(log).toEqual(['slow:start', 'slow:end', 'fast']);
    a.port2.close();
    b.port2.close();
  });

  it('storage-remote-005 rejects an argument the structured clone cannot carry', async () => {
    const storage = await over({ maintenance: { snapshotIfDue: async () => ({ created: false }) } });
    await expect(storage.maintenance.snapshotIfDue({ now: () => 1 })).rejects.toThrow();
  });

  it('storage-remote-006 rejects pending calls when the server side closes', async () => {
    const { port1, port2 } = new MessageChannel();
    createStorageServer({ health: { hang: () => new Promise(() => {}) } } as unknown as Storage).serve(port1);
    const storage = await connectStorage(port2);
    const pending = (storage.health as unknown as { hang: () => Promise<void> }).hang();
    port1.close();
    await expect(pending).rejects.toThrow('storage connection closed');
  });
});

type Method = (...a: unknown[]) => Promise<unknown>;
const at = (s: Storage, ...path: string[]): Method => {
  let t: unknown = s;
  for (const k of path) t = (t as Record<string, unknown>)[k];
  return t as Method;
};
const nextMessage = (port: MessagePort): Promise<any> => new Promise((r) => port.once('message', r));
const waitClose = (port: MessagePort): Promise<void> => new Promise((r) => port.once('close', () => r()));

describe('storage over a MessagePort: source behaviour', () => {
  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('storage-remote-007 a throwing call does not stop the queue', async () => {
    const storage = await over({
      h: {
        bad: async () => {
          throw new Error('nope');
        },
        good: async () => 'ok',
      },
    });
    await expect(at(storage, 'h', 'bad')()).rejects.toThrow('nope');
    expect(await at(storage, 'h', 'good')()).toBe('ok');
  });

  it('storage-remote-008 a non-Error throw reaches the caller as an Error', async () => {
    const storage = await over({
      h: {
        bad: async () => {
          throw 'boom';
        },
      },
    });
    const err = (await at(storage, 'h', 'bad')().catch((e: unknown) => e)) as Error;
    expect(err).toBeInstanceOf(Error);
    expect(err.name).toBe('Error');
    expect(err.message).toBe('boom');
  });

  it('storage-remote-009 logs one warning for a call that takes 2,500 ms', async () => {
    vi.useFakeTimers({ toFake: ['Date'] });
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const storage = await over({
      a: {
        b: async () => {
          vi.setSystemTime(Date.now() + 2500);
          return 'done';
        },
      },
    });
    expect(await at(storage, 'a', 'b')()).toBe('done');
    expect(warn).toHaveBeenCalledTimes(1);
    const line = String(warn.mock.calls[0]![0]);
    expect(line).toMatch(/^\[storage\] slow call a\.b \d+ms$/);
    expect(line).toBe('[storage] slow call a.b 2500ms');
  });

  it('storage-remote-010 the first message is the shape of the served storage', async () => {
    const { port1, port2 } = new MessageChannel();
    const first = nextMessage(port2);
    createStorageServer({ a: async () => 1, n: { b: async () => 2, c: 3 }, d: 4 } as unknown as Storage).serve(port1);
    expect(await first).toEqual({ shape: { a: true, n: { b: true } } });
    port1.close();
    port2.close();
  });

  it('storage-remote-011 connectStorage waits for the shape and builds plain stubs', async () => {
    const { port1, port2 } = new MessageChannel();
    let settled = false;
    const connecting = connectStorage(port2).then((s) => {
      settled = true;
      return s;
    });
    await sleep(20);
    expect(settled).toBe(false);
    port1.postMessage({ shape: { a: true, n: { b: true } } });
    const storage = await connecting;
    expect('then' in (storage as object)).toBe(false);
    expect(typeof (storage as unknown as Record<string, unknown>).a).toBe('function');
    expect(typeof at(storage, 'n', 'b')).toBe('function');
    port1.close();
    port2.close();
  });

  it('storage-remote-012 a reply for an unknown id is ignored', async () => {
    const { port1, port2 } = new MessageChannel();
    port1.postMessage({ shape: { a: true } });
    const storage = await connectStorage(port2);
    const sent = nextMessage(port1);
    const result = at(storage, 'a')();
    const call = await sent;
    port1.postMessage({ id: 999, ok: true, value: 1 });
    port1.postMessage({ id: call.id, ok: true, value: 7 });
    expect(await result).toBe(7);
    port1.close();
    port2.close();
  });

  it('storage-remote-013 a result the clone cannot carry rejects with a DataCloneError and the next call runs', async () => {
    const storage = await over({ h: { fn: async () => () => 1, ok: async () => 'fine' } });
    const err = (await at(storage, 'h', 'fn')().catch((e: unknown) => e)) as Error;
    expect(err.name).toBe('DataCloneError');
    expect(await at(storage, 'h', 'ok')()).toBe('fine');
  });

  it('storage-remote-014 a closed served port is dropped and the other port keeps being served', async () => {
    const calls: string[] = [];
    const server = createStorageServer({ h: { ping: async () => (calls.push('ping'), 'pong') } } as unknown as Storage);
    const a = new MessageChannel();
    const b = new MessageChannel();
    server.serve(a.port1);
    server.serve(b.port1);
    const [, sb] = await Promise.all([connectStorage(a.port2), connectStorage(b.port2)]);
    expect(a.port1.listenerCount('message')).toBe(1);
    const closed = waitClose(a.port1);
    a.port2.close();
    await closed;
    expect(a.port1.listenerCount('message')).toBe(0);
    expect(b.port1.listenerCount('message')).toBe(1);
    expect(await at(sb, 'h', 'ping')()).toBe('pong');
    expect(calls).toEqual(['ping']);
    b.port2.close();
  });

  it('storage-remote-015 connectStorage rejects when the port closes before the shape', async () => {
    const { port1, port2 } = new MessageChannel();
    const connecting = connectStorage(port2);
    port1.close();
    await expect(connecting).rejects.toThrow('storage connection closed');
  });

  it('storage-remote-016 the cause chain is cut to five errors', async () => {
    const storage = await over({
      h: {
        deep: async () => {
          let err: Error = new Error('e7');
          for (let i = 6; i >= 1; i--) err = new Error(`e${i}`, { cause: err });
          throw err;
        },
      },
    });
    const err = (await at(storage, 'h', 'deep')().catch((e: unknown) => e)) as Error;
    const chain: string[] = [];
    for (let e: unknown = err; e instanceof Error; e = e.cause) chain.push(e.message);
    expect(chain).toEqual(['e1', 'e2', 'e3', 'e4', 'e5']);
  });

  it('storage-remote-017 a numeric code arrives as a string', async () => {
    const storage = await over({
      h: {
        coded: async () => {
          throw Object.assign(new Error('x'), { code: 5 });
        },
      },
    });
    const err = (await at(storage, 'h', 'coded')().catch((e: unknown) => e)) as Error & { code?: unknown };
    expect(err.code).toBe('5');
  });

  it('storage-remote-018 imports only the Storage type and node:worker_threads types', () => {
    const source = readFileSync(new URL('../src/storage/remote.ts', import.meta.url), 'utf8');
    const imports = source.split('\n').filter((line) => /^import\b/.test(line));
    expect(imports).toEqual([
      "import type { MessagePort } from 'node:worker_threads';",
      "import type { Storage } from './ports';",
    ]);
    const code = source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '');
    expect(code).not.toMatch(/libsql|drizzle|sqlite/i);
  });
});
