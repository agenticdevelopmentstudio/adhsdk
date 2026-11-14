"use client";

// react-query wrappers over `syncTablesApi(family)`. The family is part of the cache key: the two
// route families read the same rows, but a write through one must not reseed a cache the other
// family filled under a different caller's authority.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  syncTablesApi,
  type SyncTableEnrollment,
  type SyncTablesFamily,
} from "@adh-sdk/data/ecosystem-config";

export const syncTablesKey = (family: SyncTablesFamily, ecosystemId: string) =>
  ["ecosystem-config", "sync-tables", family, ecosystemId] as const;

/** The enrollment catalog for one ecosystem (idle until an id is given). */
export function useSyncTables(family: SyncTablesFamily, ecosystemId: string | undefined) {
  return useQuery({
    queryKey: syncTablesKey(family, ecosystemId ?? ""),
    enabled: !!ecosystemId,
    queryFn: () => syncTablesApi(family).get(ecosystemId!),
  });
}

/** Every write answers the full catalog: reseed from it, then refetch once things settle, because
 *  two overlapping writes can settle out of order and leave a stale last-writer reseed. */
function useCatalogWrite<TVars>(
  family: SyncTablesFamily,
  ecosystemId: string | undefined,
  write: (ecosystemId: string, vars: TVars) => Promise<SyncTableEnrollment[]>,
) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (vars: TVars) => write(ecosystemId!, vars),
    onSuccess: (tables) => {
      if (ecosystemId) qc.setQueryData(syncTablesKey(family, ecosystemId), tables);
    },
    onSettled: () => {
      if (ecosystemId) void qc.invalidateQueries({ queryKey: syncTablesKey(family, ecosystemId) });
    },
  });
}

/** Set one resource's override. */
export function useSetSyncOverride(family: SyncTablesFamily, ecosystemId: string | undefined) {
  return useCatalogWrite(
    family,
    ecosystemId,
    (id, { resource, enabled }: { resource: string; enabled: boolean }) =>
      syncTablesApi(family).setOverride(id, resource, enabled),
  );
}

/** Clear one resource's override, back to its default. */
export function useClearSyncOverride(family: SyncTablesFamily, ecosystemId: string | undefined) {
  return useCatalogWrite(family, ecosystemId, (id, resource: string) =>
    syncTablesApi(family).clearOverride(id, resource),
  );
}
