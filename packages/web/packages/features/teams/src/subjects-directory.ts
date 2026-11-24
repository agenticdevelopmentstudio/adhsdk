"use client";

// The DEFAULT subjects directory for ItemAccessPanel mounts: the share targets a
// workspace offers — its human members, its personas, and its teams — resolved from
// the shared platform APIs. Hosts with a richer member registry can still inject
// their own (the `subjectsDirectory` prop stays the seam); this helper is the
// batteries-included composition so every mount doesn't re-glue the same three reads.
// Each source degrades independently: a personal workspace has no org-members route
// (404 → no customer rows beyond what assignments already show), a workspace with no
// ecosystem lists no teams — partial results beat an all-or-nothing failure.

import { listAllV1 } from "@adh-sdk/auth/client";
import { api as personasApi } from "@adh-sdk/data/personas";
import { teamsApi } from "@adh-sdk/data/teams";
import { ecosystemsApi } from "@adh-sdk/data/ecosystems";
import type { AccessSubject } from "./ItemAccessPanel";

export async function workspaceSubjectsDirectory(
  workspaceSlug: string,
): Promise<AccessSubject[]> {
  const [members, personas, teams] = await Promise.all([
    listAllV1<{ user_id: string; display_name: string | null; email: string | null }>(
      `/api/v1/workspaces/${encodeURIComponent(workspaceSlug)}/members`,
    )
      .then((rows) =>
        rows.map(
          (m): AccessSubject => ({
            kind: "customer",
            id: m.user_id,
            label: m.display_name || m.email || m.user_id,
          }),
        ),
      )
      .catch(() => [] as AccessSubject[]),
    personasApi.personas
      .list({ workspace: workspaceSlug })
      .then((ps) =>
        ps.map((p): AccessSubject => ({ kind: "persona", id: p.id, label: p.name || p.slug })),
      )
      .catch(() => [] as AccessSubject[]),
    ecosystemsApi
      .ecosystemIdForSlug(workspaceSlug)
      .then((id) => (id ? teamsApi.list(id) : []))
      .then((ts) => ts.map((t): AccessSubject => ({ kind: "team", id: t.id, label: t.displayName })))
      .catch(() => [] as AccessSubject[]),
  ]);
  return [...members, ...personas, ...teams];
}
