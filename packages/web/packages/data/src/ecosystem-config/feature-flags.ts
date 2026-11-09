"use client";

// Per-ecosystem FEATURE FLAGS (named on/off toggles this product's apps read) for ONE
// ecosystem — the per-product analogue of the admin site's GLOBAL feature-flags page.
// Wired to the backend's /v1/feature_flags route (the ecosystem rides as `ecosystem`): CREATE
// (POST /v1/feature_flags) and UPDATE (POST /v1/feature_flags/{key}) are split so a "New flag" whose key already exists is a 409, not a silent overwrite;
// the key is IMMUTABLE (it lives in the path on update). Mirrors signin-apps.ts.
//
// The types are hand-written here rather than derived from `@adh-sdk/adh-api-types`:
// every client in this package transcribes the wire shape it touches (see
// ecosystems/wire.ts), because a generic data client must not take a dependency on adh's
// generated product vocabulary.

import { authedJson, authedRequest, listAllV1, unixToIso, withV1Query } from "../http";
import { enc, sortByText } from "../client-helpers";

export interface EcosystemFeatureFlag {
  key: string;
  enabled: boolean;
  description: string;
  createdAt: string;
  updatedAt: string;
}

/** POST create body — key + optional initial state. */
export interface EcosystemFeatureFlagCreate {
  key: string;
  enabled?: boolean;
  description?: string;
}

/** Update body — at least one field; a toggle sends only `enabled`. */
export interface EcosystemFeatureFlagUpdate {
  enabled?: boolean;
  description?: string;
}

const BASE = "/api/v1/feature_flags";

/** `/v1/feature_flags` row. */
interface FlagRow {
  key: string;
  enabled: boolean;
  description: string;
  created: number;
  updated: number;
}

const toFlag = (r: FlagRow): EcosystemFeatureFlag => ({
  key: r.key,
  enabled: r.enabled,
  description: r.description,
  createdAt: unixToIso(r.created),
  updatedAt: unixToIso(r.updated),
});

const flagCursor = (row: unknown): string | undefined => (row as { key?: string }).key;

export const ecosystemFeatureFlagsApi = {
  /** All flags for the ecosystem, alphabetized by key (the pane filters this list). */
  async get(ecoId: string): Promise<EcosystemFeatureFlag[]> {
    const rows = await listAllV1<FlagRow>(withV1Query(BASE, { ecosystem: ecoId }), {}, { cursorOf: flagCursor });
    return sortByText(rows.map(toFlag), (f) => f.key);
  },

  /** Create one flag (409 if the key already exists). */
  async create(ecoId: string, body: EcosystemFeatureFlagCreate): Promise<EcosystemFeatureFlag> {
    const row = await authedJson<FlagRow>(BASE, {
      method: "POST",
      body: JSON.stringify({ ecosystem: ecoId, ...body }),
    });
    return toFlag(row);
  },

  /** Update one existing flag by key (404 if it doesn't exist; the key itself is immutable). */
  async update(
    ecoId: string,
    key: string,
    body: EcosystemFeatureFlagUpdate,
  ): Promise<EcosystemFeatureFlag> {
    const row = await authedJson<FlagRow>(`${BASE}/${enc(key)}`, {
      method: "POST",
      body: JSON.stringify({ ecosystem: ecoId, ...body }),
    });
    return toFlag(row);
  },

  async delete(ecoId: string, key: string): Promise<void> {
    await authedRequest(withV1Query(`${BASE}/${enc(key)}`, { ecosystem: ecoId }), { method: "DELETE" });
  },
};
