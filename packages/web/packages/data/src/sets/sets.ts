"use client";

// An ecosystem's SETS (phase 5): the client for the backend's sets admin surface, for the
// ecosystem's managers. Every call names the ecosystem as `?ecosystem=<id>`, as access does.
//
// Routes: /api/v1/sets                       list (GET), create (POST)
//         /api/v1/sets/{id}                  edit (POST), delete (DELETE)
//         /api/v1/sets/{id}/members          replace what it contains (POST)
//         /api/v1/sets/{id}/values           replace its permissions and limits (POST)
//         /api/v1/set_grants?customer=       a customer's grants (GET), grant (POST)
//         /api/v1/set_grants/{id}            revoke (DELETE)
//         /api/v1/set_grants/effective/{customer_id}   a customer's effective answer
//         /api/v1/offers/{offer_id}/set      the set an offer sells (POST)
//
// A write the resolver refuses is a 422 whose body names the rule; every write here turns that
// into a {@link SetRefusedError}, so a pane can say which rule and which limits.

import { authedJson, authedRequest, httpStatus, listAllV1, withV1Query } from "../http";
import { enc, sortByText } from "../client-helpers";
import type {
  EffectiveSets,
  SetEntries,
  SetEntriesWire,
  SetGrantRow,
  SetGrantWire,
  SetInput,
  SetPatch,
  SetRefusal,
  SetRow,
  SetsAnswer,
  SetsAnswerWire,
  SetValue,
  SetWire,
} from "./wire";

const SETS = "/api/v1/sets";
const GRANTS = "/api/v1/set_grants";

const q = (ecoId: string, extra: Record<string, string | undefined> = {}) => ({
  ecosystem: ecoId,
  ...extra,
});

export const toSet = (w: SetWire): SetRow => ({
  id: w.id,
  slug: w.slug,
  name: w.name,
  description: w.description ?? "",
  isDefault: w.is_default,
  isPersonal: w.is_personal,
  personalCustomerId: w.personal_customer_id ?? null,
  contains: w.contains ?? [],
  values: w.values ?? [],
});

export const toSetGrant = (w: SetGrantWire): SetGrantRow => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  customerId: w.owner_id,
  setId: w.set_id,
  source: w.source,
  billingAccountId: w.billing_account_id ?? null,
  grantedBy: w.granted_by,
  grantedAt: w.granted_at,
  revokedAt: w.revoked_at ?? null,
  revokeReason: w.revoke_reason ?? null,
});

/**
 * A customer's sets answer from its wire form: `/auth/me`'s `sets` or the effective route's body.
 * Absent (an older backend, or a realm where sets do not apply) reads as null.
 */
export function toSetsAnswer(w: SetsAnswerWire | undefined): SetsAnswer {
  if (!w) return null;
  if (w.error === "unresolved") return { error: "unresolved" };
  return {
    held: w.held ?? [],
    permissions: w.permissions ?? [],
    readOnly: w.read_only ?? [],
    limits: w.limits ?? {},
    ...(w.valid_until !== undefined ? { validUntil: w.valid_until } : {}),
  };
}

/** Whether an answer could be computed: false for null (no sets) and for `unresolved`. */
export function isEffectiveSets(a: SetsAnswer): a is EffectiveSets {
  return a !== null && !("error" in a);
}

/** The catalog's `set_entries` for one feature; undefined when the feature contributes none. */
export function toSetEntries(w: SetEntriesWire | undefined): SetEntries | undefined {
  if (!w || (!w.permission && !w.limits?.length)) return undefined;
  return {
    ...(w.permission ? { permission: true as const } : {}),
    ...(w.limits?.length ? { limits: w.limits.map((l) => ({ ...l })) } : {}),
  };
}

/** One catalog feature as the Sets pane reads it: the ones that contribute something to sets. */
export interface SetEntryFeature {
  key: string;
  label: string;
  setEntries: SetEntries;
}

/** The catalog features that contribute to sets, in catalog order. */
export function setEntryFeatures(
  catalog: readonly { key: string; label: string; setEntries?: SetEntries }[],
): SetEntryFeature[] {
  return catalog.flatMap((f) =>
    f.setEntries ? [{ key: f.key, label: f.label, setEntries: f.setEntries }] : [],
  );
}

/** Thrown by a sets write the backend refused under a set rule (a 422 `set_refused`). */
export class SetRefusedError extends Error {
  constructor(readonly refusal: SetRefusal) {
    super(refusal.message);
    this.name = "SetRefusedError";
  }
}

/**
 * `err` as a {@link SetRefusedError} when it is the backend's 422 `set_refused`; else null.
 * Duck-typed on `.status` and `.body`, as `httpStatus` is, so a host's own auth error class
 * is read the same.
 */
export function asSetRefusedError(err: unknown): SetRefusedError | null {
  if (httpStatus(err) !== 422) return null;
  const body = (err as { body?: unknown }).body;
  const e = (body as { error?: Record<string, unknown> } | null | undefined)?.error;
  if (!e || e.code !== "set_refused" || typeof e.rule !== "number") return null;
  return new SetRefusedError({
    rule: e.rule as SetRefusal["rule"],
    message: typeof e.message === "string" ? e.message : (err as Error).message,
    ...(Array.isArray(e.limits) ? { limits: e.limits as string[] } : {}),
    ...(Array.isArray(e.containers) ? { containers: e.containers as string[] } : {}),
    ...(typeof e.customers === "number" ? { customers: e.customers } : {}),
  });
}

async function write<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    throw asSetRefusedError(err) ?? err;
  }
}

const post = <T>(url: string, body: unknown) =>
  write(() => authedJson<T>(url, { method: "POST", body: JSON.stringify(body) }));

export const setsApi = {
  /** The ecosystem's sets by name; personal sets only when asked. */
  async list(ecoId: string, opts: { personal?: boolean } = {}): Promise<SetRow[]> {
    const rows = await listAllV1<SetWire>(
      withV1Query(SETS, q(ecoId, { personal: opts.personal ? "true" : undefined })),
    );
    return sortByText(rows.map(toSet), (s) => s.name);
  },

  async create(ecoId: string, input: SetInput): Promise<SetRow> {
    return toSet(
      await post<SetWire>(withV1Query(SETS, q(ecoId)), {
        slug: input.slug,
        name: input.name,
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.isDefault !== undefined ? { is_default: input.isDefault } : {}),
        ...(input.personalCustomerId ? { personal_customer_id: input.personalCustomerId } : {}),
      }),
    );
  },

  /** Making a set the default clears the flag on the previous default. */
  async edit(ecoId: string, setId: string, patch: SetPatch): Promise<SetRow> {
    return toSet(
      await post<SetWire>(withV1Query(`${SETS}/${enc(setId)}`, q(ecoId)), {
        ...(patch.slug !== undefined ? { slug: patch.slug } : {}),
        ...(patch.name !== undefined ? { name: patch.name } : {}),
        ...(patch.description !== undefined ? { description: patch.description } : {}),
        ...(patch.isDefault !== undefined ? { is_default: patch.isDefault } : {}),
      }),
    );
  },

  /** Refused (rule 8) when that unsettles a container or puts a holder in conflict. */
  async remove(ecoId: string, setId: string): Promise<void> {
    await write(() =>
      authedRequest(withV1Query(`${SETS}/${enc(setId)}`, q(ecoId)), { method: "DELETE" }),
    );
  },

  /** Replace the sets it contains (rules 3, 6 and 8). */
  async setMembers(ecoId: string, setId: string, contains: string[]): Promise<SetRow> {
    return toSet(
      await post<SetWire>(withV1Query(`${SETS}/${enc(setId)}/members`, q(ecoId)), { contains }),
    );
  },

  /** Replace its permissions and limits (rules 3 and 8). Every key must be one the catalog's
   *  `setEntries` declares, with a value of its type. */
  async setValues(ecoId: string, setId: string, values: SetValue[]): Promise<SetRow> {
    return toSet(
      await post<SetWire>(withV1Query(`${SETS}/${enc(setId)}/values`, q(ecoId)), { values }),
    );
  },

  /** A customer's grants, revoked ones with their reason; newest first. */
  async grants(ecoId: string, customerId: string): Promise<SetGrantRow[]> {
    const rows = await listAllV1<SetGrantWire>(withV1Query(GRANTS, q(ecoId, { customer: customerId })));
    return rows.map(toSetGrant);
  },

  /** Grant a set directly (rule 4). Granting a set already held returns that grant. */
  async grant(
    ecoId: string,
    input: { customerId: string; setId: string },
  ): Promise<{ grantId: string; revoked: string[] }> {
    const r = await post<{ grant_id: string; revoked?: string[] }>(withV1Query(GRANTS, q(ecoId)), {
      customer_id: input.customerId,
      set_id: input.setId,
    });
    return { grantId: r.grant_id, revoked: r.revoked ?? [] };
  },

  /** Revoke a grant; the row stays with the reason `direct`. */
  async revoke(ecoId: string, grantId: string): Promise<void> {
    await authedRequest(withV1Query(`${GRANTS}/${enc(grantId)}`, q(ecoId)), { method: "DELETE" });
  },

  /** A customer's answer before the ecosystem's ceiling. */
  async effective(ecoId: string, customerId: string): Promise<SetsAnswer> {
    const w = await authedJson<SetsAnswerWire>(
      withV1Query(`${GRANTS}/effective/${enc(customerId)}`, q(ecoId)),
    );
    return toSetsAnswer(w);
  },

  /** The set an offer sells, or null to stop it granting one (rule 9). */
  async setOfferSet(ecoId: string, offerId: string, setId: string | null): Promise<void> {
    await post(withV1Query(`/api/v1/offers/${enc(offerId)}/set`, q(ecoId)), { set_id: setId });
  },
};
