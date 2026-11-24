import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { createClient } from '@libsql/client';
import { drizzle } from 'drizzle-orm/libsql';
import { migrate } from 'drizzle-orm/libsql/migrator';
import * as schema from '../src/libsql/schema';
import type { Db } from '../src/libsql/client';
import { pingHeartbeat } from '../src/monitor/heartbeat';
import { runMonitorCycle } from '../src/monitor/cycle-runner';
import { MIGRATIONS_FOLDER } from '../src/libsql/client';
import { createLibsqlStorage } from '../src/libsql';
import { testConfig } from './helpers/config';

const HEARTBEAT_URL = 'https://hc.example.com/ping/abc';

// The dead-man's switch: every layer of the watchdog chain lives INSIDE the
// container — when the container itself dies (volume, Railway, restart retries
// exhausted) nothing tells anyone. Each successful full sync pings
// HEARTBEAT_URL (healthchecks.io-style); a missed ping alerts externally no
// matter how the monitor died.

async function freshDb(): Promise<Db> {
  const db = drizzle(createClient({ url: ':memory:' }), { schema });
  await migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
  return db;
}

beforeEach(() => {
  vi.stubEnv('HEARTBEAT_URL', 'https://hc.example.com/ping/abc');
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
});

describe('pingHeartbeat', () => {
  it('GETs the configured URL with a bounded signal', async () => {
    const fetchMock = vi.fn(async (_u: string | URL, init?: RequestInit) => {
      expect(init?.signal).toBeTruthy();
      return new Response('ok');
    });
    vi.stubGlobal('fetch', fetchMock);
    await pingHeartbeat(HEARTBEAT_URL);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(String(fetchMock.mock.calls[0]![0])).toBe('https://hc.example.com/ping/abc');
  });

  it('is a no-op without a url and fail-soft on network errors', async () => {
    const fetchMock = vi.fn(async () => {
      throw new Error('down');
    });
    vi.stubGlobal('fetch', fetchMock);
    await pingHeartbeat(null); // no url → no fetch
    expect(fetchMock).not.toHaveBeenCalled();
    await expect(pingHeartbeat(HEARTBEAT_URL)).resolves.toBeUndefined(); // failure logged, never thrown
  });
});

describe('cycle-runner heartbeat wiring', () => {
  it('pings after a successful FULL sync, not on probe-only ticks', async () => {
    const db = await freshDb();
    const storage = createLibsqlStorage(db, { url: ':memory:' });
    const pings: string[] = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (u: string | URL) => {
        pings.push(String(u));
        return new Response('ok');
      }),
    );

    await runMonitorCycle(storage, { fullSync: false, config: testConfig() });
    expect(pings.filter((u) => u.includes('hc.example.com'))).toHaveLength(0);

    await runMonitorCycle(storage, { fullSync: true, config: testConfig() });
    expect(pings.filter((u) => u.includes('hc.example.com'))).toHaveLength(1);
  });

  it('does NOT ping when the sync fails', async () => {
    // Un-migrated DB: the cycle's first read throws — the heartbeat must stay
    // silent so the external monitor sees the miss.
    const db = drizzle(createClient({ url: ':memory:' }), { schema });
    const storage = createLibsqlStorage(db, { url: ':memory:' });
    const pings: string[] = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (u: string | URL) => {
        pings.push(String(u));
        return new Response('ok');
      }),
    );
    await expect(runMonitorCycle(storage, { fullSync: true, config: testConfig() })).rejects.toThrow();
    expect(pings.filter((u) => u.includes('hc.example.com'))).toHaveLength(0);
  });
});

describe('pingHeartbeat response status', () => {
  it('logs a non-2xx check-in instead of treating it as a successful ping', async () => {
    // A typo'd/expired HEARTBEAT_URL answers 404. fetch() RESOLVES, so without a
    // status check every cycle believes it checked in while the external
    // dead-man service never sees a valid ping — the watchdog silently never arms.
    const errors: string[] = [];
    const spy = vi.spyOn(console, 'error').mockImplementation((...args: unknown[]) => {
      errors.push(args.map(String).join(' '));
    });
    vi.stubGlobal('fetch', vi.fn(async () => new Response('not found', { status: 404 })));
    try {
      await pingHeartbeat(HEARTBEAT_URL);
      expect(errors.join('\n')).toMatch(/heartbeat/i);
      expect(errors.join('\n')).toContain('404');
    } finally {
      spy.mockRestore();
    }
  });
});

describe('pingHeartbeat conformance vectors', () => {
  const quiet = () => vi.spyOn(console, 'error').mockImplementation(() => {});
  const logged = (spy: ReturnType<typeof quiet>): string =>
    spy.mock.calls.map((c: unknown[]) => c.map(String).join(' ')).join('\n');

  it('status-server-monitor-heartbeat-001 null url is a no-op that resolves undefined', async () => {
    const fetchMock = vi.fn(async () => {
      throw new Error('down');
    });
    vi.stubGlobal('fetch', fetchMock);
    await expect(pingHeartbeat(null)).resolves.toBeUndefined();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('status-server-monitor-heartbeat-002 empty-string url is a no-op', async () => {
    const fetchMock = vi.fn(async () => {
      throw new Error('down');
    });
    vi.stubGlobal('fetch', fetchMock);
    await expect(pingHeartbeat('')).resolves.toBeUndefined();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('status-server-monitor-heartbeat-003 one GET with the User-Agent header', async () => {
    const fetchMock = vi.fn(async (_u: string | URL, _init?: RequestInit) => new Response('ok'));
    vi.stubGlobal('fetch', fetchMock);
    await pingHeartbeat(HEARTBEAT_URL);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe(HEARTBEAT_URL);
    expect(init!.method).toBe('GET');
    expect((init!.headers as Record<string, string>)['User-Agent']).toBe('AgenticDeveloperHubStatus/1.0');
  });

  it('status-server-monitor-heartbeat-004 the request carries an abort signal', async () => {
    let signal: AbortSignal | null | undefined;
    vi.stubGlobal(
      'fetch',
      vi.fn(async (_u: string | URL, init?: RequestInit) => {
        signal = init?.signal;
        return new Response('ok');
      }),
    );
    await pingHeartbeat(HEARTBEAT_URL);
    expect(signal).toBeTruthy();
  });

  it('status-server-monitor-heartbeat-005 a hung fetch is aborted after 5000ms and resolves undefined', async () => {
    const controller = new AbortController();
    const timeoutSpy = vi.spyOn(AbortSignal, 'timeout').mockReturnValue(controller.signal);
    const errSpy = quiet();
    vi.stubGlobal(
      'fetch',
      vi.fn(
        (_u: string | URL, init?: RequestInit) =>
          new Promise<Response>((_resolve, reject) => {
            init!.signal!.addEventListener('abort', () => reject(new Error('aborted')));
          }),
      ),
    );
    try {
      const pending = pingHeartbeat(HEARTBEAT_URL);
      expect(timeoutSpy).toHaveBeenCalledWith(5000);
      controller.abort();
      await expect(pending).resolves.toBeUndefined();
      expect(logged(errSpy)).toMatch(/heartbeat.*aborted/);
    } finally {
      timeoutSpy.mockRestore();
      errSpy.mockRestore();
    }
  });

  it('status-server-monitor-heartbeat-006 a 404 is logged with its status and never thrown', async () => {
    const errSpy = quiet();
    vi.stubGlobal('fetch', vi.fn(async () => new Response('not found', { status: 404 })));
    try {
      await expect(pingHeartbeat(HEARTBEAT_URL)).resolves.toBeUndefined();
      expect(logged(errSpy)).toMatch(/heartbeat/i);
      expect(logged(errSpy)).toContain('404');
    } finally {
      errSpy.mockRestore();
    }
  });

  it('status-server-monitor-heartbeat-007 a thrown fetch resolves undefined', async () => {
    const errSpy = quiet();
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => {
        throw new Error('down');
      }),
    );
    try {
      await expect(pingHeartbeat(HEARTBEAT_URL)).resolves.toBeUndefined();
      expect(errSpy).toHaveBeenCalledTimes(1);
    } finally {
      errSpy.mockRestore();
    }
  });

  it('status-server-monitor-heartbeat-008 takes one url parameter and never reads the environment', () => {
    expect(pingHeartbeat.length).toBe(1);
    const source = readFileSync(new URL('../src/monitor/heartbeat.ts', import.meta.url), 'utf8');
    const code = source
      .split('\n')
      .filter((line) => !line.trim().startsWith('//'))
      .join('\n');
    expect(code).not.toMatch(/process\.env/);
    expect(code).not.toMatch(/^\s*import\s/m);
  });

  it('status-server-monitor-heartbeat-009 concurrent calls are independent', async () => {
    const URL_A = 'https://hc.example.com/ping/a';
    const URL_B = 'https://hc.example.com/ping/b';
    const seen: string[] = [];
    const errSpy = quiet();
    vi.stubGlobal(
      'fetch',
      vi.fn(async (u: string | URL) => {
        seen.push(String(u));
        if (String(u) === URL_B) throw new Error('b down');
        return new Response('ok');
      }),
    );
    try {
      const results = await Promise.all([pingHeartbeat(URL_A), pingHeartbeat(URL_B)]);
      expect(results).toEqual([undefined, undefined]);
      expect([...seen].sort()).toEqual([URL_A, URL_B]);
      expect(errSpy).toHaveBeenCalledTimes(1);
      expect(logged(errSpy)).toContain('b down');
    } finally {
      errSpy.mockRestore();
    }
  });

  it('status-server-monitor-heartbeat-010 a 200 resolves undefined and logs nothing', async () => {
    const errSpy = quiet();
    vi.stubGlobal('fetch', vi.fn(async () => new Response('ok', { status: 200 })));
    try {
      await expect(pingHeartbeat(HEARTBEAT_URL)).resolves.toBeUndefined();
      expect(errSpy).not.toHaveBeenCalled();
    } finally {
      errSpy.mockRestore();
    }
  });
});
