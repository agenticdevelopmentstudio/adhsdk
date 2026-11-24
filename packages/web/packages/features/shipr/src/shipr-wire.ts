import { unixToIso } from '@adh-sdk/auth/client';

import type {
  AccessVerb,
  DeclarationResponse,
  DevRepo,
  Environment,
  EventPage,
  ForgeConnection,
  ForgeRepository,
  Group,
  Ladder,
  OrgDefaults,
  Operation,
  Repo,
  RepoDetail,
  RepoItem,
  RepoState,
  Run,
  RunEvent,
  RunState,
  RunStep,
  ScopeKind,
  TreeResponse,
  Workspace,
} from './types';

/**
 * The /v1 wire shapes shipr reads, and the field-by-field mappers that turn them into the
 * camelCase domain types the console consumes (`./types`). Written out one key at a time on
 * purpose: `envBranches`, a run's `summary`, a step's `detail` and a repo item's `state` are
 * maps whose keys are DATA, and a generic snake-to-camel pass would rename them.
 *
 * `state` is the one bag worth naming: /v1's schema declares it as a bare object, so the
 * gateway leaves its keys exactly as the legacy route wrote them — camelCase (`readAt`,
 * `deployRepoId`) — and it is passed through here as the `RepoState` it already is.
 */

export interface ShiprWireGroup {
  id: string;
  parent_id: string | null;
  name: string;
  path: string;
  depth: number;
  position: number;
}

export interface ShiprWireDevRepo {
  id: string;
  slug: string;
  display_name: string | null;
  main_branch: string;
  prepared_branch: string;
  declaration_sha: string | null;
  connection_id: string | null;
}

export interface ShiprWireRepo {
  id: string;
  dev_repo_id: string;
  group_id: string | null;
  slug: string;
  shard: string;
  ship_branch: string;
  env_branches: Partial<Record<Environment, string>>;
  registered_at: string | null;
  position: number;
}

export interface ShiprWireLadder {
  columns: string[];
  rows: Ladder['rows'];
  settled: boolean;
  read_at?: string;
}

export interface ShiprWireRun {
  id: string;
  operation: Operation;
  scope_kind: ScopeKind;
  scope_id: string | null;
  environments: Environment[];
  state: RunState;
  summary: unknown;
  started_at: string | null;
  finished_at: string | null;
  created: number;
}

export interface ShiprWireRunStep {
  id: string;
  run_id: string;
  deploy_repo_id: string | null;
  ordinal: number;
  environment: Environment | null;
  stage: 'advance' | 'arrival' | 'verify' | null;
  state: string;
  detail: unknown;
}

export interface ShiprWireRunEvent {
  seq: number;
  step_id: string | null;
  stream: 'out' | 'err' | 'meta';
  text: string;
  at: string;
}

export interface ShiprWireRepoItem extends ShiprWireRepo {
  dev_repo: ShiprWireDevRepo | null;
  state: RepoState | null;
}

export interface ShiprWireTree {
  workspace: { kind: Workspace['kind']; owner_id: string };
  verbs: AccessVerb[];
  groups: ShiprWireGroup[];
  items: ShiprWireRepoItem[];
}

export interface ShiprWireRepoDetail {
  repo: ShiprWireRepo;
  dev_repo: ShiprWireDevRepo | null;
  group: ShiprWireGroup | null;
  ladder: ShiprWireLadder | null;
  runs: ShiprWireRun[];
}

export interface ShiprWireEventPage {
  events: ShiprWireRunEvent[];
  next_seq: number;
  state: RunState;
  done: boolean;
}

export interface ShiprWireConnection {
  id: string;
  label: string;
  account_login: string | null;
}

export interface ShiprWireRepositories {
  repositories: { slug: string; default_branch: string; private: boolean }[];
  read_at: string;
}

export interface ShiprWireDeclaration {
  deployments: { shard: string; slug: string }[] | null;
  fallback_slug: string;
  note?: string;
}

export interface ShiprWireOrgDefaults {
  id: string;
  org: string;
  deployment_owner: string | null;
  name_suffix: string;
  env_branches: Partial<Record<Environment, string>>;
  created: number;
  updated: number;
}

export const shiprGroup = (g: ShiprWireGroup): Group => ({
  id: g.id,
  parentId: g.parent_id,
  name: g.name,
  path: g.path,
  depth: g.depth,
  position: g.position,
});

export const shiprDevRepo = (d: ShiprWireDevRepo): DevRepo => ({
  id: d.id,
  slug: d.slug,
  displayName: d.display_name,
  mainBranch: d.main_branch,
  preparedBranch: d.prepared_branch,
  declarationSha: d.declaration_sha,
  connectionId: d.connection_id,
});

export const shiprRepo = (r: ShiprWireRepo): Repo => ({
  id: r.id,
  devRepoId: r.dev_repo_id,
  groupId: r.group_id,
  slug: r.slug,
  shard: r.shard,
  shipBranch: r.ship_branch,
  envBranches: r.env_branches,
  registeredAt: r.registered_at,
  position: r.position,
});

export const shiprLadder = (l: ShiprWireLadder): Ladder => ({
  columns: l.columns,
  rows: l.rows,
  settled: l.settled,
  ...(l.read_at !== undefined ? { readAt: l.read_at } : {}),
});

/** /v1 carries no `updated` for a run, so `updatedAt` is the latest moment the run itself
 *  records. Live ticks (`./live`) overwrite it with the real one. */
export const shiprRun = (r: ShiprWireRun): Run => {
  const createdAt = unixToIso(r.created);
  return {
    id: r.id,
    operation: r.operation,
    scopeKind: r.scope_kind,
    scopeId: r.scope_id,
    environments: r.environments,
    state: r.state,
    summary: r.summary,
    startedAt: r.started_at,
    finishedAt: r.finished_at,
    createdAt,
    updatedAt: r.finished_at ?? r.started_at ?? createdAt,
  };
};

/** /v1's step has no timestamps, so both are null. */
export const shiprRunStep = (s: ShiprWireRunStep): RunStep => ({
  id: s.id,
  runId: s.run_id,
  deployRepoId: s.deploy_repo_id,
  ordinal: s.ordinal,
  environment: s.environment,
  stage: s.stage,
  state: s.state,
  detail: s.detail,
  startedAt: null,
  finishedAt: null,
});

/** /v1's event row is `{seq, step_id, stream, text, at}`; the run id is the caller's and a
 *  row's identity within it is its `seq`. */
export const shiprRunEvent = (runId: string, e: ShiprWireRunEvent): RunEvent => ({
  id: `${runId}:${e.seq}`,
  runId,
  stepId: e.step_id,
  seq: e.seq,
  stream: e.stream,
  text: e.text,
  at: e.at,
});

export const shiprRepoItem = (i: ShiprWireRepoItem): RepoItem => ({
  ...shiprRepo(i),
  devRepo: i.dev_repo ? shiprDevRepo(i.dev_repo) : null,
  state: i.state ?? null,
});

export const shiprTree = (t: ShiprWireTree): TreeResponse => ({
  workspace: { kind: t.workspace.kind, ownerId: t.workspace.owner_id },
  verbs: t.verbs,
  groups: t.groups.map(shiprGroup),
  items: t.items.map(shiprRepoItem),
});

export const shiprRepoDetail = (d: ShiprWireRepoDetail): RepoDetail => ({
  repo: shiprRepo(d.repo),
  devRepo: d.dev_repo ? shiprDevRepo(d.dev_repo) : null,
  group: d.group ? shiprGroup(d.group) : null,
  ladder: d.ladder ? shiprLadder(d.ladder) : null,
  runs: d.runs.map(shiprRun),
});

export const shiprEventPage = (runId: string, p: ShiprWireEventPage): EventPage => ({
  events: p.events.map((e) => shiprRunEvent(runId, e)),
  nextSeq: p.next_seq,
  state: p.state,
  done: p.done,
});

export const shiprConnection = (c: ShiprWireConnection): ForgeConnection => ({
  id: c.id,
  label: c.label,
  accountLogin: c.account_login,
});

export const shiprForgeRepositories = (
  r: ShiprWireRepositories,
): { repositories: ForgeRepository[]; readAt: string } => ({
  repositories: r.repositories.map((f) => ({
    slug: f.slug,
    defaultBranch: f.default_branch,
    private: f.private,
  })),
  readAt: r.read_at,
});

export const shiprDeclaration = (d: ShiprWireDeclaration): DeclarationResponse => ({
  deployments: d.deployments,
  fallbackSlug: d.fallback_slug,
  ...(d.note !== undefined ? { note: d.note } : {}),
});

export const shiprOrgDefaults = (o: ShiprWireOrgDefaults): OrgDefaults => ({
  id: o.id,
  org: o.org,
  deploymentOwner: o.deployment_owner,
  nameSuffix: o.name_suffix,
  envBranches: o.env_branches,
  createdAt: unixToIso(o.created),
  updatedAt: unixToIso(o.updated),
});
