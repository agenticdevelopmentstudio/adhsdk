import { describe, expect, it } from 'vitest';
import { activityPaths } from '../src/openapi/paths/activity';
import { hooksPaths } from '../src/openapi/paths/hooks';
import { configSchemas } from '../src/openapi/paths/config';
import { tokensPaths } from '../src/openapi/paths/tokens';
import { badgePaths } from '../src/openapi/paths/badge';
import { streamPaths } from '../src/openapi/paths/stream';
import { boardPaths, boardSchemas } from '../src/openapi/paths/board';
import { BEARER, errors, ref } from '../src/openapi/shared';

// Conformance vectors status-server-paths-005 .. 012. Vectors 001-004 (the drift guard,
// the security scheme and the committed-spec pin) live in openapi.test.ts, beside the app
// they build. These read the hand-written path modules directly: they are static literals.
/* eslint-disable @typescript-eslint/no-explicit-any */
type Param = { name: string; required?: boolean };

describe('hand-written OpenAPI path modules', () => {
  it('status-server-paths-005 GET /activity documents the cursor pair, bearer security and 400/401', () => {
    const op = activityPaths['/activity'].get;
    const params = op.parameters as Param[];
    const byName = (n: string) => params.find((p) => p.name === n)!;
    expect(byName('before')).toBeDefined();
    expect(byName('beforeId')).toBeDefined();
    expect(byName('limit')).toBeDefined();
    expect(byName('before').required).toBe(false);
    expect(byName('beforeId').required).toBe(false);
    expect(op.security).toBe(BEARER);
    const schema = op.responses[200].content['application/json'].schema;
    expect(Object.keys(schema.properties)).toEqual(expect.arrayContaining(['rows', 'nextCursor']));
    expect(op.responses[400]).toBe(errors(400)[400]);
    expect(op.responses[401]).toBe(errors(401)[401]);
    expect(op.description).toContain('lone half 400s');
  });

  it('status-server-paths-006 both provider webhooks omit security and share okIgnored and 401/503', () => {
    const vercel = hooksPaths['/hooks/vercel'].post;
    const railway = hooksPaths['/hooks/railway'].post;
    for (const op of [vercel, railway]) {
      expect(op).not.toHaveProperty('security');
      expect(op.responses[401]).toBe(errors(401)[401]);
      expect(op.responses[503]).toBe(errors(503)[503]);
    }
    expect(vercel.responses[200]).toBe(railway.responses[200]);
    const schema = vercel.responses[200].content['application/json'].schema;
    expect(Object.keys(schema.properties).sort()).toEqual(['id', 'ignored', 'ok']);
    expect(schema.required).toEqual(['ok']);
  });

  it('status-server-paths-007 PeerRow carries hasToken and no token property', () => {
    const allOf = configSchemas.PeerRow.allOf as { properties?: Record<string, unknown> }[];
    const merged = Object.assign({}, ...allOf.map((s) => s.properties ?? {})) as Record<string, unknown>;
    expect(merged.hasToken).toEqual({ type: 'boolean' });
    expect(merged).not.toHaveProperty('token');
    expect(Object.keys(merged)).toEqual(expect.arrayContaining(['id', 'createdAt']));
  });

  it('status-server-paths-008 only the 201 create response carries the raw token', () => {
    const created = tokensPaths['/tokens'].post.responses[201].content['application/json'].schema;
    expect(created.allOf).toContainEqual({ type: 'object', required: ['token'], properties: { token: { type: 'string' } } });
    const listed = tokensPaths['/tokens'].get.responses[200].content['application/json'].schema;
    expect(listed).toEqual({ type: 'array', items: ref('ApiTokenMeta') });
    expect(listed).not.toHaveProperty('properties');
  });

  it('status-server-paths-009 the badge returns image/svg+xml as a string', () => {
    const content = badgePaths['/status/badge.svg'].get.responses[200].content;
    expect(Object.keys(content)).toEqual(['image/svg+xml']);
    expect(content['image/svg+xml']).toEqual({ schema: { type: 'string' } });
  });

  it('status-server-paths-010 /live/check 503 is the literal no-scheduler shape, not Error', () => {
    const r503 = streamPaths['/live/check'].post.responses[503];
    const schema = r503.content['application/json'].schema;
    expect(schema.required).toEqual(['ok', 'ran', 'reason']);
    expect(schema.properties.ok.enum).toEqual([false]);
    expect(schema.properties.ran.enum).toEqual([false]);
    expect(schema.properties.reason.enum).toEqual(['no scheduler']);
    expect(r503).not.toBe(errors(503)[503]);
    expect(JSON.stringify(schema)).not.toContain('#/components/schemas/Error');
  });

  it('status-server-paths-011 POST /board/reconcile documents 401 and 403', () => {
    const responses = boardPaths['/board/reconcile'].post.responses as Record<string, unknown>;
    expect(responses[401]).toBe(errors(401)[401]);
    expect(responses[403]).toBe(errors(403)[403]);
    expect(boardPaths['/board/reconcile'].post.security).toBe(BEARER);
  });

  it('status-server-paths-012 ActivityRow has one owner (board) and activity references it', () => {
    const rows = activityPaths['/activity'].get.responses[200].content['application/json'].schema.properties.rows;
    expect(rows).toEqual({ type: 'array', items: ref('ActivityRow') });
    expect(boardSchemas).toHaveProperty('ActivityRow');
    // activity.ts exports no Schemas object of its own.
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    return import('../src/openapi/paths/activity').then((m) => {
      expect(Object.keys(m).filter((k) => k.endsWith('Schemas'))).toEqual([]);
    });
  });
});
