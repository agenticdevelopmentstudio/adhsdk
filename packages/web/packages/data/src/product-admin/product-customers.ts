"use client";

// A product's ROSTER (phase 6), for the product's own admins at its admin site. Existence, not
// content: each row says who the customer is, when they were last active, what they hold and how
// much storage they use, and never anything they made. A manager calling these is 403; managers
// keep generic CRUD's customers until phase 7.
//
// Routes: /api/v1/product_admin/customers?ecosystem=&q=&cursor=   one page, 50, newest first
//         /api/v1/product_admin/customers/{id}?ecosystem=         delete (DELETE)
//         /api/v1/product_admin/customers/{id}/pause?ecosystem=   pause (POST), lift (DELETE)
//         /api/v1/product_admin/customers/{id}/quota?ecosystem=   set the quota (POST; PUT inside)
//
// Every call carries the ecosystem uuid, never an rdid: the backend's `:eco` matcher and its
// realm check compare the uuid exactly. Pausing or deleting yourself or another holder of
// `admin` is a 422 `admin_seat_protected`, which `isAdminSeatProtected` recognizes.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { authedJson, authedRequest, httpStatus, unixToIso, withV1Query } from "../http";
import { enc } from "../client-helpers";
import { PRODUCT_TOTALS_KEY } from "./product-totals";

export interface ProductCustomerRole {
  id: string;
  slug: string;
  name: string;
}

export interface ProductCustomerWire {
  id: string;
  email: string | null;
  display_name: string | null;
  avatar_url: string | null;
  external_id: string | null;
  /** Unix seconds. */
  created: number;
  /** `YYYY-MM-DD`, the last UTC day with usage in this product. */
  last_active_day: string | null;
  roles: ProductCustomerRole[];
  sets: string[];
  storage_bytes: number;
  quota_bytes: number;
  paused: boolean;
}

export interface ProductCustomerPageWire {
  items: ProductCustomerWire[];
  next_cursor: string | null;
}

export interface ProductCustomer {
  id: string;
  email: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  externalId: string | null;
  /** ISO 8601. */
  createdAt: string | null;
  lastActiveDay: string | null;
  /** The product roles held product-wide. */
  roles: ProductCustomerRole[];
  /** The ids of the sets granted and not revoked. */
  sets: string[];
  storageBytes: number;
  quotaBytes: number;
  paused: boolean;
}

export interface ProductCustomerPage {
  items: ProductCustomer[];
  /** Pass back as `cursor` for the next page; null on the last. */
  nextCursor: string | null;
}

export const PRODUCT_CUSTOMERS_PATH = "/api/v1/product_admin/customers";

export const toProductCustomer = (w: ProductCustomerWire): ProductCustomer => ({
  id: w.id,
  email: w.email ?? null,
  displayName: w.display_name ?? null,
  avatarUrl: w.avatar_url || null,
  externalId: w.external_id ?? null,
  createdAt: unixToIso(w.created),
  lastActiveDay: w.last_active_day ?? null,
  roles: w.roles ?? [],
  sets: w.sets ?? [],
  storageBytes: w.storage_bytes,
  quotaBytes: w.quota_bytes,
  paused: w.paused,
});

const customerUrl = (ecosystemId: string, customerId: string, tail = "") =>
  withV1Query(`${PRODUCT_CUSTOMERS_PATH}/${enc(customerId)}${tail}`, { ecosystem: ecosystemId });

/** True when `err` is the backend's refusal to pause or delete yourself or another admin
 *  (a 422 whose body is `{ error: { code: 'admin_seat_protected', message } }`). */
export function isAdminSeatProtected(err: unknown): boolean {
  if (httpStatus(err) !== 422) return false;
  if ((err as { code?: unknown }).code === "admin_seat_protected") return true;
  const body = (err as { body?: unknown }).body as { error?: { code?: unknown } } | null | undefined;
  return body?.error?.code === "admin_seat_protected";
}

export const productAdminApi = {
  /** One page of the roster, newest first; `q` filters email and name. */
  async customers(
    ecosystemId: string,
    opts: { q?: string; cursor?: string } = {},
  ): Promise<ProductCustomerPage> {
    const w = await authedJson<ProductCustomerPageWire>(
      withV1Query(PRODUCT_CUSTOMERS_PATH, {
        ecosystem: ecosystemId,
        q: opts.q || undefined,
        cursor: opts.cursor || undefined,
      }),
    );
    return { items: (w.items ?? []).map(toProductCustomer), nextCursor: w.next_cursor ?? null };
  },

  /** Refuse the customer's sign-in and every request; revokes their sign-in sessions. */
  async pause(ecosystemId: string, customerId: string, reason?: string): Promise<{ paused: boolean }> {
    const r = await authedJson<{ paused: boolean }>(customerUrl(ecosystemId, customerId, "/pause"), {
      method: "POST",
      body: JSON.stringify(reason ? { reason } : {}),
    });
    return { paused: r.paused };
  },

  async unpause(ecosystemId: string, customerId: string): Promise<void> {
    await authedRequest(customerUrl(ecosystemId, customerId, "/pause"), { method: "DELETE" });
  },

  /** At most `DEFAULT_QUOTA_BYTES`; the backend answers 403 above it. */
  async setQuota(ecosystemId: string, customerId: string, bytes: number): Promise<{ quotaBytes: number }> {
    const r = await authedJson<{ quota_bytes: number }>(customerUrl(ecosystemId, customerId, "/quota"), {
      method: "POST",
      body: JSON.stringify({ bytes }),
    });
    return { quotaBytes: r.quota_bytes };
  },

  /** Tombstones the customer; 409 while they still own data. */
  async deleteCustomer(ecosystemId: string, customerId: string): Promise<void> {
    await authedRequest(customerUrl(ecosystemId, customerId), { method: "DELETE" });
  },
};

// ── Hooks ─────────────────────────────────────────────────────────────────────

export const PRODUCT_CUSTOMERS_KEY = (ecosystemId: string) =>
  ["product-admin", ecosystemId, "customers"] as const;

/** One roster page. Disabled until there is an id to ask about. */
export function useProductCustomers(
  ecosystemId: string | null | undefined,
  opts: { q?: string; cursor?: string } = {},
) {
  return useQuery({
    queryKey: [...PRODUCT_CUSTOMERS_KEY(ecosystemId ?? ""), opts.q ?? "", opts.cursor ?? ""],
    queryFn: () => productAdminApi.customers(ecosystemId as string, opts),
    enabled: Boolean(ecosystemId),
  });
}

/** Every roster write invalidates the roster and the totals, which count the same people. */
function useRosterMutation<V>(
  ecosystemId: string | null | undefined,
  fn: (eco: string, v: V) => Promise<unknown>,
) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (v: V) => fn(ecosystemId as string, v),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: PRODUCT_CUSTOMERS_KEY(ecosystemId ?? "") });
      void qc.invalidateQueries({ queryKey: PRODUCT_TOTALS_KEY(ecosystemId ?? "") });
    },
  });
}

export const usePauseCustomer = (ecosystemId: string | null | undefined) =>
  useRosterMutation(ecosystemId, (eco, v: { customerId: string; reason?: string }) =>
    productAdminApi.pause(eco, v.customerId, v.reason),
  );

export const useUnpauseCustomer = (ecosystemId: string | null | undefined) =>
  useRosterMutation(ecosystemId, (eco, customerId: string) => productAdminApi.unpause(eco, customerId));

export const useSetCustomerQuota = (ecosystemId: string | null | undefined) =>
  useRosterMutation(ecosystemId, (eco, v: { customerId: string; bytes: number }) =>
    productAdminApi.setQuota(eco, v.customerId, v.bytes),
  );

export const useDeleteCustomer = (ecosystemId: string | null | undefined) =>
  useRosterMutation(ecosystemId, (eco, customerId: string) =>
    productAdminApi.deleteCustomer(eco, customerId),
  );
