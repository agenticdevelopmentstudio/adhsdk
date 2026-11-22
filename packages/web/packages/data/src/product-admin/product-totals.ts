"use client";

// A product's TOTALS (phase 6): counts only, never a per-customer row. A manager of the product
// and a product admin may both read them; the hub's Admin site pane and the product admin site's
// Totals page are the two readers.
//
// Route: /api/v1/product_admin/totals?ecosystem=<uuid>   (internal GET /product-admin/totals)

import { useQuery } from "@tanstack/react-query";
import { authedJson, withV1Query } from "../http";

/** The /v1 body: the gateway snake-cases `storageBytes` and the two pending counts. */
export interface ProductTotalsWire {
  customers: number;
  new7d: number;
  new30d: number;
  active7d: number;
  active30d: number;
  storage_bytes: number;
  pending_invitations: number;
  pending_requests: number;
}

export interface ProductTotals {
  /** Live customers. */
  customers: number;
  /** Customers made in the last 7 and 30 days. */
  new7d: number;
  new30d: number;
  /** Customers with usage in the last 7 and 30 days. */
  active7d: number;
  active30d: number;
  /** Bytes in the customers' ready attachments. */
  storageBytes: number;
  /** Invitations sent and not yet used. */
  pendingInvitations: number;
  /** Requests for an invitation. */
  pendingRequests: number;
}

export const PRODUCT_TOTALS_PATH = "/api/v1/product_admin/totals";

export const toProductTotals = (w: ProductTotalsWire): ProductTotals => ({
  customers: w.customers,
  new7d: w.new7d,
  new30d: w.new30d,
  active7d: w.active7d,
  active30d: w.active30d,
  storageBytes: w.storage_bytes,
  pendingInvitations: w.pending_invitations,
  pendingRequests: w.pending_requests,
});

export async function fetchProductTotals(ecosystemId: string): Promise<ProductTotals> {
  return toProductTotals(
    await authedJson<ProductTotalsWire>(withV1Query(PRODUCT_TOTALS_PATH, { ecosystem: ecosystemId })),
  );
}

export const PRODUCT_TOTALS_KEY = (ecosystemId: string) =>
  ["product-admin", ecosystemId, "totals"] as const;

/** The product's totals. Disabled until there is an id to ask about. */
export function useProductTotals(ecosystemId: string | null | undefined) {
  return useQuery({
    queryKey: PRODUCT_TOTALS_KEY(ecosystemId ?? ""),
    queryFn: () => fetchProductTotals(ecosystemId as string),
    enabled: Boolean(ecosystemId),
  });
}
