// Local wire types for the Teams clients — the /v1 rows + request-body shapes the
// clients read/send (see projects/wire.ts for the pattern: these replace the hub's
// generated `SuccessBody<...>` / `RequestBody<...>` from `@adh-sdk/adh-api-types`,
// adh product vocabulary a generic data client must not take on). Each interface
// carries exactly the fields the mappers and call sites touch. Type-only file.

/** `/v1/teams` row (list, get, create, update). `created`/`updated` are UNIX seconds. */
export interface TeamRow {
  object?: "team";
  id: string;
  name: string;
  /** Lowercase slug, unique within the owning ecosystem, e.g. `participants`. */
  slug: string;
  created: number;
  updated: number;
}

/** `POST /v1/teams` body. */
export interface TeamCreateBody {
  name: string;
  slug: string;
}

/** `POST /v1/teams/{id}` body — a partial update. */
export interface TeamPutBody {
  name?: string;
  slug?: string;
}

/** `/v1/team_members` row. */
export interface TeamMemberRow {
  object?: "team_member";
  id: string;
  team_id: string;
  user_id: string;
  role: string;
  added_at: string;
  member_kind?: "customer" | "persona";
  email: string | null;
  display_name: string | null;
  persona_slug: string | null;
  persona_name: string | null;
}
