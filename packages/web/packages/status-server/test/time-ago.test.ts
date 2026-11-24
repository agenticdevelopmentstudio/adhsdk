// Conformance vectors for monitor/time-ago.ts (status-server-monitor-time-ago-001..011).
import { afterEach, describe, expect, it, vi } from 'vitest';
import { timeAgo } from '../src/monitor/time-ago';

const NOW = Date.parse('2026-01-01T12:00:00.000Z');
/** The ISO string `secs` seconds before NOW. */
const ago = (secs: number): string => new Date(NOW - secs * 1000).toISOString();

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe('timeAgo', () => {
  it('status-server-monitor-time-ago-001: zero elapsed is "just now"', () => {
    expect(timeAgo(ago(0), NOW)).toBe('just now');
  });
  it('status-server-monitor-time-ago-002: 59 seconds is still "just now"', () => {
    expect(timeAgo(ago(59), NOW)).toBe('just now');
  });
  it('status-server-monitor-time-ago-003: 60 seconds is "1m"', () => {
    expect(timeAgo(ago(60), NOW)).toBe('1m');
  });
  it('status-server-monitor-time-ago-004: 3599 seconds is "59m"', () => {
    expect(timeAgo(ago(3599), NOW)).toBe('59m');
  });
  it('status-server-monitor-time-ago-005: 3600 seconds is "1h"', () => {
    expect(timeAgo(ago(3600), NOW)).toBe('1h');
  });
  it('status-server-monitor-time-ago-006: 23 hours is "23h"', () => {
    expect(timeAgo(ago(23 * 3600), NOW)).toBe('23h');
  });
  it('status-server-monitor-time-ago-007: 24 hours is "1d"', () => {
    expect(timeAgo(ago(24 * 3600), NOW)).toBe('1d');
  });
  it('status-server-monitor-time-ago-008: 240 hours is "10d" with no week/month rollover', () => {
    expect(timeAgo(ago(240 * 3600), NOW)).toBe('10d');
  });
  it('status-server-monitor-time-ago-009: an iso 5 minutes in the future is "just now"', () => {
    expect(timeAgo(ago(-300), NOW)).toBe('just now');
  });
  it('status-server-monitor-time-ago-010: an unparseable iso yields the literal "NaNd"', () => {
    expect(timeAgo('not-a-date', Date.now())).toBe('NaNd');
  });
  it('status-server-monitor-time-ago-011: pure and synchronous, no clock/console/fetch use, no throw', () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const consoleSpies = (['log', 'info', 'warn', 'error', 'debug'] as const).map((m) =>
      vi.spyOn(console, m).mockImplementation(() => {}),
    );
    const nowSpy = vi.spyOn(Date, 'now');
    const inputs: Array<[string, number]> = [
      [ago(0), NOW], [ago(59), NOW], [ago(60), NOW], [ago(3599), NOW], [ago(3600), NOW],
      [ago(23 * 3600), NOW], [ago(24 * 3600), NOW], [ago(240 * 3600), NOW], [ago(-300), NOW],
      ['not-a-date', NOW],
    ];
    for (const [iso, nowMs] of inputs) {
      expect(() => timeAgo(iso, nowMs)).not.toThrow();
      expect(typeof timeAgo(iso, nowMs)).toBe('string'); // synchronous: a string, not a Promise
    }
    expect(nowSpy).not.toHaveBeenCalled();
    expect(fetchSpy).not.toHaveBeenCalled();
    for (const s of consoleSpies) expect(s).not.toHaveBeenCalled();
  });
});
