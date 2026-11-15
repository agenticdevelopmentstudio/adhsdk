import { describe, it, expect } from 'vitest';
import { classify, DEGRADED_THRESHOLD_MS } from '../src/monitor/health';

describe('classify', () => {
  const base = { statusCode: 200, responseTimeMs: 100, expectedStatus: 200 };
  const hk = { ...base, isHealthKind: true };

  it('status-server-monitor-health-001 healthy on fast 2xx', () => {
    expect(classify(base)).toBe('healthy');
  });

  it('status-server-monitor-health-002 degraded when slow', () => {
    expect(classify({ ...base, responseTimeMs: 2500 })).toBe('degraded');
  });

  it('status-server-monitor-health-003 down on 5xx', () => {
    expect(classify({ ...base, statusCode: 503 })).toBe('down');
  });

  it('status-server-monitor-health-004 down when the expected body marker is missing', () => {
    expect(classify({ ...base, bodyMarkerMissing: true })).toBe('down');
  });

  it('status-server-monitor-health-005 down when a health-kind JSON body reports non-ok status', () => {
    expect(
      classify({ ...base, isHealthKind: true, bodyText: '{"status":"degraded"}' }),
    ).toBe('down');
  });

  it('status-server-monitor-health-006 honours a non-2xx expectedStatus match as not-down', () => {
    expect(classify({ ...base, statusCode: 401, expectedStatus: 401 })).toBe('healthy');
  });

  it('status-server-monitor-health-007 non-JSON health-kind body falls through to healthy', () => {
    expect(classify({ ...hk, bodyText: 'not json' })).toBe('healthy');
  });

  it('status-server-monitor-health-008 health-kind JSON without a status field falls through', () => {
    expect(classify({ ...hk, bodyText: '{"ok":true}' })).toBe('healthy');
  });

  it('status-server-monitor-health-009 health-kind check is skipped without body text', () => {
    expect(classify({ ...hk, bodyText: '' })).toBe('healthy');
  });

  it('status-server-monitor-health-010 status "OK" matches case-insensitively', () => {
    expect(classify({ ...hk, bodyText: '{"status":"OK"}' })).toBe('healthy');
  });

  it('status-server-monitor-health-011 a numeric status is coerced to a string and is not ok', () => {
    expect(classify({ ...hk, bodyText: '{"status":200}' })).toBe('down');
  });

  it('status-server-monitor-health-012 latency exactly at DEGRADED_THRESHOLD_MS is not degraded', () => {
    expect(DEGRADED_THRESHOLD_MS).toBe(2000);
    expect(classify({ ...base, responseTimeMs: DEGRADED_THRESHOLD_MS })).toBe('healthy');
    expect(classify({ ...base, responseTimeMs: DEGRADED_THRESHOLD_MS + 1 })).toBe('degraded');
  });

  it('status-server-monitor-health-013 the health-kind verdict returns before the marker check', () => {
    expect(classify({ ...hk, bodyText: '{"status":"degraded"}', bodyMarkerMissing: true })).toBe('down');
  });
});
