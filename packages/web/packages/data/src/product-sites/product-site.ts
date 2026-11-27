"use client";

// A product's PRODUCT SITE (product sites phase 5), for the product's managers at the hub: its
// handle, the address that handle gives it, the switch for its `/admin` console, and whether the
// hub reads only the product's house rows (`contentGated`), which All Data says.
//
// Route: /api/ecosystem/product-site?ecosystem=<id>   read (GET), change (PATCH)
//
// The hub's `/api/:path*` rewrite forwards to the backend's own route, not through /v1, so the
// answer is the route's camelCase body and a PATCH stays a PATCH.
//
// A refusal carries the backend's sentence: a malformed or reserved handle is 400 (`{ error:
// { message } }` from an HTTPException); a taken handle or a console with no base domain is 409
// `{ error: { code, message } }`. ProductSiteError keeps the status, the code and that sentence,
// so the pane shows what the backend wrote.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { authedJson, httpStatus, isNotFound, withV1Query } from "../http";

export interface ProductSiteWire {
  ecosystemId: string;
  handle: string;
  primaryOrigin: string | null;
  adminEnabled: boolean;
  adminClientId: string | null;
  /** Absent from a backend that predates it, which reads as not live. */
  consoleLive?: boolean;
  /** Absent from a backend that predates it, which reads as not gated. */
  contentGated?: boolean;
}

export interface ProductSite {
  ecosystemId: string;
  /** The product's handle: the first label of its address. */
  handle: string;
  /** `https://<handle>.<base domain>`, or null while the backend has no base domain. */
  primaryOrigin: string | null;
  /** Whether the product's `/admin` console is switched on. */
  adminEnabled: boolean;
  /** The console's login registration, once it has one. */
  adminClientId: string | null;
  /** Whether the console answers at the product's address now. */
  consoleLive: boolean;
  /** Whether content enforcement is on: the hub reads only the product's house rows. */
  contentGated: boolean;
}

export interface ProductSiteUpdate {
  handle?: string;
  adminEnabled?: boolean;
}

export const PRODUCT_SITE_PATH = "/api/ecosystem/product-site";

/** A refusal from the product-site route. `message` is the backend's sentence. */
export class ProductSiteError extends Error {
  constructor(
    readonly status: number,
    message: string,
    /** The backend's machine code (`product_site_handle_taken`, ...), when it sent one. */
    readonly code?: string,
  ) {
    super(message);
    this.name = "ProductSiteError";
  }
}

export const toProductSite = (w: ProductSiteWire): ProductSite => ({
  ecosystemId: w.ecosystemId,
  handle: w.handle,
  primaryOrigin: w.primaryOrigin ?? null,
  adminEnabled: Boolean(w.adminEnabled),
  adminClientId: w.adminClientId ?? null,
  consoleLive: Boolean(w.consoleLive),
  contentGated: Boolean(w.contentGated),
});

/**
 * An HTTP failure as a ProductSiteError. The transport has already read the body: its message is
 * the backend's `error.message` (or top-level `message`), its code `error.code`. A failure with no
 * status (the network) is rethrown unchanged, so it is still reported as unexpected.
 */
function asProductSiteError(err: unknown): never {
  const status = httpStatus(err);
  if (status === undefined) throw err;
  const code = (err as { code?: unknown }).code;
  throw new ProductSiteError(status, (err as Error).message, typeof code === "string" ? code : undefined);
}

const url = (ecosystemId: string) => withV1Query(PRODUCT_SITE_PATH, { ecosystem: ecosystemId });

export const productSiteApi = {
  async get(ecosystemId: string): Promise<ProductSite> {
    try {
      return toProductSite(await authedJson<ProductSiteWire>(url(ecosystemId)));
    } catch (err) {
      return asProductSiteError(err);
    }
  },

  /** Change the handle, the console's switch, or both; answers as `get`. */
  async update(ecosystemId: string, body: ProductSiteUpdate): Promise<ProductSite> {
    try {
      return toProductSite(
        await authedJson<ProductSiteWire>(url(ecosystemId), {
          method: "PATCH",
          body: JSON.stringify(body),
        }),
      );
    } catch (err) {
      return asProductSiteError(err);
    }
  },
};

// ── Hooks ─────────────────────────────────────────────────────────────────────

export const PRODUCT_SITE_KEY = (ecosystemId: string) => ["product-sites", ecosystemId] as const;

/**
 * The product's site. Disabled until there is an id to ask about. A 404 is not retried: an
 * ecosystem that is not a product (a workspace's, asked by AllDataPane) answers it every time, so
 * a retry only doubles the failed requests.
 */
export function useProductSite(ecosystemId: string | null | undefined) {
  return useQuery<ProductSite, ProductSiteError>({
    queryKey: PRODUCT_SITE_KEY(ecosystemId ?? ""),
    queryFn: () => productSiteApi.get(ecosystemId as string),
    enabled: Boolean(ecosystemId),
    retry: (count, err) => !isNotFound(err) && count < 1,
  });
}

/** Change the site; writes the answer straight into the cache. */
export function useUpdateProductSite(ecosystemId: string) {
  const qc = useQueryClient();
  return useMutation<ProductSite, ProductSiteError, ProductSiteUpdate>({
    mutationFn: (body) => productSiteApi.update(ecosystemId, body),
    onSuccess: (site) => {
      qc.setQueryData(PRODUCT_SITE_KEY(ecosystemId), site);
    },
  });
}
