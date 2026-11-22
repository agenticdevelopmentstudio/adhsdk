// Wire shapes of the backend's SETS surface (phase 5: adhbackend src/routes/sets.ts, reached as
// /v1/sets, /v1/set_grants and /v1/offers/{id}/set). The unsuffixed interfaces are the camelCase
// shapes the panes consume; the `*Wire` ones are the snake_case /v1 JSON `sets.ts` maps them from.
//
// A SET is a named bundle of an ecosystem's permissions (catalog features) and limits (typed
// values such as a usage tier). Sets contain other sets; a customer holds sets through grants
// (an offer bought, a direct grant, the sign-up list), and the backend resolves what they hold
// into one EFFECTIVE answer. Hand-written, as every client in this package (see access/wire.ts).

/** One value a set defines: a permission (a feature key, value `true`) or a limit. */
export interface SetValue {
  kind: "permission" | "limit";
  /** A feature key for a permission; a limit key (e.g. `usage.tier`) for a limit. */
  key: string;
  /** `true` for a permission; for a limit, a tier slug (string) or a byte or count (integer). */
  value: unknown;
}

export interface SetRow {
  id: string;
  slug: string;
  name: string;
  description: string;
  /** Applies to a customer who holds no live grant; one per ecosystem. */
  isDefault: boolean;
  /** A one-customer exception, hidden from the list and from offers. */
  isPersonal: boolean;
  personalCustomerId: string | null;
  /** The sets it directly contains. */
  contains: string[];
  /** Its own values (not those of the sets it contains). */
  values: SetValue[];
}

/** Create a set. A personal set names its customer, and that is fixed once made. */
export interface SetInput {
  slug: string;
  name: string;
  description?: string;
  isDefault?: boolean;
  personalCustomerId?: string | null;
}

/** Edit a set's own fields; what is left out stays as it is. */
export type SetPatch = Partial<Pick<SetRow, "slug" | "name" | "description" | "isDefault">>;

export type SetGrantSource = "offer" | "direct" | "signup";

export interface SetGrantRow {
  id: string;
  ecosystemId: string;
  /** The customer who holds it. */
  customerId: string;
  setId: string;
  source: SetGrantSource;
  billingAccountId: string | null;
  grantedBy: string;
  grantedAt: string;
  revokedAt: string | null;
  /** e.g. `direct`, `refund`, `offer_changed`, `purchase_conflict`. */
  revokeReason: string | null;
}

/** What a customer's sets resolve to. */
export interface EffectiveSets {
  /** The set ids held, after containment. */
  held: string[];
  /** Feature keys granted in full. */
  permissions: string[];
  /** Feature keys granted read-only. */
  readOnly: string[];
  /** Limit key to value (a tier slug, a byte or a count). Keys are never re-cased. */
  limits: Record<string, unknown>;
  /** When the answer next changes (a grant lapsing); absent on `/auth/me`. */
  validUntil?: string | null;
}

/** The answer the backend could not compute (set enforcement off; with it on the call is 403). */
export interface UnresolvedSets {
  error: "unresolved";
}

/**
 * A customer's sets as `/auth/me` reports them (`sets`) and as `GET /v1/set_grants/effective`
 * answers: null when the ecosystem has no sets, the {@link EffectiveSets}, or
 * {@link UnresolvedSets}.
 */
export type SetsAnswer = EffectiveSets | UnresolvedSets | null;

/**
 * Why the backend refused a sets write (a 422), by the rule it would break: 3, a container whose
 * contained sets disagree on a limit must define it; 4, the customer holds a conflicting set; 6, a
 * containment loop; 8, the edit unsettles a container or puts a holder in conflict; 9, the set
 * conflicts with another live offer's set.
 */
export interface SetRefusal {
  rule: 1 | 2 | 3 | 4 | 6 | 8 | 9;
  message: string;
  /** The limits at issue. */
  limits?: string[];
  /** Rule 3 or 8: the containers left unsettled. */
  containers?: string[];
  /** Rule 8: how many holders would conflict. */
  customers?: number;
}

/** The type of a limit a feature declares: a tier slug, a number of bytes, or a count. */
export type SetLimitType = "tier" | "bytes" | "count";

export interface SetLimitEntry {
  key: string;
  type: SetLimitType;
  label: string;
}

/**
 * What one catalog feature contributes to sets (the catalog's `setEntries`): `permission` when the
 * feature itself can be in a set, and the typed limits a set may define under it. The Sets pane is
 * generated from these.
 */
export interface SetEntries {
  permission?: true;
  limits?: SetLimitEntry[];
}

/** `/v1/sets` row. */
export interface SetWire {
  id: string;
  slug: string;
  name: string;
  description: string;
  is_default: boolean;
  is_personal: boolean;
  personal_customer_id: string | null;
  contains: string[];
  values: SetValue[];
}

/** `/v1/set_grants` row. */
export interface SetGrantWire {
  id: string;
  ecosystem_id: string;
  owner_id: string;
  set_id: string;
  source: SetGrantSource;
  billing_account_id: string | null;
  granted_by: string;
  granted_at: string;
  revoked_at: string | null;
  revoke_reason: string | null;
}

/** The effective answer as /v1 and `/auth/me` carry it. */
export type SetsAnswerWire = {
  held?: string[];
  permissions?: string[];
  read_only?: string[];
  limits?: Record<string, unknown>;
  valid_until?: string | null;
  error?: "unresolved";
} | null;

/** The catalog's `set_entries` as /v1/features carries it. */
export interface SetEntriesWire {
  permission?: true;
  limits?: SetLimitEntry[];
}
