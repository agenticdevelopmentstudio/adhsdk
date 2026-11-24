"use client";

// An ORGANIZATION workspace's people roster.

import { listAllV1 } from "../http";
import { enc } from "../client-helpers";
import type { WorkspaceMemberWire, WorkspaceMembersResponse } from "./wire";

export type { WorkspaceMember, WorkspaceMembersResponse } from "./wire";

export const workspaceMembersApi = {
  /** An ORGANIZATION workspace's roster: the distinct customers across the org's
   *  org-owned teams. 404 for non-org slugs and orgs the caller isn't a member of. */
  async list(slug: string): Promise<WorkspaceMembersResponse> {
    const rows = await listAllV1<WorkspaceMemberWire>(`/api/v1/workspaces/${enc(slug)}/members`);
    return {
      members: rows.map((r) => ({
        userId: r.user_id,
        ...(r.email !== undefined ? { email: r.email } : {}),
        ...(r.display_name !== undefined ? { displayName: r.display_name } : {}),
        isAdmin: r.is_admin,
        addedAt: r.added_at,
      })),
    };
  },
};
