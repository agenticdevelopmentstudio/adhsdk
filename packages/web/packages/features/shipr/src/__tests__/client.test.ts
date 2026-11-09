import { describe, expect, it, vi } from 'vitest';

import { BASE, createShiprClient } from '../client';

const listAllV1 = vi.hoisted(() => vi.fn());
vi.mock('@adh-sdk/auth/client', async (orig) => ({
  ...(await orig<typeof import('@adh-sdk/auth/client')>()),
  listAllV1,
}));

const emptyTree = {
  object: 'shipr.repo',
  workspace: { kind: 'customer', owner_id: 'u1' },
  verbs: ['R'],
  groups: [],
  items: [],
};

const ok = (body: unknown) =>
  new Response(JSON.stringify(body), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });

const fail = (status: number, body: string) =>
  new Response(body, { status, headers: { 'content-type': 'application/json' } });

describe('createShiprClient — paths', () => {
  it('mounts under the site rewrite prefix, not the backend mount', () => {
    // `/v1/shipr` is the backend's path; `/api` is the fleet site's own `next.config.ts`
    // rewrite. Neither one carries the other's prefix.
    expect(BASE).toBe('/api/v1/shipr');
  });

  it('reads the whole tree in one GET, with no body', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok(emptyTree));
    await createShiprClient(fetcher).tree();
    const [path, init] = fetcher.mock.calls[0]!;
    expect(path).toBe('/api/v1/shipr/repos');
    expect(init.method).toBe('GET');
    expect(init.body).toBeUndefined();
  });

  it('appends the workspace slug when the client has one', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok(emptyTree));
    await createShiprClient(fetcher, 'acme').tree();
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos?workspace=acme');
  });

  it('omits the parameter entirely rather than sending an empty slug', async () => {
    // `workspace=` is a slug the resolver has to reject; absent means "the caller's own",
    // which is a different request.
    const fetcher = vi.fn().mockResolvedValue(ok(emptyTree));
    await createShiprClient(fetcher, '').tree();
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos');
  });

  it('escapes an id rather than pasting it into the path', async () => {
    const wireRepo = {
      id: 'r1',
      dev_repo_id: 'd1',
      group_id: null,
      slug: 'a/b',
      shard: 'all',
      ship_branch: 'main',
      env_branches: {},
      registered_at: null,
      position: 0,
    };
    const fetcher = vi
      .fn()
      .mockResolvedValue(
        ok({ repo: wireRepo, dev_repo: null, group: null, ladder: null, runs: [] }),
      );
    await createShiprClient(fetcher).repo('a/b?c');
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos/a%2Fb%3Fc');
  });

  it('updates a repository and a folder with POST on the item, in snake_case', async () => {
    // /v1 has one update verb. A fresh Response per call: a body can only be read once.
    const fetcher = vi.fn().mockImplementation(async () => ok({ env_branches: {} }));
    const client = createShiprClient(fetcher);
    await client.updateRepo('r1', { groupId: 'g1', shipBranch: 'main' });
    await client.updateGroup('g1', { name: 'fleet', parentId: null });
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos/r1');
    expect(fetcher.mock.calls[0]![1].method).toBe('POST');
    expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({
      group_id: 'g1',
      ship_branch: 'main',
    });
    expect(fetcher.mock.calls[1]![0]).toBe('/api/v1/shipr/groups/g1');
    expect(fetcher.mock.calls[1]![1].method).toBe('POST');
    expect(JSON.parse(fetcher.mock.calls[1]![1].body)).toEqual({ name: 'fleet', parent_id: null });
  });

  it('maps a /v1 repository back to the camelCase domain row', async () => {
    const fetcher = vi.fn().mockImplementation(async () =>
      ok({
        object: 'shipr.repo',
        id: 'r1',
        dev_repo_id: 'd1',
        group_id: null,
        slug: 'a/b',
        shard: 'all',
        ship_branch: 'main',
        env_branches: { staging: 'stg' },
        registered_at: null,
        position: 3,
      }),
    );
    await expect(createShiprClient(fetcher).updateRepo('r1', { position: 3 })).resolves.toEqual({
      id: 'r1',
      devRepoId: 'd1',
      groupId: null,
      slug: 'a/b',
      shard: 'all',
      shipBranch: 'main',
      envBranches: { staging: 'stg' },
      registeredAt: null,
      position: 3,
    });
  });

  it('sends a JSON content-type only when there is a body', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({}));
    const client = createShiprClient(fetcher);
    await client.run({ operation: 'status', scopeKind: 'all' });
    const [, init] = fetcher.mock.calls[0]!;
    expect(init.headers).toEqual({ 'content-type': 'application/json' });
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/runs');
    expect(JSON.parse(init.body)).toEqual({
      operation: 'status',
      scope_kind: 'all',
    });
  });

  it('answers a queued run as runId', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ run_id: 'run1' }));
    await expect(
      createShiprClient(fetcher).run({
        operation: 'deploy',
        scopeKind: 'group',
        scopeId: 'g1',
        options: { groupId: 'g1' },
      }),
    ).resolves.toEqual({ runId: 'run1' });
    expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({
      operation: 'deploy',
      scope_kind: 'group',
      scope_id: 'g1',
      options: { group_id: 'g1' },
    });
  });

  it('registers on POST /v1/shipr/repos and maps the accepted run', async () => {
    const dev = {
      id: 'd1',
      slug: 'a/b',
      display_name: null,
      main_branch: 'main',
      prepared_branch: 'prepared',
      declaration_sha: null,
      connection_id: 'c1',
    };
    const fetcher = vi.fn().mockResolvedValue(ok({ run_id: 'run1', dev_repo: dev }));
    const res = await createShiprClient(fetcher, 'acme').register({
      slug: 'a/b',
      connectionId: 'c1',
      deploymentOwner: 'acme',
    });
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos?workspace=acme');
    expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({
      slug: 'a/b',
      connection_id: 'c1',
      deployment_owner: 'acme',
    });
    expect(res.runId).toBe('run1');
    expect(res.devRepo.mainBranch).toBe('main');
  });

  it('configures with provision:false', async () => {
    const fetcher = vi.fn().mockResolvedValue(
      ok({
        dev_repo: {
          id: 'd1',
          slug: 'a/b',
          display_name: null,
          main_branch: 'main',
          prepared_branch: 'prepared',
          declaration_sha: null,
          connection_id: null,
        },
        mirrors: [],
        notes: ['n'],
      }),
    );
    const res = await createShiprClient(fetcher).configure({ slug: 'a/b' });
    expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({ slug: 'a/b', provision: false });
    expect(res.mirrors).toEqual([]);
    expect(res.notes).toEqual(['n']);
  });

  it('writes org defaults with POST and maps created/updated to ISO strings', async () => {
    const fetcher = vi.fn().mockResolvedValue(
      ok({
        object: 'shipr.org_default',
        id: 'o1',
        org: 'acme',
        deployment_owner: 'acme-deploy',
        name_suffix: '-deployment',
        env_branches: {},
        created: 1700000000,
        updated: 1700000060,
      }),
    );
    const res = await createShiprClient(fetcher).setOrgDefaults('acme', {
      deploymentOwner: 'acme-deploy',
    });
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/org_defaults/acme');
    expect(fetcher.mock.calls[0]![1].method).toBe('POST');
    expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({ deployment_owner: 'acme-deploy' });
    expect(res.deploymentOwner).toBe('acme-deploy');
    expect(res.createdAt).toBe('2023-11-14T22:13:20.000Z');
    expect(res.updatedAt).toBe('2023-11-14T22:14:20.000Z');
  });

  it('reads the org defaults list through listAllV1, with the workspace', async () => {
    listAllV1.mockResolvedValueOnce([]);
    await createShiprClient(vi.fn(), 'acme').orgDefaults();
    expect(listAllV1).toHaveBeenLastCalledWith('/api/v1/shipr/org_defaults?workspace=acme');
  });

  it('names the operation in the path for the per-repository buttons', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ run_id: 'run1' }));
    await createShiprClient(fetcher).runOnRepo('r1', 'deploy', {
      environments: ['staging'],
    });
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos/r1/deploy');
    expect(JSON.parse(fetcher.mock.calls[0]![1].body)).toEqual({
      environments: ['staging'],
    });
  });

  it('unregisters with DELETE on the repository and no body', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ run_id: 'run9' }));
    await expect(createShiprClient(fetcher).runOnRepo('r1', 'unregister')).resolves.toEqual({
      runId: 'run9',
    });
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/repos/r1');
    expect(fetcher.mock.calls[0]![1].method).toBe('DELETE');
    expect(fetcher.mock.calls[0]![1].body).toBeUndefined();
  });

  it('asks for the connections WITHOUT a workspace, even when it has one', async () => {
    // `integration_connections` is keyed on the person. Sending the slug would suggest the
    // answer differs between workspaces, and the backend would have to explain that it does
    // not.
    listAllV1.mockResolvedValueOnce([{ id: 'c1', label: 'acme', account_login: 'acme' }]);
    const res = await createShiprClient(vi.fn(), 'acme').connections();
    expect(listAllV1).toHaveBeenLastCalledWith('/api/v1/shipr/connections');
    expect(res.connections).toEqual([{ id: 'c1', label: 'acme', accountLogin: 'acme' }]);
  });

  it('reads a declaration as an include of the connection', async () => {
    const fetcher = vi.fn().mockResolvedValue(
      ok({ declaration: { deployments: null, fallback_slug: 'a/b-deployment' } }),
    );
    const res = await createShiprClient(fetcher).connectionDeclaration('c1', 'a/b', 'main');
    const url = new URL(fetcher.mock.calls[0]![0], 'http://x');
    expect(url.pathname).toBe('/api/v1/shipr/connections/c1');
    expect(url.searchParams.getAll('include[]')).toEqual(['declaration']);
    expect(url.searchParams.get('slug')).toBe('a/b');
    expect(url.searchParams.get('branch')).toBe('main');
    expect(res).toEqual({ deployments: null, fallbackSlug: 'a/b-deployment' });
  });

  it('carries the cursor on an events page and drops an absent limit', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ events: [], next_seq: 42, state: 'running', done: false }));
    await createShiprClient(fetcher).events('run1', 42);
    expect(fetcher.mock.calls[0]![0]).toBe(
      '/api/v1/shipr/runs/run1/events?after=42',
    );
  });

  it('maps an events page to the camelCase domain', async () => {
    const fetcher = vi.fn().mockResolvedValue(
      ok({
        events: [{ seq: 7, step_id: 's1', stream: 'out', text: 'hi', at: '2026-01-01T00:00:00Z' }],
        next_seq: 8,
        state: 'running',
        done: false,
      }),
    );
    const page = await createShiprClient(fetcher).events('run1');
    expect(page.nextSeq).toBe(8);
    expect(page.events[0]).toEqual({
      id: 'run1:7',
      runId: 'run1',
      stepId: 's1',
      seq: 7,
      stream: 'out',
      text: 'hi',
      at: '2026-01-01T00:00:00Z',
    });
  });

  it('cancels with POST and returns the run mapped from /v1', async () => {
    const fetcher = vi.fn().mockResolvedValue(
      ok({
        object: 'shipr.run',
        id: 'run1',
        operation: 'deploy',
        scope_kind: 'all',
        scope_id: null,
        environments: [],
        state: 'cancelled',
        summary: { keepMe_case: 1 },
        started_at: null,
        finished_at: '2026-01-01T00:00:05Z',
        created: 1700000000,
      }),
    );
    const { run } = await createShiprClient(fetcher).cancelRun('run1');
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/runs/run1/cancel');
    expect(run.scopeKind).toBe('all');
    expect(run.createdAt).toBe('2023-11-14T22:13:20.000Z');
    expect(run.summary).toEqual({ keepMe_case: 1 });
  });

  it('sends the cursor explicitly even at zero — only absent values are dropped', async () => {
    // `query` drops `undefined` and the empty string, not falsiness: `after=0` is a real
    // request for the whole log, and dropping it would leave the default to the backend.
    const fetcher = vi.fn().mockResolvedValue(ok({ events: [], next_seq: 0, state: 'queued', done: false }));
    await createShiprClient(fetcher).events('run1');
    expect(fetcher.mock.calls[0]![0]).toBe('/api/v1/shipr/runs/run1/events?after=0');
  });
});

describe('createShiprClient — failures', () => {
  it('unwraps the backend envelope, because a refusal is the interesting answer', async () => {
    const fetcher = vi
      .fn()
      .mockResolvedValue(
        fail(409, JSON.stringify({ error: { message: 'tip is not verified' } })),
      );
    await expect(
      createShiprClient(fetcher).run({ operation: 'deploy', scopeKind: 'all' }),
    ).rejects.toThrow('tip is not verified');
  });

  it('falls back to the raw text when the body is not the envelope', async () => {
    const fetcher = vi
      .fn()
      .mockResolvedValue(new Response('502 Bad Gateway', { status: 502 }));
    await expect(createShiprClient(fetcher).tree()).rejects.toThrow(
      '502 Bad Gateway',
    );
  });

  it('throws on a refused delete rather than resolving', async () => {
    // A 204-shaped endpoint returning `fetcher`'s promise directly would RESOLVE on a 403,
    // and the folder would vanish from the tree while still existing in the database.
    const fetcher = vi
      .fn()
      .mockResolvedValue(
        fail(403, JSON.stringify({ error: { message: 'not allowed' } })),
      );
    await expect(createShiprClient(fetcher).deleteGroup('g1')).rejects.toThrow(
      'not allowed',
    );
  });

  it('resolves a delete tombstone without reading it', async () => {
    const fetcher = vi.fn().mockResolvedValue(ok({ id: 'g1', object: 'shipr.group', deleted: true }));
    await expect(createShiprClient(fetcher).deleteGroup('g1')).resolves.toBeUndefined();
    expect(fetcher.mock.calls[0]![1].method).toBe('DELETE');
  });
});
