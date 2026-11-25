// Pure helpers over `/v1/workspaces` rows — no React, no fetch, so a server module can use them.
//
// Moved from the hub (`data/workspace-features.ts`, `data/workspace-slugs.ts`) so every surface
// that offers workspaces — the hub's switcher and a satellite's — names, labels and de-duplicates
// them one way.

import type { WorkspaceType } from "./workspaces";

/**
 * A workspace's selection id across types: `<type>:<slug>`. A slug alone isn't unique across TYPES
 * (a personal workspace and a team can share one, and so can an organization and a team), so
 * anything that names a workspace across that boundary — a React key, a menu row id — has to carry
 * both.
 *
 * NOT unique on its own either: a team's slug is unique only within its owner, so two teams under
 * different owners share this id. A workspace menu gets unique ids only because the header's
 * workspaces feed first keeps one row per slug ({@link firstWorkspacePerSlug}), which is also the
 * only row a bare `/<slug>` can open. The id is never decoded back into a slug: the feed maps a
 * picked id to its row's slug with its own lookup over those same kept rows.
 */
export function workspaceCompositeId(ws: { type: WorkspaceType; slug: string }): string {
  return `${ws.type}:${ws.slug}`;
}

/** What a workspace is CALLED in the UI — the hub's workspaces-rail row, every site's header
 *  workspace menu, and the title of the workspace's own topic list (and, through the hub's
 *  `workspaceTitle`, its banner). Every type reads by its own name: the backend already names the
 *  individual workspace after its owner (`displayName ?? slug`, see listWorkspacesForUser), so a
 *  personal workspace shows the USER'S NAME rather than a generic "My Workspace". Kept as one
 *  function so all those surfaces can never drift.
 *
 *  The blank fallback is load-bearing, not defensive noise: the backend's `displayName ?? slug`
 *  is NULLISH-coalescing, so a display name saved as the empty string arrives here as `''` — and
 *  every consumer treats `''` as a present value (the hub breadcrumb's `?? selectedId` fallback
 *  does not fire, the rail row gets an empty accessible name). Reading a name is the whole point of
 *  this function, so it is also the only place that can refuse to return nothing. */
export function workspaceListLabel(ws: { name: string; type: WorkspaceType }): string {
  const name = ws.name.trim();
  if (name) return name;
  return ws.type === "individual" ? "My Workspace" : "Workspace";
}

/**
 * The workspaces a bare `/<slug>` can reach: the FIRST row of each slug, in list order.
 *
 * A slug is not unique (see {@link workspaceCompositeId}). The hub's URL carries the bare slug and
 * resolves it with `rows.find(w => w.slug === slug)` over GET /workspaces, which the backend
 * returns priority-ordered (individual → organization → team), so of the rows sharing a slug only
 * the first can ever be opened. Offering the others lists a row that opens its namesake, and a menu
 * that marks the current row by slug highlights all of them at once.
 *
 * Generic over the row so each caller maps the survivors to its own shape afterwards.
 */
export function firstWorkspacePerSlug<T extends { slug: string }>(workspaces: readonly T[]): T[] {
  const seen = new Set<string>();
  return workspaces.filter((w) => {
    if (seen.has(w.slug)) return false;
    seen.add(w.slug);
    return true;
  });
}
