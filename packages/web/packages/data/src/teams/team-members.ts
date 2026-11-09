// Team members API client — wired to the backend route /api/v1/team_members. A member is either an existing
// customer (added by EMAIL, resolved to a customer in the ecosystem — 404 if none) or one
// of the caller's personas (added by key, gated on the persona's may_act 'team' grant).
// The backend enforces the team owner/admin scope and guards duplicates (409). authedJson
// throws an Error carrying the backend's message, so callers surface e.message inline.
// Types are hand-declared: this route is off the generated OpenAPI surface.

import { authedJson, authedRequest, listAllV1, withV1Query } from "../http";
import type { TeamMemberRow } from "./wire";
import { enc } from "../client-helpers";

export interface TeamMember {
  id: string;
  teamId: string;
  userId: string;
  role: string;
  addedAt: string;
  /** Discriminates a customer member from a persona member. Present on every GET row;
   *  treat anything other than 'persona' as a customer (robust to the api-types field
   *  still being optional). */
  memberKind: "customer" | "persona";
  /** Resolved from the member's customer row; null if outside the caller's ecosystem. */
  email: string | null;
  displayName: string | null;
  /** Set only for persona members (null for customers). */
  personaSlug: string | null;
  personaName: string | null;
}

const BASE = "/api/v1/team_members";

export function toTeamMember(r: TeamMemberRow): TeamMember {
  return {
    id: r.id,
    teamId: r.team_id,
    userId: r.user_id,
    role: r.role,
    addedAt: r.added_at,
    memberKind: r.member_kind === "persona" ? "persona" : "customer",
    email: r.email ?? null,
    displayName: r.display_name ?? null,
    personaSlug: r.persona_slug ?? null,
    personaName: r.persona_name ?? null,
  };
}

export const teamMembersApi = {
  async list(teamId: string): Promise<TeamMember[]> {
    const rows = await listAllV1<TeamMemberRow>(withV1Query(BASE, { team_id: teamId }));
    return rows.map(toTeamMember);
  },

  /** Member count per team in the caller's scope (`GET /v1/team_members?include[]=total_count`).
   *
   *  It was built for the All-teams landing cards, and **nothing in the fleet calls it now** —
   *  that landing is gone, and an unselected teams frontier is the select hint, which decorates
   *  nothing (see the `overview` rule). `TeamsFeature.test.tsx` asserts the absence rather than
   *  leaving it to drift. Kept because the route it wraps is live and this client mirrors the
   *  backend's surface, not the current callers'; delete it with the route, not before. */
  async counts(): Promise<Map<string, number>> {
    const body = await authedJson<{
      total_count?: { counts?: Array<{ team_id: string; count: number }> };
    }>(withV1Query(BASE, { "include[]": ["total_count"] }));
    return new Map((body.total_count?.counts ?? []).map((c) => [c.team_id, c.count]));
  },

  /** Add an existing customer (by email) to the team. Throws the backend's message on
   *  404 (no such user) / 409 (already a member); the caller surfaces it inline. */
  add(teamId: string, email: string): Promise<TeamMember> {
    return authedJson<TeamMemberRow>(BASE, {
      method: "POST",
      body: JSON.stringify({ team_id: teamId, email }),
    }).then(toTeamMember);
  },

  /** Add one of the caller's personas to the team. The backend enforces the persona has
   *  been granted may_act 'team' (403 otherwise) and 404s an unknown persona; the caller
   *  surfaces the thrown message inline. */
  async addPersona(teamId: string, personaKey: string): Promise<TeamMember> {
    const row = await authedJson<TeamMemberRow>(BASE, {
      method: "POST",
      body: JSON.stringify({ type: "persona", team_id: teamId, persona_key: personaKey }),
    });
    return toTeamMember(row);
  },

  remove(memberId: string): Promise<void> {
    return authedRequest(`${BASE}/${enc(memberId)}`, { method: "DELETE" });
  },
};
