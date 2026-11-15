// Conformance vectors for monitor/url.ts (status-server-monitor-url-001..011).
import { afterEach, describe, expect, it, vi } from 'vitest';
import { hostOf, projectPageUrl } from '../src/monitor/url';

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe('hostOf', () => {
  it('status-server-monitor-url-001: returns the host of an absolute URL', () => {
    expect(hostOf('https://example.com/path')).toBe('example.com');
  });
  it('status-server-monitor-url-002: keeps a non-default port', () => {
    expect(hostOf('https://example.com:8080/x')).toBe('example.com:8080');
  });
  it('status-server-monitor-url-003: returns an unparseable string unchanged', () => {
    expect(hostOf('not a url')).toBe('not a url');
  });
  it('status-server-monitor-url-004: returns the empty string unchanged', () => {
    expect(hostOf('')).toBe('');
  });
});

describe('projectPageUrl', () => {
  it('status-server-monitor-url-005: null, undefined and empty string give null', () => {
    expect(projectPageUrl(null)).toBeNull();
    expect(projectPageUrl(undefined)).toBeNull();
    expect(projectPageUrl('')).toBeNull();
  });
  it('status-server-monitor-url-006: collapses a Vercel deploy URL to the project page', () => {
    expect(projectPageUrl('https://vercel.com/acme/my-app/dpl_abc123')).toBe('https://vercel.com/acme/my-app');
  });
  it('status-server-monitor-url-007: drops the deploy id, further segments, query and fragment', () => {
    expect(projectPageUrl('https://vercel.com/acme/my-app/dpl_abc123/logs?tab=build#top')).toBe(
      'https://vercel.com/acme/my-app',
    );
  });
  it('status-server-monitor-url-008: a Vercel URL with fewer than 3 segments passes through unchanged', () => {
    expect(projectPageUrl('https://vercel.com/acme/my-app')).toBe('https://vercel.com/acme/my-app');
    // Returned as the original string, not rebuilt from origin: a trailing slash survives.
    expect(projectPageUrl('https://vercel.com/acme/my-app/')).toBe('https://vercel.com/acme/my-app/');
  });
  it('status-server-monitor-url-009: a non-Vercel URL passes through unchanged', () => {
    const u = 'https://backboard.railway.app/project/xyz/service/abc';
    expect(projectPageUrl(u)).toBe(u);
  });
  it('status-server-monitor-url-010: an unparseable string passes through unchanged', () => {
    expect(projectPageUrl('not a url')).toBe('not a url');
  });
  it('status-server-monitor-url-011: both functions are pure, synchronous and never throw', () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const consoleSpies = (['log', 'info', 'warn', 'error', 'debug'] as const).map((m) =>
      vi.spyOn(console, m).mockImplementation(() => {}),
    );
    const hostInputs = ['https://example.com/path', 'https://example.com:8080/x', 'not a url', ''];
    const pageInputs = [
      null, undefined, '', 'https://vercel.com/acme/my-app/dpl_abc123',
      'https://vercel.com/acme/my-app/dpl_abc123/logs?tab=build#top', 'https://vercel.com/acme/my-app',
      'https://backboard.railway.app/project/xyz/service/abc', 'not a url',
    ];
    for (const i of hostInputs) {
      expect(() => hostOf(i)).not.toThrow();
      expect(typeof hostOf(i)).toBe('string');
    }
    for (const i of pageInputs) {
      expect(() => projectPageUrl(i)).not.toThrow();
      const r = projectPageUrl(i);
      expect(r === null || typeof r === 'string').toBe(true);
    }
    expect(fetchSpy).not.toHaveBeenCalled();
    for (const s of consoleSpies) expect(s).not.toHaveBeenCalled();
  });
});
