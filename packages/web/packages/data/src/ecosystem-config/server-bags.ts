"use client";

// Per-ecosystem SERVER BAGS (arbitrary key → JSON config values this product's backend
// reads at runtime) for ONE ecosystem — the per-product analogue of the admin site's
// GLOBAL server-bags page. Wired to the backend's /v1/server_bag route (the ecosystem rides as
// `ecosystem`): CREATE (POST /v1/server_bag, value required) and UPDATE (POST /v1/server_bag/{key},
// partial) are split so a "New bag" whose key
// already exists is a 409, not a silent overwrite; the key is IMMUTABLE. Mirrors
// signin-apps.ts.
//
// Hand-written wire types, for the reason feature-flags.ts states.

import { authedJson, authedRequest, listAllV1, unixToIso, withV1Query } from "../http";
import { enc, sortByText } from "../client-helpers";

export interface EcosystemServerBag {
  key: string;
  value: unknown;
  description: string;
  createdAt: string;
  updatedAt: string;
}

/** POST create body — key + value (required) + optional description. */
export interface EcosystemServerBagCreate {
  key: string;
  value: unknown;
  description?: string;
}

/** Update body — value and/or description (at least one). */
export interface EcosystemServerBagUpdate {
  value?: unknown;
  description?: string;
}

const BASE = "/api/v1/server_bag";

/** `/v1/server_bag` row. `value` is a JSON bag and passes through unchanged. */
interface BagRow {
  key: string;
  value: unknown;
  description: string;
  created: number;
  updated: number;
}

const toBag = (r: BagRow): EcosystemServerBag => ({
  key: r.key,
  value: r.value,
  description: r.description,
  createdAt: unixToIso(r.created),
  updatedAt: unixToIso(r.updated),
});

const bagCursor = (row: unknown): string | undefined => (row as { key?: string }).key;

export const ecosystemServerBagsApi = {
  /** All bags for the ecosystem, alphabetized by key (the pane filters this list). */
  async get(ecoId: string): Promise<EcosystemServerBag[]> {
    const rows = await listAllV1<BagRow>(withV1Query(BASE, { ecosystem: ecoId }), {}, { cursorOf: bagCursor });
    return sortByText(rows.map(toBag), (b) => b.key);
  },

  /** Create one bag (409 if the key already exists). */
  async create(ecoId: string, body: EcosystemServerBagCreate): Promise<EcosystemServerBag> {
    const row = await authedJson<BagRow>(BASE, {
      method: "POST",
      body: JSON.stringify({ ecosystem: ecoId, ...body }),
    });
    return toBag(row);
  },

  /** Update one existing bag by key (404 if it doesn't exist; the key itself is immutable). */
  async update(
    ecoId: string,
    key: string,
    body: EcosystemServerBagUpdate,
  ): Promise<EcosystemServerBag> {
    const row = await authedJson<BagRow>(`${BASE}/${enc(key)}`, {
      method: "POST",
      body: JSON.stringify({ ecosystem: ecoId, ...body }),
    });
    return toBag(row);
  },

  async delete(ecoId: string, key: string): Promise<void> {
    await authedRequest(withV1Query(`${BASE}/${enc(key)}`, { ecosystem: ecoId }), { method: "DELETE" });
  },
};
