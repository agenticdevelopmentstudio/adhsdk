"use client";

// Per-ecosystem offline-sync table ENROLLMENT: which catalog resources one ecosystem syncs to
// offline clients, each overriding its code default. The backend contract is adhbackend's
// sync-table-enrollment recipe. It serves one handler set under two route families that differ
// only in who may call them:
//
//   "admin"     /v1/sync/tables/{id}               platform staff, any ecosystem
//   "ecosystem" /v1/ecosystems/{id}/sync_tables    the ecosystem's owner or org admin
//
// so one client, parameterized by family, serves the admin console and the hub alike. `{id}` is
// the ecosystem's rdid or raw uuid; the route resolves either.
//
// Every write answers (or, for DELETE, is followed by a read of) the FULL catalog, because the
// server is the authority on effective and overridden state: a follower turned on while its
// parent is off comes back overridden but not enabled.
//
// The types are hand-written rather than derived from `@adh-sdk/adh-api-types`, like every
// client in this package (see feature-flags.ts).

import { authedJson, listAllV1 } from "../http";
import { enc } from "../client-helpers";

export type SyncTablesFamily = "admin" | "ecosystem";

/** One catalog resource's enrollment for an ecosystem. */
export interface SyncTableEnrollment {
  /** Dotted resource id, e.g. "content.feed". */
  resource: string;
  /** "owner" | "author" | "ecosystem" — display only. */
  scope: string;
  /** "generic" | "route" — display only. */
  pushMode: string;
  /** The code default this ecosystem inherits absent an override. */
  defaultEnabled: boolean;
  /** EFFECTIVE state — what the ecosystem's clients actually sync. */
  enabled: boolean;
  /** True when an explicit per-ecosystem override exists. */
  overridden: boolean;
}

/** The /v1 wire row (snake_case). */
interface WireEnrollment {
  resource: string;
  scope: string;
  push_mode: string;
  default_enabled: boolean;
  enabled: boolean;
  overridden: boolean;
}

const toEnrollment = (r: WireEnrollment): SyncTableEnrollment => ({
  resource: r.resource,
  scope: r.scope,
  pushMode: r.push_mode,
  defaultEnabled: r.default_enabled,
  enabled: r.enabled,
  overridden: r.overridden,
});

const listPath = (family: SyncTablesFamily, ecosystemId: string): string =>
  family === "admin"
    ? `/api/v1/sync/tables/${enc(ecosystemId)}`
    : `/api/v1/ecosystems/${enc(ecosystemId)}/sync_tables`;

const resourcePath = (family: SyncTablesFamily, ecosystemId: string, resource: string): string =>
  family === "admin"
    ? `${listPath(family, ecosystemId)}/resources/${enc(resource)}`
    : `${listPath(family, ecosystemId)}/${enc(resource)}`;

export interface SyncTablesClient {
  /** The full catalog, every resource with its effective state. */
  get(ecosystemId: string): Promise<SyncTableEnrollment[]>;
  /** Set one resource's override; returns the refreshed catalog. */
  setOverride(
    ecosystemId: string,
    resource: string,
    enabled: boolean,
  ): Promise<SyncTableEnrollment[]>;
  /** Clear one resource's override (back to its default); returns the refreshed catalog. */
  clearOverride(ecosystemId: string, resource: string): Promise<SyncTableEnrollment[]>;
}

/** The enrollment client for one route family. */
export function syncTablesApi(family: SyncTablesFamily): SyncTablesClient {
  const api: SyncTablesClient = {
    async get(ecosystemId) {
      const rows = await listAllV1<WireEnrollment>(listPath(family, ecosystemId));
      return rows.map(toEnrollment);
    },

    async setOverride(ecosystemId, resource, enabled) {
      const { tables } = await authedJson<{ tables: WireEnrollment[] }>(
        resourcePath(family, ecosystemId, resource),
        { method: "POST", body: JSON.stringify({ enabled }) },
      );
      return tables.map(toEnrollment);
    },

    // /v1 answers DELETE with a tombstone, not the catalog, so the catalog is re-read.
    async clearOverride(ecosystemId, resource) {
      await authedJson<unknown>(resourcePath(family, ecosystemId, resource), {
        method: "DELETE",
      });
      return api.get(ecosystemId);
    },
  };
  return api;
}

/**
 * The schema a resource belongs to: the part before the first dot. The list uses it as a facet
 * rather than splitting the catalog into one table per schema, so sorting and counting work
 * across the whole catalog.
 */
export function schemaOf(row: Pick<SyncTableEnrollment, "resource">): string {
  return row.resource.split(".")[0] ?? "";
}
