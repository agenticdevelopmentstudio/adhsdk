import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock node:dns so the DNS-resolution checks are deterministic (the real probe
// does a live lookup). Hoisted so the mock factory can reference the spies.
const { resolve4, resolve6, resolveCname } = vi.hoisted(() => ({
  resolve4: vi.fn<(h: string) => Promise<string[]>>(),
  resolve6: vi.fn<(h: string) => Promise<string[]>>(),
  resolveCname: vi.fn<(h: string) => Promise<string[]>>(),
}));
vi.mock('node:dns', () => ({ promises: { resolve4, resolve6, resolveCname } }));

// Spy on `classify` while keeping its real behaviour, so vector 010 can see its input.
vi.mock('../src/monitor/health', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../src/monitor/health')>();
  return { ...actual, classify: vi.fn(actual.classify) };
});

import { probe, probeEndpoints, PROBE_BODY_MAX_BYTES } from '../src/monitor/probe';
import { classify } from '../src/monitor/health';
import type { ConfiguredEndpoint } from '../src/storage/ports';

// Base endpoint shape — fields required by ConfiguredEndpoint.
const base: ConfiguredEndpoint = {
  slug: 'svc',
  group: 'test',
  name: 'Test Service',
  environment: null,
  url: 'https://example.com',
  kind: 'http',
  platform: null,
  deployProject: null,
  expectedStatus: 200,
};

beforeEach(() => {
  // Default: the host resolves via an A record, and fetch answers 200.
  resolve4.mockResolvedValue(['93.184.216.34']);
  resolve6.mockResolvedValue([]);
  resolveCname.mockResolvedValue([]);
  vi.stubGlobal('fetch', vi.fn(async () => new Response('ok', { status: 200 })));
});

afterEach(() => {
  vi.unstubAllGlobals();
  resolve4.mockReset();
  resolve6.mockReset();
  resolveCname.mockReset();
});

describe('probe', () => {
  it('status-server-monitor-probe-001: classifies a healthy endpoint', async () => {
    const result = await probe(base);
    expect(result.status).toBe('healthy');
    expect(result.statusCode).toBe(200);
    expect(result.dnsOk).toBe(true);
    expect(result.error).toBeNull();
    expect(result.slug).toBe('svc');
  });

  it('status-server-monitor-probe-002: marks an endpoint down on a 500', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('err', { status: 500 })));
    const result = await probe(base);
    expect(result.status).toBe('down');
    expect(result.statusCode).toBe(500);
    expect(result.dnsOk).toBe(true);
    expect(result.error).toContain('500');
  });

  it('status-server-monitor-probe-003: treats a CNAME-only host as resolvable when all record checks are on (default)', async () => {
    resolve4.mockResolvedValue([]);
    resolve6.mockResolvedValue([]);
    resolveCname.mockResolvedValue(['cname.vercel-dns.com']);
    const result = await probe(base);
    expect(result.dnsOk).toBe(true);
    expect(result.status).toBe('healthy');
  });

  it('status-server-monitor-probe-004: fails DNS when only the enabled record types do not resolve', async () => {
    // Only the A check is enabled, but the host resolves via CNAME → DNS fails,
    // and the disabled CNAME check is never queried.
    resolve4.mockResolvedValue([]);
    resolveCname.mockResolvedValue(['cname.vercel-dns.com']);
    const result = await probe({ ...base, dnsCheckA: true, dnsCheckAaaa: false, dnsCheckCname: false });
    expect(result.status).toBe('down');
    expect(result.dnsOk).toBe(false);
    expect(result.error).toContain('DNS');
    expect(resolveCname).not.toHaveBeenCalled();
    expect(resolve6).not.toHaveBeenCalled();
  });

  it('status-server-monitor-probe-005: skips DNS resolution entirely when every record check is off', async () => {
    resolve4.mockResolvedValue([]);
    resolve6.mockResolvedValue([]);
    resolveCname.mockResolvedValue([]);
    const result = await probe({ ...base, dnsCheckA: false, dnsCheckAaaa: false, dnsCheckCname: false });
    // No DNS query was made, so the (failing) lookups don't gate the HTTP probe.
    expect(resolve4).not.toHaveBeenCalled();
    expect(resolve6).not.toHaveBeenCalled();
    expect(resolveCname).not.toHaveBeenCalled();
    expect(result.dnsOk).toBe(true);
    expect(result.status).toBe('healthy');
  });
  it('status-server-monitor-probe-006: a malformed URL skips DNS and reports the fetch TypeError', async () => {
    // Real fetch rejects a malformed URL without touching the network.
    vi.unstubAllGlobals();
    let expected = '';
    try {
      await fetch('not a url');
    } catch (err) {
      expected = (err as Error).message;
    }
    expect(expected).not.toBe('');
    const result = await probe({ ...base, url: 'not a url' });
    expect(resolve4).not.toHaveBeenCalled();
    expect(resolve6).not.toHaveBeenCalled();
    expect(resolveCname).not.toHaveBeenCalled();
    expect(result.status).toBe('down');
    expect(result.dnsOk).toBe(true);
    expect(result.error).toBe(expected);
  });

  it('status-server-monitor-probe-007: a fetch that never answers times out as down', async () => {
    // The mocked fetch never settles on its own; it only rejects when the probe aborts it.
    vi.stubGlobal(
      'fetch',
      vi.fn(
        (_url: string, init: RequestInit) =>
          new Promise<Response>((_resolve, reject) => {
            init.signal!.addEventListener('abort', () => reject(new Error('This operation was aborted')));
          }),
      ),
    );
    const result = await probe(base, { timeoutMs: 50 });
    expect(result.status).toBe('down');
    expect(result.statusCode).toBeNull();
    expect(result.responseTimeMs).toBe(50);
    expect(result.error).toBe('Timeout after 50ms');
    expect(result.dnsOk).toBe(true);
  });

  it('status-server-monitor-probe-008: a missing expectBody marker is down with the plain message', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('nope', { status: 200 })));
    const result = await probe({ ...base, kind: 'http', expectBody: 'OK-MARKER', expectedStatus: 200 });
    expect(result.status).toBe('down');
    expect(result.error).toBe('expected content "OK-MARKER" not found in response');
  });

  it('status-server-monitor-probe-009: a marker lost to the body cap says the body was truncated', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => new Response('x'.repeat(PROBE_BODY_MAX_BYTES + 1024), { status: 200 })),
    );
    const result = await probe({ ...base, kind: 'http', expectBody: 'OK-MARKER', expectedStatus: 200 });
    expect(PROBE_BODY_MAX_BYTES).toBe(262144);
    expect(result.status).toBe('down');
    expect(result.error).toContain('body truncated');
    expect(result.error).toContain('marker may lie beyond the cap');
    expect(result.error).toContain('256KB');
  });

  it('status-server-monitor-probe-010: an unchecked body is cancelled and classified without body text', async () => {
    const cancelled = vi.fn();
    const stream = new ReadableStream<Uint8Array>({
      pull(controller) {
        controller.enqueue(new TextEncoder().encode('data'));
      },
      cancel: cancelled,
    });
    vi.stubGlobal('fetch', vi.fn(async () => new Response(stream, { status: 200 })));
    vi.mocked(classify).mockClear();
    const result = await probe({ ...base, kind: 'http', expectBody: null });
    expect(result.status).toBe('healthy');
    expect(cancelled).toHaveBeenCalledTimes(1);
    expect(classify).toHaveBeenCalledTimes(1);
    const input = vi.mocked(classify).mock.calls[0]![0];
    expect(input.bodyText).toBeUndefined();
    expect(input.bodyMarkerMissing).toBe(false);
  });

  it('status-server-monitor-probe-011: probeEndpoints bounds concurrency at 24 and keeps input order', async () => {
    let inFlight = 0;
    let maxInFlight = 0;
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => {
        inFlight++;
        maxInFlight = Math.max(maxInFlight, inFlight);
        await new Promise((r) => setTimeout(r, 10));
        inFlight--;
        return new Response('ok', { status: 200 });
      }),
    );
    const endpoints = Array.from({ length: 30 }, (_, i) => ({ ...base, slug: `svc-${i}` }));
    const results = await probeEndpoints(endpoints);
    expect(results).toHaveLength(30);
    expect(results.map((r) => r.slug)).toEqual(endpoints.map((e) => e.slug));
    expect(maxInFlight).toBeLessThanOrEqual(24);
    expect(maxInFlight).toBeGreaterThan(1);
  });
});
