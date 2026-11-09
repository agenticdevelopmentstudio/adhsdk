// Local wire types for the reactions client — the backend row + request-body shapes it
// reads/sends. Narrowed by hand from the OpenAPI schema (`Reaction`) rather than imported from
// `@adh-sdk/adh-api-types`, which is adh product vocabulary a generic data client must
// not take on; the cost is that a backend contract change is caught by keeping this in sync,
// not by the build. Type-only file.

/** Backend row for `/content/reactions` (list, create) — one actor's one emoji on one subject. */
export interface ReactionRow {
  id: string;
  ownerKind: string;
  ownerId: string;
  /** the actor who reacted (server-stamped from the caller — never sent). */
  authorKind: string | null;
  authorId: string | null;
  ecosystemId: string;
  targetKind: string;
  targetId: string;
  emoji: string;
  createdAt: string;
  /** set once removed; the read routes already filter these out. */
  deletedAt?: string | null;
}

/** `POST /content/reactions` body. */
export interface ReactionCreateBody {
  target_kind: string;
  target_id: string;
  emoji: string;
}

/** `/v1/content/reactions` row as it crosses the wire (snake_case, unix-second `created`). */
export interface ReactionWire {
  object?: string;
  id: string;
  owner_kind?: string | null;
  owner_id?: string | null;
  author_kind?: string | null;
  author_id?: string | null;
  ecosystem_id: string;
  target_kind: string;
  target_id: string;
  emoji: string;
  created: number;
  deleted_at?: string | null;
}
