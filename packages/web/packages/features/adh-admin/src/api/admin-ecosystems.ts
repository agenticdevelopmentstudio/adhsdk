"use client";

import { useQuery } from "@tanstack/react-query";
import type { SuccessBody } from "@adh-sdk/adh-api-types";
import { listAllV1 } from "./http";

/** An ecosystem row from `GET /v1/ecosystems` (spec-typed). */
export type EcosystemSummary = SuccessBody<"/v1/ecosystems", "get">["data"][number];

/** Ecosystems for an admin picker — deleted ones dropped, sorted by name. Admin bypasses tenant
 *  scoping, so this list returns every ecosystem (same pattern as useAdminUsers sourcing
 *  `/v1/customers`). */
export function useAdminEcosystems() {
  return useQuery({
    queryKey: ["admin", "ecosystems"],
    queryFn: async (): Promise<EcosystemSummary[]> => {
      const rows = await listAllV1<EcosystemSummary>("/api/v1/ecosystems");
      return rows.filter((e) => !e.is_deleted).sort((a, b) => a.name.localeCompare(b.name));
    },
  });
}
