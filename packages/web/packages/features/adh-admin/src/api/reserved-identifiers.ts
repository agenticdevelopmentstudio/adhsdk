"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { authedJson, listAllV1 } from "./http";

/**
 * The /v1/reserved_identifiers surface: rdids that are held with nothing using them, and the
 * action that gives one back.
 *
 * The page works in camelCase, so these three shapes are the domain types and the mappers below
 * (`toReserved`, `toRelease`) are the only place that knows the `/v1` snake_case wire names.
 */

/** Why a name is being held. Mirrors `ReservedReason` in backend lib/reserved-identifiers.ts. */
export type ReservedReason = "rename-leftover" | "orphan" | "deleted-entity";

export type ReservedIdentifier = {
  rdid: string;
  entityType: string;
  entityId: string;
  reason: ReservedReason;
  heldSince: string | null;
  /**
   * May this one be released? False for the names the surface can only REPORT — a revoked token's
   * slug, reserved by policy, and legacy reverse-domain handles. Sent per row rather than re-derived
   * here from `entityType`: the policy is the backend's, and a second copy of it in the UI is a copy
   * that goes stale into a button that answers 403.
   */
  releasable: boolean;
};


export type ReleaseResult = {
  rdid: string;
  reason: ReservedReason;
  freed: boolean;
  placeholder?: string;
  aliasesRemoved: number;
  stillHeldBy: string[];
  /** The held names UNDERNEATH this one that the same call freed, deepest first. */
  children: ReleaseResult[];
};

interface ReservedWire {
  rdid: string;
  entity_type: string;
  entity_id: string;
  reason: ReservedReason;
  held_since: string | null;
  releasable: boolean;
}

interface ReleaseWire {
  rdid: string;
  reason: ReservedReason;
  freed: boolean;
  renamed_to: string | null;
  aliases_removed: number;
  still_held_by: string[];
  children?: ReleaseWire[];
}

const toReserved = (w: ReservedWire): ReservedIdentifier => ({
  rdid: w.rdid,
  entityType: w.entity_type,
  entityId: w.entity_id,
  reason: w.reason,
  heldSince: w.held_since,
  releasable: w.releasable,
});

const toRelease = (w: ReleaseWire): ReleaseResult => ({
  rdid: w.rdid,
  reason: w.reason,
  freed: w.freed,
  ...(w.renamed_to ? { placeholder: w.renamed_to } : {}),
  aliasesRemoved: w.aliases_removed,
  stillHeldBy: w.still_held_by,
  children: (w.children ?? []).map(toRelease),
});

const KEYS = {
  list: () => ["system", "reserved-identifiers"] as const,
};

export function useReservedIdentifiers() {
  return useQuery({
    queryKey: KEYS.list(),
    // EVERY HELD NAME, walked page by page. The list filters, sorts and selects in the browser and
    // every one of those is a question about the WHOLE population: a type filter over page one
    // answers "which of these twenty-five", and an empty search over a slice reads as "that name
    // is free". Cursor paging has no cap to report, so there is no truncation notice to show.
    queryFn: async (): Promise<ReservedIdentifier[]> =>
      (await listAllV1<ReservedWire>("/api/v1/reserved_identifiers")).map(toReserved),
  });
}

export function useReleaseReservedIdentifier() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (item: ReservedIdentifier): Promise<ReleaseResult> =>
      toRelease(
        await authedJson<ReleaseWire>("/api/v1/reserved_identifiers/release", {
          method: "POST",
          body: JSON.stringify({
            rdid: item.rdid,
            entity_type: item.entityType,
            entity_id: item.entityId,
          }),
        }),
      ),
    onSuccess: () => {
      // Every page, not just the current one: releasing an ecosystem re-homes its whole subtree, so
      // rows on other pages change too.
      void qc.invalidateQueries({ queryKey: ["system", "reserved-identifiers"] });
    },
  });
}
