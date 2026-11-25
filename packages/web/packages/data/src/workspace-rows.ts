// Pure helpers over `/v1/workspaces` rows — no React, no fetch, so a server module can use them.
//
// Moved from the hub (`data/workspace-features.ts`, `data/workspace-slugs.ts`) so every surface
// that offers workspaces — the hub's switcher and a satellite's — names, labels and de-duplicates
// them one way.

import type { WorkspaceType } from "./workspaces";

/**
 * A workspace's stable id across types: `<type>:<slug>`. A slug is unique only WITHIN a type (an
 * organization and a team can share one, and so can two teams), so anything that names a workspace
 * across that boundary — a React key, a menu row id — has to carry both. Rows that share a slug are
 * reduced to the first by {@link firstWorkspacePerSlug}, which is also the only row a bare
 * `/<slug>` can open.
 */
export function workspaceCompositeId(ws: { type: WorkspaceType; slug: string }): string {
  return `${ws.type}:${ws.slug}`;
}

/** A workspace's label in a list: its name, or for a nameless one "My Workspace" (personal) or
 *  "Workspace". */
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
