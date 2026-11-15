import { describe, it, expect, vi, afterEach } from 'vitest';
import { NON_DEPLOY_KINDS as ENGINE_NON_DEPLOY_KINDS } from '@adh-sdk/deploy-platform/engine';
import { ENDPOINT_KINDS, NON_DEPLOY_KINDS, isEndpointKind, type EndpointKind } from '../src/monitor/endpoint-kinds';

afterEach(() => vi.restoreAllMocks());

describe('endpoint-kinds conformance vectors', () => {
  it('status-server-monitor-endpoint-kinds-001: the vocabulary has six kinds in order', () => {
    expect(ENDPOINT_KINDS).toHaveLength(6);
    expect(ENDPOINT_KINDS.join(',')).toBe('http,frontend,admin,health,custom,dns');
  });

  it('status-server-monitor-endpoint-kinds-002: only vocabulary members are assignable to EndpointKind', () => {
    const ok: EndpointKind = 'http';
    // @ts-expect-error 'staging' is not a member of the endpoint-kind vocabulary
    const bad: EndpointKind = 'staging';
    expect(isEndpointKind(ok)).toBe(true);
    expect(isEndpointKind(bad)).toBe(false);
  });

  it('status-server-monitor-endpoint-kinds-003: the tuple is readonly at compile time only, not frozen at runtime', () => {
    // @ts-expect-error a readonly tuple has no push
    expect(() => ENDPOINT_KINDS.push('extra')).not.toThrow();
    try {
      expect(ENDPOINT_KINDS).toHaveLength(7);
      expect(Object.isFrozen(ENDPOINT_KINDS)).toBe(false);
    } finally {
      (ENDPOINT_KINDS as unknown as string[]).pop(); // restore the shared vocabulary
    }
    expect(ENDPOINT_KINDS).toHaveLength(6);
  });

  it('status-server-monitor-endpoint-kinds-004: isEndpointKind accepts dns and http', () => {
    expect(isEndpointKind('dns')).toBe(true);
    expect(isEndpointKind('http')).toBe(true);
  });

  it('status-server-monitor-endpoint-kinds-005: isEndpointKind rejects wrong case, empty and unknown strings', () => {
    expect(isEndpointKind('DNS')).toBe(false);
    expect(isEndpointKind('')).toBe(false);
    expect(isEndpointKind('unknown')).toBe(false);
  });

  it('status-server-monitor-endpoint-kinds-006: a superstring of a valid kind is not a valid kind', () => {
    expect(isEndpointKind('httpz')).toBe(false);
    expect(isEndpointKind('adminx')).toBe(false);
  });

  it('status-server-monitor-endpoint-kinds-007: isEndpointKind narrows a plain string inside the passing branch only', () => {
    const value: string = 'admin';
    const takesKind = (k: EndpointKind): EndpointKind => k;
    let narrowed: EndpointKind | null = null;
    if (isEndpointKind(value)) narrowed = takesKind(value);
    // @ts-expect-error outside the passing branch the plain string is not an EndpointKind
    takesKind(value);
    expect(narrowed).toBe('admin');
  });

  it("status-server-monitor-endpoint-kinds-008: NON_DEPLOY_KINDS is the classifier's own set, re-exported", () => {
    expect(NON_DEPLOY_KINDS).toBe(ENGINE_NON_DEPLOY_KINDS);
    for (const k of ['health', 'custom', 'dns']) expect(NON_DEPLOY_KINDS.has(k)).toBe(true);
    for (const k of ['http', 'frontend', 'admin']) expect(NON_DEPLOY_KINDS.has(k)).toBe(false);
  });

  it('status-server-monitor-endpoint-kinds-009: loading and using the module has no side effects', async () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const spies = [
      vi.spyOn(console, 'log'),
      vi.spyOn(console, 'error'),
      vi.spyOn(console, 'warn'),
      vi.spyOn(console, 'info'),
      vi.spyOn(console, 'debug'),
    ];
    const fs = (await import('node:fs')).default;
    const fsSpies = [vi.spyOn(fs, 'readFileSync'), vi.spyOn(fs, 'writeFileSync'), vi.spyOn(fs, 'existsSync')];
    try {
      vi.resetModules();
      const fresh = await import('../src/monitor/endpoint-kinds');
      for (const k of ['http', 'dns', 'nope']) fresh.isEndpointKind(k);
      for (const s of [fetchSpy, ...spies, ...fsSpies]) expect(s).not.toHaveBeenCalled();
    } finally {
      vi.unstubAllGlobals();
    }
  });
});
