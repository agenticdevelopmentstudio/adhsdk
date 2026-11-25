"use client";

// The caller's workspaces — the owning principals they can act as.
//
// A workspace is a slug the backend resolves to an owning principal (see the
// backend's `resolveWorkspaceOwner`): the caller's own personal slug, or an
// organization they belong to. It is what `?workspace=<slug>` pins a list/create
// to, so it is the natural ROOT of a feature site's hierarchical stack.
//
// The backend's `/workspaces` also returns `team` rows, but a team is a membership
// grouping, NOT an owning principal — `?workspace=<teamSlug>` 404s. So `list()`
// drops them: every row it returns is one a feature can actually be scoped to.
// (The hub's own switcher shows teams because it navigates to team routes; this
// client exists for owner-scoping, which is a strictly smaller set.)

import { authedJson } from "./http";
import { v1List } from "./v1-case";
import { sortByText } from "./client-helpers";
import { getToolkitQueryClient } from "./query";
import { revalidateResources } from "./use-resource-list";

/** A principal the caller can scope a feature to: their personal workspace, or an org's. */
export interface Workspace {
  slug: string;
  name: string;
  kind: "individual" | "organization";
}

/**
 * The react-query key for {@link workspacesApi.list} — exported because the list goes stale from
 * OUTSIDE this module: renaming an organization moves its slug, and the workspace bar, the
 * switcher and every feature rail read it. Published here so a host and a feature invalidate the
 * same cache entry rather than each holding a private key for the same endpoint.
 */
export const WORKSPACES_QUERY_KEY = ["workspaces"] as const;

/**
 * The react-query key for {@link workspacesApi.listAll} — every row, teams included, as
 * `WorkspaceRow[]` (`useWorkspaces`, the header's workspace menu). Its OWN key, not
 * {@link WORKSPACES_QUERY_KEY}: that entry holds `list()`'s `Workspace[]` (`kind`, no teams), and
 * two shapes under one key would hand each reader the other's array. Not a prefix of it either, so
 * a sweep of one never silently means the other; {@link notifyWorkspacesChanged} names both.
 */
export const WORKSPACE_ROWS_QUERY_KEY = ["workspace-rows"] as const;

/** The window event {@link notifyWorkspacesChanged} fires. Exported for tests and for a host that
 *  would rather listen directly than through {@link onWorkspacesChanged}. */
export const WORKSPACES_CHANGED_EVENT = "adh:workspaces-changed";

/**
 * Announce that the workspace LIST gained or lost a row. Creating an organization is the action
 * that does it today; archiving one is the other direction.
 *
 * A WINDOW EVENT rather than an invalidation, because the list is cached more than once and the
 * copies do not share a client:
 *
 *  - the toolkit's client, under {@link WORKSPACES_QUERY_KEY} — the fleet's switcher;
 *  - the toolkit's resource cache, under `useResourceList('workspaces')` — SiteHomeShell's chooser,
 *    which is a different entry over the same endpoint;
 *  - **the host app's own client**, which is a different PHYSICAL react-query module from this one
 *    (see `@adh-sdk/data/query`). The hub bundles its own copy, so its provider is
 *    invisible to any toolkit component and no `useQueryClient()` here can ever reach it. That is
 *    the bug this exists for: an org created from the Organizations rail refetched the org list and
 *    left the hub's workspace switcher showing the pre-create list for the whole 5-minute
 *    `staleTime`. `colorMode` crosses the same boundary the same way.
 *
 * The two caches this module CAN reach are swept here, so one call is the whole announcement. A
 * host with its own cache subscribes with {@link onWorkspacesChanged}.
 */
export function notifyWorkspacesChanged(): void {
  const client = getToolkitQueryClient();
  void client.invalidateQueries({ queryKey: WORKSPACES_QUERY_KEY }).catch(() => {});
  void client.invalidateQueries({ queryKey: WORKSPACE_ROWS_QUERY_KEY }).catch(() => {});
  revalidateResources((cacheKey) => cacheKey === "workspaces");
  if (typeof window === "undefined") return;
  const event = new CustomEvent(WORKSPACES_CHANGED_EVENT);
  sentByThisCopy.add(event);
  window.dispatchEvent(event);
}

/** The change events THIS copy of the module dispatched. Its own caches were already swept before
 *  the dispatch, so a listener inside this copy that would sweep them again skips these (see
 *  {@link onWorkspacesChangedElsewhere}). Weak, so a dispatched event is not kept alive by it. */
const sentByThisCopy = new WeakSet<Event>();

/** Subscribe a host's own cache to {@link notifyWorkspacesChanged}. Returns the unsubscribe, so it
 *  is an effect body on its own: `useEffect(() => onWorkspacesChanged(fn), [fn])`. */
export function onWorkspacesChanged(listener: () => void): () => void {
  if (typeof window === "undefined") return () => {};
  window.addEventListener(WORKSPACES_CHANGED_EVENT, listener);
  return () => window.removeEventListener(WORKSPACES_CHANGED_EVENT, listener);
}

/**
 * {@link onWorkspacesChanged}, minus the announcements this copy of the module made itself. For a
 * listener that sweeps a cache {@link notifyWorkspacesChanged} already sweeps directly (the
 * toolkit client), so one change is one invalidation there, not two: react-query's
 * `invalidateQueries` cancels a refetch in flight and starts another, so a second sweep is a
 * second request. An event another copy sent (a host bundling its own `@adh-sdk/data`) still
 * reaches it, because that copy's sweep reached that copy's client, not this one's.
 *
 * Internal to the package: a host's own cache is never swept by `notifyWorkspacesChanged`, so a
 * host always wants every event and uses {@link onWorkspacesChanged}.
 */
export function onWorkspacesChangedElsewhere(listener: () => void): () => void {
  if (typeof window === "undefined") return () => {};
  const onChange = (event: Event) => {
    if (!sentByThisCopy.has(event)) listener();
  };
  window.addEventListener(WORKSPACES_CHANGED_EVENT, onChange);
  return () => window.removeEventListener(WORKSPACES_CHANGED_EVENT, onChange);
}

/** `GET /v1/handles/{handle}`, verbatim: `reason` says which test refused it. */
export interface SlugAvailability {
  available: boolean;
  reason?: "format" | "taken";
}

/**
 * Is `slug` free to claim in the workspace URL namespace?
 *
 * ONE namespace, deliberately: a user's handle and an organization's occupy the same URL space,
 * so the endpoint answers about both and a form editing either must ask it. It excludes only the
 * CALLER's own user row — an org editing its own handle must therefore skip the probe for its
 * current slug, or its live row comes back "taken" and the form refuses the value it already has.
 */
export function checkWorkspaceSlugAvailable(slug: string): Promise<SlugAvailability> {
  return authedJson<SlugAvailability>(`/api/v1/handles/${encodeURIComponent(slug)}`);
}

/** What a `/v1/workspaces` row is: a personal workspace, an organization's, or a team's. Pinned
 *  EXACTLY to the generated spec's enum by adh-api-types' `data-workspace-wire.test-d.ts`, so a
 *  fourth type the backend adds fails that package's type-check instead of reaching the menu. */
export type WorkspaceType = "individual" | "organization" | "team";

/**
 * One `/v1/workspaces` row as {@link fromV1} maps it (`FromV1` of the generated spec's `Workspace`
 * list row, its `object` tag dropped) — teams included. The backend returns them priority-ordered
 * (individual → organization → team), and a slug is unique only within a type.
 *
 * Written out rather than derived, because the spec lives in `@adh-sdk/adh-api-types`, the adh
 * vocabulary tier above this portable package, and `tools/check_boundaries.py` refuses that import
 * (it resolves inside adh's workspace and fails in every other consumer). The transcription is
 * still held to the spec, the sanctioned way round: adh-api-types' `data-workspace-wire.test-d.ts`
 * requires the generated row, through `FromV1`, to satisfy this interface, so a backend rename or
 * retype regenerates its schema and fails that type-check.
 */
export interface WorkspaceRow {
  slug: string;
  name: string;
  type: WorkspaceType;
}

/** The cursor a /v1 workspace row pages by: its slug, the only key the row carries. With the
 *  default `id` cursor, anyone with more than one page of workspaces got an error, not a list. */
export function workspaceCursor(row: unknown): string | undefined {
  const slug = (row as { slug?: unknown } | null)?.slug;
  return typeof slug === "string" ? slug : undefined;
}

export const workspacesApi = {
  /** Every row the caller can switch to, teams included, in the backend's order. What a switcher
   *  that NAVIGATES lists (the hub's, which has team routes); {@link workspacesApi.list} is the
   *  owner-scopable subset. */
  async listAll(): Promise<WorkspaceRow[]> {
    return v1List<WorkspaceRow>("/api/v1/workspaces", { cursorOf: workspaceCursor });
  },
  /** The caller's personal workspace first, then their organizations (A→Z). */
  async list(): Promise<Workspace[]> {
    const rows = await workspacesApi.listAll();
    const own = rows.filter((r) => r.type === "individual");
    const orgs = rows.filter((r) => r.type === "organization");
    return [...own, ...sortByText(orgs, (o) => o.name)].map((r) => ({
      slug: r.slug,
      name: r.name,
      kind: r.type as Workspace["kind"],
    }));
  },
};
