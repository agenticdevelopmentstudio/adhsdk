import { beforeAll, describe, expect, it } from 'vitest';
import { createApp } from '../src/app';
import { testDeps } from './helpers/storage';
import { freshDb } from './helpers/db';
import { sessionHeaders } from './helpers/auth';

// GET /report over the real app: view-tier auth, query validation into the app's
// `{ error: { message } }` 400 (what the adh-status CLI prints), and the payload's shape.

describe('GET /report', () => {
  let app: ReturnType<typeof createApp>;
  let viewAuth: { Cookie: string };

  beforeAll(async () => {
    const db = await freshDb();
    viewAuth = await sessionHeaders(db, 'viewer');
    app = createApp(testDeps(db));
  });

  it('401 without a token (gated)', async () => {
    expect((await app.request('/report?wait=0')).status).toBe(401);
  });

  it.each([
    ['range=1y', 'range must be one of 24h, 7d, 30d'],
    ['days=0', 'days must be an integer 1-365'],
    ['days=abc', 'days must be an integer 1-365'],
    ['wait=61', 'wait must be an integer 0-60'],
    ['logs=true', 'logs must be 0 or 1'],
  ])('400 for %s', async (query, message) => {
    const res = await app.request(`/report?${query}`, { headers: viewAuth });
    expect(res.status).toBe(400);
    expect(((await res.json()) as { error: { message: string } }).error.message).toBe(message);
  });

  it('200 with the full shape, never cached', async () => {
    const res = await app.request('/report?wait=0&days=14&range=30d&logs=1', { headers: viewAuth });
    expect(res.status).toBe(200);
    expect(res.headers.get('cache-control')).toBe('no-store');
    const body = (await res.json()) as Record<string, unknown> & {
      coverage: Record<string, { ok: boolean }>;
      sections: Record<string, unknown> & { uptime: { days: number } | null; analytics: { range: string } | null };
      counts: Record<string, number>;
      findings: unknown[];
    };
    expect(body.schema).toBe('status.report/1');
    expect(typeof body.generatedAt).toBe('string');
    expect(['healthy', 'attention', 'degraded', 'down', 'unknown']).toContain(body.verdict);
    expect(typeof body.complete).toBe('boolean');
    expect(Object.keys(body.counts).sort()).toEqual(['critical', 'major', 'minor']);
    expect(Array.isArray(body.findings)).toBe(true);
    const sources = ['monitor', 'deploys', 'integrations', 'errors', 'runtimeErrors', 'analytics', 'uptime'];
    expect(Object.keys(body.coverage)).toEqual(sources);
    expect(Object.keys(body.sections)).toEqual(sources);
    for (const source of sources) {
      expect(body.sections[source] === null).toBe(!body.coverage[source]!.ok);
    }
    expect(body.sections.uptime?.days).toBe(14);
    expect(body.sections.analytics?.range).toBe('30d');
  });
});
