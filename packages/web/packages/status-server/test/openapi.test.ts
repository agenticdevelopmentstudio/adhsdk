import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { describe, expect, expectTypeOf, it, vi } from 'vitest';
import { z } from 'zod';
import type { OpenAPIHono } from '@hono/zod-openapi';
import type { Scheduler } from '../src/scheduler';
import type { Storage } from '../src/storage/ports';
import { createApp } from '../src/app';
import { createDefaultAuthGate } from '../src/auth';
import { buildOpenApiSpec } from '../src/openapi/build';
import { normHonoPath } from '../src/openapi/route-key';
import {
  BEARER,
  errorResponse,
  errors,
  jsonBody,
  okFlag,
  okJson,
  pathParam,
  queryParam,
  ref,
  zodJson,
} from '../src/openapi/shared';
import { readsSchemas } from '../src/openapi/paths/reads';
import { boardSchemas } from '../src/openapi/paths/board';
import { configSchemas } from '../src/openapi/paths/config';
import { telemetrySchemas } from '../src/openapi/paths/telemetry';
import { dashboardSchemas } from '../src/openapi/paths/telemetry-dashboards';
import { reportSchemas } from '../src/openapi/paths/fleet-report';
import { fleetSchemas } from '../src/openapi/paths/fleet';
import { authSchemas } from '../src/openapi/paths/auth';
import { tokensSchemas } from '../src/openapi/paths/tokens';
import { PERMANENTLY_UNDOCUMENTED } from './openapi-exclusions';
import { testConfig } from './helpers/config';

// Registration never touches storage/scheduler (only handlers do), so stubs are
// enough to read app.routes and build the spec. A truthy scheduler ensures the
// conditionally-mounted /cron/* routes are present (they're gated on opts.scheduler).
const config = testConfig();
const storage = {} as unknown as Storage;
const auth = createDefaultAuthGate(storage, config);
const app = createApp({ storage, scheduler: {} as unknown as Scheduler, config, auth });
const spec = buildOpenApiSpec(app, config.appVersion) as {
  openapi: string;
  components: { securitySchemes: Record<string, { scheme: string }> };
  paths: Record<string, Record<string, unknown>>;
};

describe('OpenAPI spec generation', () => {
  it('status-server-paths-003 is OpenAPI 3.1 with bearer security', () => {
    expect(spec.openapi).toBe('3.1.0');
    expect(spec.components.securitySchemes.bearerAuth.scheme).toBe('bearer');
  });
});

// Drift guard. The documented surface is derived from the REAL app: every route
// createApp() registers must be documented in the spec or permanently excluded
// (test/openapi-exclusions.ts). There is NO backlog fixture — a newly mounted,
// undocumented route fails the suite the moment it is added.
describe('OpenAPI spec stays in sync with the routes', () => {
  const registered = new Set<string>();
  for (const r of app.routes) {
    if (r.method === 'ALL') continue; // .use() middleware, not an operation
    registered.add(`${r.method.toUpperCase()} ${normHonoPath(r.path)}`);
  }
  const documented = new Set<string>();
  for (const [path, item] of Object.entries(spec.paths)) {
    for (const m of Object.keys(item)) {
      if (['get', 'post', 'put', 'patch', 'delete'].includes(m)) {
        documented.add(`${m.toUpperCase()} ${path}`);
      }
    }
  }

  it('status-server-paths-002 documents no phantom routes — every documented op maps to a registered route', () => {
    // Catches a path typo or stale entry in src/openapi/paths/* that documents a
    // route createApp() never registers (which would 404 for every caller).
    const phantom = [...documented].filter((op) => !registered.has(op)).sort();
    expect(
      phantom,
      `OpenAPI documents routes that are not registered by createApp() — fix the path ` +
        `string in src/openapi/build.ts or src/openapi/paths/*:\n  ${phantom.join('\n  ')}`,
    ).toEqual([]);
  });

  it('status-server-paths-001 every registered route is documented or permanently excluded (no backlog)', () => {
    const undocumented = [...registered]
      .filter((op) => !documented.has(op) && !PERMANENTLY_UNDOCUMENTED.has(op))
      .sort();
    expect(
      undocumented,
      `These routes are registered by createApp() but absent from the OpenAPI spec. ` +
        `Document them in a src/openapi/paths/* module (assembled by src/openapi/build.ts). ` +
        `If a route is intentionally never documented, add it to test/openapi-exclusions.ts:\n  ` +
        `${undocumented.join('\n  ')}`,
    ).toEqual([]);
  });

  it('status-server-paths-004 the committed openapi.json matches a fresh build (re-run: pnpm openapi:dump)', () => {
    // The package's tracked openapi.json is what its `pnpm openapi:dump` writes;
    // this pins it to the code so it can never silently drift. dump-openapi.ts builds
    // with NO scheduler (createApp({ storage, config })), so the committed artifact omits the
    // scheduler-gated /cron/* routes — build it the SAME way here for an apples-to-
    // apples compare. (The drift guard above still covers /cron via the scheduler-
    // stubbed `app`, so cron isn't left unchecked.)
    const dumpSpec = buildOpenApiSpec(createApp({ storage, config, auth }), config.appVersion);
    const committedPath = resolve(dirname(fileURLToPath(import.meta.url)), '../openapi.json');
    const committed = JSON.parse(readFileSync(committedPath, 'utf8')) as { info: Record<string, unknown> };
    // info.version derives from APP_VERSION at build time — normalize it so this
    // structural check doesn't flake when CI injects a version string.
    const pinVersion = (s: { info: Record<string, unknown> }) => ({
      ...s,
      info: { ...s.info, version: '0.0.0' },
    });
    expect(
      pinVersion(committed),
      'status-server/openapi.json is out of date — re-run: pnpm openapi:dump in packages/web/packages/status-server (and commit).',
    ).toEqual(pinVersion(dumpSpec as { info: Record<string, unknown> }));
  });
});

// ---------------------------------------------------------------------------
// Conformance vectors: status-server-openapi-001 .. 027
// ---------------------------------------------------------------------------
type Doc = {
  openapi: string;
  info: Record<string, unknown>;
  components: { schemas: Record<string, unknown>; securitySchemes: Record<string, unknown> };
  paths: Record<string, Record<string, unknown>>;
};
type AnyApp = OpenAPIHono<any>; // eslint-disable-line @typescript-eslint/no-explicit-any
// A stand-in for createApp(): only getOpenAPI31Document is ever called by the builder.
const stubApp = (doc: Record<string, unknown>): AnyApp =>
  ({ getOpenAPI31Document: () => doc }) as unknown as AnyApp;
const COLLISION_DOC = { paths: { '/tokens': { get: { summary: 'AUTO' } } } };
const fullSpec = spec as unknown as Doc;
const HTTP_METHODS = ['get', 'post', 'put', 'patch', 'delete'];
const documentedOps = (s: Doc): Set<string> => {
  const out = new Set<string>();
  for (const [path, item] of Object.entries(s.paths))
    for (const m of Object.keys(item)) if (HTTP_METHODS.includes(m)) out.add(`${m.toUpperCase()} ${path}`);
  return out;
};
const registeredOps = (): Set<string> => {
  const out = new Set<string>();
  for (const r of app.routes) if (r.method !== 'ALL') out.add(`${r.method.toUpperCase()} ${normHonoPath(r.path)}`);
  return out;
};

describe('buildOpenApiSpec assembly (vectors 001-010, 026, 027)', () => {
  it('status-server-openapi-001 base document is 3.1.0 with the fixed title and caller version', () => {
    const s = buildOpenApiSpec(app, '1.2.3') as Doc;
    expect(s.openapi).toBe('3.1.0');
    expect(s.info).toEqual({ title: 'status-backend', version: '1.2.3' });
  });

  it('status-server-openapi-002 bearerAuth security scheme is the fixed literal', () => {
    expect(fullSpec.components.securitySchemes.bearerAuth).toEqual({ type: 'http', scheme: 'bearer' });
  });

  it('status-server-openapi-003 native routes are documented but contributed by no MODULES entry', () => {
    const native = ['/health', '/version', '/public/status-summary', '/cron/refresh', '/cron/maintenance'];
    for (const p of native) expect(fullSpec.paths[p], p).toBeDefined();
    // With the auto-generated document empty, only the hand-written MODULES paths remain.
    const handWritten = buildOpenApiSpec(stubApp({ paths: {} }), 'v') as Doc;
    for (const p of native) expect(handWritten.paths[p], p).toBeUndefined();
    // Drift-guard computation over the real app: zero phantom, zero undocumented.
    const registered = registeredOps();
    const documented = documentedOps(fullSpec);
    expect([...documented].filter((o) => !registered.has(o))).toEqual([]);
    expect([...registered].filter((o) => !documented.has(o) && !PERMANENTLY_UNDOCUMENTED.has(o))).toEqual([]);
  });

  it('status-server-openapi-004 hand-written paths are merged into the document', () => {
    expect(fullSpec.paths['/tokens']).toHaveProperty('get');
    expect(fullSpec.paths['/tokens']).toHaveProperty('post');
    expect(fullSpec.paths['/tokens/{id}']).toHaveProperty('delete');
  });

  it('status-server-openapi-005 an auto-generated path-item replaces the hand-written one wholesale', () => {
    const s = buildOpenApiSpec(stubApp(COLLISION_DOC), 'v') as Doc;
    expect(s.paths['/tokens']).toEqual({ get: { summary: 'AUTO' } });
    expect(s.paths['/tokens']).not.toHaveProperty('post');
  });

  it('status-server-openapi-006 components default when the auto-generated document has none', () => {
    const s = buildOpenApiSpec(stubApp({ paths: {} }), 'v') as Doc;
    expect(s.components.schemas).toBeTypeOf('object');
    expect(s.components.schemas).toHaveProperty('Error');
    expect(s.components.securitySchemes).toEqual({ bearerAuth: { type: 'http', scheme: 'bearer' } });
  });

  it('status-server-openapi-007 component schemas union all three tiers', () => {
    expect(fullSpec.components.schemas).toHaveProperty('ApiTokenMeta');
    expect(fullSpec.components.schemas).toHaveProperty('Error');
  });

  it('status-server-openapi-008 the Error component schema has the fixed shape with no required list', () => {
    expect(fullSpec.components.schemas.Error).toEqual({
      type: 'object',
      properties: { error: { type: 'object', properties: { message: { type: 'string' }, code: { type: 'string' } } } },
    });
    expect(JSON.stringify(fullSpec.components.schemas.Error)).not.toContain('required');
  });

  it('status-server-openapi-009 the return type is unknown', () => {
    expectTypeOf(buildOpenApiSpec).returns.toEqualTypeOf<unknown>();
  });

  it('status-server-openapi-010 two builds of equivalent apps deep-equal the committed openapi.json', () => {
    const pin = (s: unknown) => ({ ...(s as Doc), info: { ...(s as Doc).info, version: '0.0.0' } });
    const committed = JSON.parse(
      readFileSync(resolve(dirname(fileURLToPath(import.meta.url)), '../openapi.json'), 'utf8'),
    ) as unknown;
    const a = buildOpenApiSpec(createApp({ storage, config, auth }), config.appVersion);
    const b = buildOpenApiSpec(createApp({ storage, config, auth }), config.appVersion);
    expect(pin(a)).toEqual(pin(committed));
    expect(pin(b)).toEqual(pin(committed));
  });

  it('status-server-openapi-026 a path collision drops POST /tokens and the drift guard reports it', () => {
    const colliding = buildOpenApiSpec(
      { routes: app.routes, getOpenAPI31Document: () => COLLISION_DOC } as unknown as AnyApp,
      'v',
    ) as Doc;
    const documented = documentedOps(colliding);
    const undocumented = [...registeredOps()].filter((o) => !documented.has(o) && !PERMANENTLY_UNDOCUMENTED.has(o));
    expect(undocumented).toContain('POST /tokens');
  });

  it('status-server-openapi-027 no two modules export the same component-schema name today', () => {
    // The merge in build.ts is last-write-wins and nothing guards it, so pin the
    // convention here: every module's schema names are unique across modules.
    const all = [
      readsSchemas, boardSchemas, configSchemas, telemetrySchemas, dashboardSchemas,
      reportSchemas, fleetSchemas, authSchemas, tokensSchemas,
    ];
    const names = all.flatMap((m) => Object.keys(m));
    expect(names.filter((n, i) => names.indexOf(n) !== i)).toEqual([]);
  });
});

describe('normHonoPath (vectors 011-016)', () => {
  it('status-server-openapi-011 converts :param to {param}', () => {
    expect(normHonoPath('/tokens/:id')).toBe('/tokens/{id}');
  });
  it('status-server-openapi-012 converts a non-final param identically', () => {
    expect(normHonoPath('/deployments/:id/log')).toBe('/deployments/{id}/log');
  });
  it('status-server-openapi-013 collapses every run of slashes', () => {
    expect(normHonoPath('/tokens//id///log')).toBe('/tokens/id/log');
  });
  it('status-server-openapi-014 strips a trailing slash', () => {
    expect(normHonoPath('/tokens/')).toBe('/tokens');
  });
  it('status-server-openapi-015 keeps the root path as /', () => {
    expect(normHonoPath('/')).toBe('/');
  });
  it('status-server-openapi-016 is pure across interleaved calls', () => {
    const first = normHonoPath('/health');
    normHonoPath('/version');
    expect(normHonoPath('/health')).toBe(first);
    expect(first).toBe('/health');
  });
});

describe('shared fragment builders (vectors 017-025)', () => {
  const errorBody = { content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } } };
  it('status-server-openapi-017 BEARER is the bearerAuth requirement', () => {
    expect(BEARER).toEqual([{ bearerAuth: [] }]);
  });
  it('status-server-openapi-018 jsonBody wraps a ref as application/json', () => {
    expect(jsonBody(ref('Error'))).toEqual(errorBody);
  });
  it('status-server-openapi-019 errorResponse has the fixed shape', () => {
    expect(errorResponse).toEqual({ description: 'Error', ...errorBody });
  });
  it('status-server-openapi-020 errors() maps each code to the shared errorResponse reference', () => {
    const e = errors(401, 404);
    expect(e).toEqual({ 401: errorResponse, 404: errorResponse });
    expect(e[401]).toBe(errorResponse);
    expect(e[404]).toBe(errorResponse);
  });
  it('status-server-openapi-021 okFlag has the fixed shape', () => {
    expect(okFlag).toEqual({
      description: 'Success',
      content: {
        'application/json': { schema: { type: 'object', required: ['ok'], properties: { ok: { type: 'boolean' } } } },
      },
    });
    expect(okJson('Success', { type: 'object' })).toEqual({
      description: 'Success',
      content: { 'application/json': { schema: { type: 'object' } } },
    });
  });
  it('status-server-openapi-022 pathParam is always a required string', () => {
    expect(pathParam('id')).toEqual({ name: 'id', in: 'path', required: true, schema: { type: 'string' } });
  });
  it('status-server-openapi-023 queryParam defaults to optional', () => {
    expect(queryParam('q')).toEqual({ name: 'q', in: 'query', required: false, schema: { type: 'string' } });
    expect(queryParam('q', true)).toEqual({ name: 'q', in: 'query', required: true, schema: { type: 'string' } });
  });
  it('status-server-openapi-024 zodJson returns the draft-2020-12 conversion', () => {
    const schema = z.object({ id: z.string() });
    const out = zodJson(schema);
    expect(out).toEqual(z.toJSONSchema(schema, { target: 'draft-2020-12' }));
    expect(out.properties.id).toEqual({ type: 'string' });
  });
  it('status-server-openapi-025 zodJson falls back to a permissive object without logging', () => {
    const spies = (['log', 'info', 'warn', 'error', 'debug'] as const).map((m) =>
      vi.spyOn(console, m).mockImplementation(() => {}),
    );
    try {
      expect(() => z.toJSONSchema(z.date(), { target: 'draft-2020-12' })).toThrow();
      expect(zodJson(z.date())).toEqual({ type: 'object', additionalProperties: true });
      for (const sp of spies) expect(sp).not.toHaveBeenCalled();
    } finally {
      for (const sp of spies) sp.mockRestore();
    }
  });
});
