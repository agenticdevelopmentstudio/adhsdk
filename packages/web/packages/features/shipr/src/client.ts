import { listAllV1, V1_PAGE_MAX, withV1Query, type V1List } from '@adh-sdk/auth/client';

import {
  shiprConnection,
  shiprDeclaration,
  shiprDevRepo,
  shiprEventPage,
  shiprForgeRepositories,
  shiprGroup,
  shiprOrgDefaults,
  shiprRepo,
  shiprRepoDetail,
  shiprRun,
  shiprRunStep,
  shiprTree,
  type ShiprWireConnection,
  type ShiprWireDeclaration,
  type ShiprWireDevRepo,
  type ShiprWireEventPage,
  type ShiprWireGroup,
  type ShiprWireOrgDefaults,
  type ShiprWireRepo,
  type ShiprWireRepoDetail,
  type ShiprWireRepositories,
  type ShiprWireRun,
  type ShiprWireRunStep,
  type ShiprWireTree,
} from './shipr-wire';
import type {
  DeclarationResponse,
  EventPage,
  ForgeConnection,
  ForgeRepository,
  Group,
  OrgDefaults,
  OrgDefaultsPatch,
  RegisterAccepted,
  RegisterConfigured,
  RegisterRequest,
  Repo,
  RepoPatch,
  RepoDetail,
  Run,
  RunAccepted,
  RunRequest,
  RunStep,
  TreeResponse,
} from './types';

/**
 * A `fetch`-shaped call that already carries auth. Supplied by the host site.
 *
 * A fetcher may signal failure either way, and both are handled: return a non-ok
 * `Response` (a bare `fetch`, and what the tests use) or throw (`authedFetch` from
 * `@adh-sdk/auth/client`, which is what the site supplies — it throws
 * `AuthHttpError` after its one refresh-and-retry on a 401).
 */
export type Fetcher = (path: string, init?: RequestInit) => Promise<Response>;

/**
 * The backend's standard error envelope is `{ error: { message } }` (`app.ts:403`).
 *
 * Unwrapping it matters more here than on a form: shipr's refusals are the interesting
 * half of the product. "that repository is already registered in this workspace", "folder
 * not found", and above all the unverified-tip refusal are sentences an operator acts on,
 * and handing them the raw JSON instead would bury each one inside a brace.
 */
async function errorMessage(res: Response): Promise<string> {
  const text = await res.text().catch(() => '');
  try {
    const parsed = JSON.parse(text) as { error?: { message?: string } };
    if (typeof parsed?.error?.message === 'string') return parsed.error.message;
  } catch {
    // Not JSON (a proxy's plain-text 502) — the raw text is the best message there is.
  }
  return text || `${res.status} ${res.statusText}`;
}

async function json<T>(res: Response): Promise<T> {
  if (!res.ok) throw new Error(await errorMessage(res));
  return (await res.json()) as T;
}

/** `json`'s void sibling, for the one endpoint that answers 204. Without it a delete that
 *  returned `fetcher`'s promise directly would RESOLVE on a 403 under a bare-`fetch`
 *  fetcher, and a folder that refused to be deleted would vanish from the tree anyway. */
async function ok(res: Response): Promise<void> {
  if (!res.ok) throw new Error(await errorMessage(res));
}

/**
 * shipr's /v1 resources live under `/v1/shipr`. The `/api` prefix in front of it is the
 * **frontend's** — every fleet site rewrites `/api/:path*` to `${BACKEND_URL}/:path*` in
 * its `next.config.ts`. No backend mount carries `/api`.
 */
export const BASE = '/api/v1/shipr';

/** `shipr.groups` is the one shipr table on GENERIC CRUD (`src/crud/policy.ts`), which is
 *  why folders are created and renamed through a different shape than everything else here
 *  — a bare row in, a bare row out, `POST` on the item for the update and a 200 tombstone
 *  for the delete. */
const GROUPS = `${BASE}/groups`;

const seg = encodeURIComponent;

/** `?workspace=<slug>`, or nothing at all. Absent means the caller's OWN workspace, which
 *  is a different thing from an empty one: sending `workspace=` would be a slug the
 *  resolver has to reject. */
function query(params: Record<string, string | number | undefined>): string {
  const parts = Object.entries(params)
    .filter(([, v]) => v !== undefined && v !== '')
    .map(([k, v]) => `${k}=${seg(String(v))}`);
  return parts.length ? `?${parts.join('&')}` : '';
}

/** `RegisterRequest` as /v1's snake_case body. Absent keys stay absent. */
function registerWire(body: RegisterRequest): Record<string, unknown> {
  return {
    slug: body.slug,
    ...(body.connectionId !== undefined ? { connection_id: body.connectionId } : {}),
    ...(body.groupId !== undefined ? { group_id: body.groupId } : {}),
    ...(body.mainBranch !== undefined ? { main_branch: body.mainBranch } : {}),
    ...(body.preparedBranch !== undefined ? { prepared_branch: body.preparedBranch } : {}),
    ...(body.deploymentOwner !== undefined ? { deployment_owner: body.deploymentOwner } : {}),
    ...(body.deploymentName !== undefined ? { deployment_name: body.deploymentName } : {}),
    ...(body.provision !== undefined ? { provision: body.provision } : {}),
  };
}

/** The `environments` and `options` halves of a run request, in /v1's snake_case. */
function runScopeWire(
  body: Pick<RunRequest, 'environments' | 'options'>,
): Record<string, unknown> {
  const o = body.options;
  return {
    ...(body.environments !== undefined ? { environments: body.environments } : {}),
    ...(o !== undefined
      ? {
          options: {
            ...(o.sha !== undefined ? { sha: o.sha } : {}),
            ...(o.shard !== undefined ? { shard: o.shard } : {}),
            ...(o.groupId !== undefined ? { group_id: o.groupId } : {}),
          },
        }
      : {}),
  };
}

const accepted = (res: { run_id: string }): RunAccepted => ({ runId: res.run_id });

/**
 * Everything the console can ask the backend for.
 *
 * `workspace` is fixed at construction rather than passed per call: it is the slug in the
 * URL bar, one per screen, and threading it through thirteen signatures would make
 * "forgot the workspace on one call" a defect the type system cannot see — a tree read in
 * the org workspace beside a register that lands in the caller's personal one.
 *
 * Nothing here polls or retries. A run's output arrives on the stream (`./live`), and a
 * failed request throws with the backend's own sentence in it.
 */
export function createShiprClient(fetcher: Fetcher, workspace?: string) {
  const ws = query({ workspace });

  const send = async <T>(path: string, method: string, body?: unknown) =>
    json<T>(
      await fetcher(path, {
        method,
        ...(body === undefined
          ? {}
          : {
              headers: { 'content-type': 'application/json' },
              body: JSON.stringify(body),
            }),
      }),
    );

  return {
    /** The slug this client acts in, so a caller can build a stream URL that agrees with
     *  the reads it is watching. */
    workspace,

    // --- the tree ----------------------------------------------------------

    /** Every folder and every repository the caller reaches, in ONE request — the HTDV
     *  renders levels, not nodes, so a per-folder fetch would be a round trip per click. */
    tree: async (): Promise<TreeResponse> =>
      shiprTree(await send<ShiprWireTree>(`${BASE}/repos${ws}`, 'GET')),

    /** The details pane: the repository, its ladder, and its recent runs. */
    repo: async (id: string): Promise<RepoDetail> =>
      shiprRepoDetail(await send<ShiprWireRepoDetail>(`${BASE}/repos/${seg(id)}`, 'GET')),

    /** Move it, reorder it, or change which branches it ships to. Absent keys are absent —
     *  a drag-and-drop sends `{ groupId, position }` and touches nothing else. */
    updateRepo: async (id: string, body: RepoPatch): Promise<Repo> =>
      shiprRepo(
        await send<ShiprWireRepo>(`${BASE}/repos/${seg(id)}`, 'POST', {
          ...(body.groupId !== undefined ? { group_id: body.groupId } : {}),
          ...(body.position !== undefined ? { position: body.position } : {}),
          ...(body.slug !== undefined ? { slug: body.slug } : {}),
          ...(body.displayName !== undefined ? { display_name: body.displayName } : {}),
          ...(body.shipBranch !== undefined ? { ship_branch: body.shipBranch } : {}),
          ...(body.envBranches !== undefined ? { env_branches: body.envBranches } : {}),
        }),
      ),


    // --- folders -----------------------------------------------------------

    /** A new folder. `parentId` absent (or null) makes a root.
     *
     *  `path` and `depth` are NOT sent and must not be: both are maintained by
     *  `shipr.group_path()`, the trigger migration 0205 installs, which is also what
     *  refuses a cycle and rewrites a subtree when a folder moves. */
    createGroup: async (body: {
      name: string;
      parentId?: string | null;
      position?: number;
    }): Promise<Group> =>
      shiprGroup(
        await send<ShiprWireGroup>(`${GROUPS}${ws}`, 'POST', {
          name: body.name,
          ...(body.parentId !== undefined ? { parent_id: body.parentId } : {}),
          ...(body.position !== undefined ? { position: body.position } : {}),
        }),
      ),

    /** Rename it, move it under a different parent, or reorder it among its siblings.
     *
     *  POST on the item — /v1's update verb. It still merges: the columns absent from
     *  `body` keep their stored values. */
    updateGroup: async (
      id: string,
      body: { name?: string; parentId?: string | null; position?: number },
    ): Promise<Group> =>
      shiprGroup(
        await send<ShiprWireGroup>(`${GROUPS}/${seg(id)}${ws}`, 'POST', {
          ...(body.name !== undefined ? { name: body.name } : {}),
          ...(body.parentId !== undefined ? { parent_id: body.parentId } : {}),
          ...(body.position !== undefined ? { position: body.position } : {}),
        }),
      ),

    /** Delete it. 200 with a tombstone nobody reads — hence `ok` rather than `json`. */
    deleteGroup: async (id: string) =>
      ok(await fetcher(`${GROUPS}/${seg(id)}${ws}`, { method: 'DELETE' })),

    // --- the toolbar -------------------------------------------------------

    /**
     * The credentials the caller can register a repository with.
     *
     * NO WORKSPACE on this one, and that is not an omission: `integration_connections` is
     * keyed on the person, not on a workspace, so the answer is the same in every one of
     * them. The backend narrows it to what `register` accepts — a GitHub App installation
     * of the caller's, active — so the register form can offer the list verbatim.
     */
    connections: async (): Promise<{ connections: ForgeConnection[] }> => ({
      connections: (await listAllV1<ShiprWireConnection>(`${BASE}/connections`)).map(
        shiprConnection,
      ),
    }),

    /**
     * The repositories one connection was granted — the wizard's first question.
     *
     * No workspace, for `connections`' reason: the answer is a property of the installation.
     *
     * READS WHAT WAS WRITTEN DOWN. The backend answers this from the row the last successful
     * read stored, and reaches GitHub only when there is no row yet — so the picker opens on
     * a list instead of on a spinner, and a slow or unreachable forge shows a stale list
     * rather than an empty one. `readAt` is what stops that being a lie: the wizard says how
     * old the list is, and {@link refreshConnectionRepositories} is how it stops being old.
     */
    connectionRepositories: async (
      id: string,
    ): Promise<{ repositories: ForgeRepository[]; readAt: string }> =>
      shiprForgeRepositories(
        await send<ShiprWireRepositories>(`${BASE}/connections/${seg(id)}/repositories`, 'GET'),
      ),

    /**
     * Ask GitHub again, and store what it says.
     *
     * A POST because it writes. Separate from the read for the reason the backend keeps them
     * separate: the read cannot fail in a way worth reporting and this one can — a revoked
     * installation, a suspended app, a forge that is down — and a caller needs to be able to
     * tell "here is the list" from "here is the list, and it is the one from before".
     */
    refreshConnectionRepositories: async (
      id: string,
    ): Promise<{ repositories: ForgeRepository[]; readAt: string }> =>
      shiprForgeRepositories(
        await send<ShiprWireRepositories>(
          `${BASE}/connections/${seg(id)}/repositories/refresh`,
          'POST',
        ),
      ),

    /**
     * What a repository's `.shipr` declares — the wizard's second question, and usually the
     * answer that there is no second question to ask.
     *
     * The console READS the file and never writes it. Declaring shards stays an edit an
     * operator makes in a repository and reviews in a diff; a form that could override a
     * declared slug is exactly the drift the CLI refuses when `--org` is passed alongside
     * `--deployment`.
     */
    connectionDeclaration: async (
      id: string,
      slug: string,
      branch?: string,
    ): Promise<DeclarationResponse> =>
      shiprDeclaration(
        (
          await send<{ declaration: ShiprWireDeclaration }>(
            withV1Query(`${BASE}/connections/${seg(id)}`, {
              'include[]': ['declaration'],
              slug,
              branch: branch || undefined,
            }),
            'GET',
          )
        ).declaration,
      ),

    /**
     * Register a repository — the one operation that creates rows rather than moving
     * commits. 202: the provisioning itself is a queued run, and `devRepo` is the row it
     * will provision mirrors for.
     */
    register: async (body: RegisterRequest): Promise<RegisterAccepted> => {
      const res = await send<{ run_id: string; dev_repo: ShiprWireDevRepo }>(
        `${BASE}/repos${ws}`,
        'POST',
        registerWire(body),
      );
      return { runId: res.run_id, devRepo: shiprDevRepo(res.dev_repo) };
    },

    /**
     * Write down where a repository's mirrors GO, and create nothing.
     *
     * The same route, `provision: false`, and 201 rather than 202: the rows are written
     * synchronously, `registeredAt` stays null on every one of them, and no run is queued.
     * That is the whole of what Add does now — a deployment repository created under a name
     * nobody has looked at yet is the mistake this split exists to prevent, and it is not
     * one an unregister undoes, because the repository on the forge stays.
     *
     * Provisioning it later is `run({ operation: 'register', scopeKind: 'dev_repo', ... })`,
     * which is the identical operation the queue would have run — there is no second path.
     */
    configure: async (body: Omit<RegisterRequest, 'provision'>): Promise<RegisterConfigured> => {
      const res = await send<{
        dev_repo: ShiprWireDevRepo;
        mirrors: ShiprWireRepo[];
        notes?: string[];
      }>(`${BASE}/repos${ws}`, 'POST', registerWire({ ...body, provision: false }));
      return {
        devRepo: shiprDevRepo(res.dev_repo),
        mirrors: res.mirrors.map(shiprRepo),
        ...(res.notes !== undefined ? { notes: res.notes } : {}),
      };
    },

    // --- per-org defaults --------------------------------------------------

    /**
     * What each forge org's repositories are born with — all of them, in one read.
     *
     * A LIST AND NOT A LOOKUP, because the org menu already shows every account the
     * caller's installations reach: one request fills every gear icon at once, and an org
     * nobody has configured is simply ABSENT rather than a 404 the caller has to learn to
     * read as "unset".
     */
    orgDefaults: async (): Promise<{ orgDefaults: OrgDefaults[] }> => ({
      orgDefaults: (await listAllV1<ShiprWireOrgDefaults>(`${BASE}/org_defaults${ws}`)).map(
        shiprOrgDefaults,
      ),
    }),

    /**
     * Set one org's defaults. Upsert — "the defaults for this org" is one row whether or
     * not anybody has written it yet, so the dialog's Apply does not behave differently the
     * second time it is pressed.
     *
     * IT PROVISIONS NOTHING AND CHANGES NO MIRROR THAT ALREADY EXISTS: a default is read
     * when a mirror is BORN, so writing one re-aims the next repository and leaves every
     * registered one where the operator put it. Applying it to the ones already there is
     * the dialog's own walk over `updateRepo`.
     */
    setOrgDefaults: async (org: string, body: OrgDefaultsPatch): Promise<OrgDefaults> =>
      shiprOrgDefaults(
        await send<ShiprWireOrgDefaults>(`${BASE}/org_defaults/${seg(org)}${ws}`, 'POST', {
          ...(body.deploymentOwner !== undefined ? { deployment_owner: body.deploymentOwner } : {}),
          ...(body.nameSuffix !== undefined ? { name_suffix: body.nameSuffix } : {}),
          ...(body.envBranches !== undefined ? { env_branches: body.envBranches } : {}),
        }),
      ),

    /**
     * The toolbar, as one call: an operation and a scope.
     *
     * `deploy_repo` is one mirror, `dev_repo` a repository and all its shards, `group` a
     * folder and everything nested under it, `all` the workspace. A run over a folder walks
     * its repositories ONE AT A TIME in the tree's own order.
     */
    run: async (body: RunRequest): Promise<RunAccepted> =>
      accepted(
        await send<{ run_id: string }>(`${BASE}/runs${ws}`, 'POST', {
          operation: body.operation,
          scope_kind: body.scopeKind,
          ...(body.scopeId !== undefined ? { scope_id: body.scopeId } : {}),
          ...runScopeWire(body),
        }),
      ),

    /** The four per-repository buttons. Sugar over `run` — same gate, same queue — for the
     *  common case where the scope is the row the operator has selected. */
    runOnRepo: async (
      id: string,
      operation: 'status' | 'prepare' | 'deploy' | 'unregister',
      body: Omit<RunRequest, 'operation' | 'scopeKind' | 'scopeId'> = {},
    ): Promise<RunAccepted> =>
      accepted(
        // Unregister is /v1's DELETE on the repository: it answers 202 with the run, takes
        // no body, and there is nothing to send it.
        operation === 'unregister'
          ? await send<{ run_id: string }>(`${BASE}/repos/${seg(id)}`, 'DELETE')
          : await send<{ run_id: string }>(
              `${BASE}/repos/${seg(id)}/${operation}`,
              'POST',
              runScopeWire(body),
            ),
      ),

    // --- runs --------------------------------------------------------------

    /** The runs the caller may watch, newest first. */
    runs: async (limit: number = V1_PAGE_MAX): Promise<{ items: Run[] }> => {
      const page = await send<V1List<ShiprWireRun>>(
        `${BASE}/runs${query({ workspace, limit })}`,
        'GET',
      );
      return { items: page.data.map(shiprRun) };
    },

    /**
     * Stop a run.
     *
     * A STOP, NOT AN UNDO — a folder deploy halted at the fourth of eleven has carried four
     * of them, and the log says which. The backend retires the run's lease rather than
     * messaging the worker, so the stop lands within a heartbeat wherever the run is being
     * held. Idempotent: a run that has already settled comes back unchanged.
     */
    cancelRun: async (id: string): Promise<{ run: Run }> => ({
      run: shiprRun(await send<ShiprWireRun>(`${BASE}/runs/${seg(id)}/cancel`, 'POST')),
    }),

    /** One run and its steps, oldest step first — which is the order it walked them. */
    runDetail: async (id: string): Promise<{ run: Run; steps: RunStep[] }> => {
      const res = await send<{ run: ShiprWireRun; steps: ShiprWireRunStep[] }>(
        `${BASE}/runs/${seg(id)}`,
        'GET',
      );
      return { run: shiprRun(res.run), steps: res.steps.map(shiprRunStep) };
    },

    /**
     * A page of the run's log.
     *
     * The SAME cursor the stream uses, so the pane can start here and switch to the stream
     * — or fall back to this when EventSource is unavailable — without a second notion of
     * position. Send back the `nextSeq` it answered with.
     */
    events: async (id: string, after = 0, limit?: number, repo?: string): Promise<EventPage> =>
      shiprEventPage(
        id,
        await send<ShiprWireEventPage>(
          `${BASE}/runs/${seg(id)}/events${query({ after, limit, repo })}`,
          'GET',
        ),
      ),
  };
}

export type ShiprClient = ReturnType<typeof createShiprClient>;
