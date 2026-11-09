// Local wire types for the Ecosystems clients — the backend row + request-body
// shapes the clients read/send (see projects/wire.ts for the pattern: these
// replace the hub's generated `SuccessBody<...>` / `RequestBody<...>` from
// `@adh-sdk/adh-api-types`, adh product vocabulary a
// generic data client must not take on). Each
// interface carries exactly the fields the mappers and call sites touch.
// Type-only file.

/** What an ecosystem is (backend `ecosystems.type`). `personal` / `organization` are the hub-data
 *  ecosystems — a user's / an org's Notes, Research, Documents, Integrations, Planning and Storage;
 *  the rest are the owner's own (`workspace`), a persona's, one the owner made (`container`) or a
 *  website / app / service (`product`). */
export type EcosystemType =
  | "workspace"
  | "persona"
  | "personal"
  | "organization"
  | "container"
  | "product";

/** `/v1/ecosystems` row (list, get, create, update). `created`/`updated` are UNIX seconds. */
export interface EcosystemRow {
  object?: "ecosystem";
  id: string;
  name: string;
  description?: string | null;
  region?: string | null;
  primary_domain?: string | null;
  created: number;
  updated: number;
  /** hides the auto-provisioned default ecosystem in `list`/`listChildren`. */
  is_default: boolean;
  /** the ecosystem's own slug — used to resolve a workspace's ecosystem by slug. */
  slug: string;
  /** `?workspace=` mode only: whether the CALLER may manage this ecosystem's contents
   *  (the org-admin bar). The list itself is membership-gated, so a plain org member
   *  sees org products they cannot open — the UI uses this to present that honestly. */
  can_manage?: boolean;
  /** Optional on the wire: a backend older than the `type` column omits it, and a row without one
   *  is treated as NOT hub data (see `isHubDataEcosystem`). */
  type?: EcosystemType;
}

/** `POST /v1/ecosystems` body. */
export interface EcosystemCreateBody {
  id: string;
  slug: string;
  name: string;
  description: string;
  region: string;
  primary_domain: string;
}

/** `POST /v1/ecosystems/{id}` body — a partial update. `slug` is the RENAME: the address is
 *  derived from the stored slug, so changing it is the move, and the route cascades the new
 *  address onto the handle and every descendant. */
export interface EcosystemPutBody {
  slug?: string;
  name?: string;
  description?: string;
  region?: string;
  primary_domain?: string;
}

/** The per-ecosystem auth policy as the `auth_settings` include carries it. */
export interface AuthSettingsWire {
  signup_mode: "open" | "invite_only" | "closed";
  login_enabled: boolean;
  password_enabled: boolean;
  allowed_providers: string[] | null;
}

/** `PATCH /registry/identifiers/{rdid}` body — renames an rdid in place. */
export interface IdentifierRenameBody {
  rdid: string;
}
