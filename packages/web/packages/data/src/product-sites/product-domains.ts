"use client";

// A product's CUSTOM DOMAINS (product sites phase 8), for the product's managers at the hub: the
// hosts the product answers at besides its own address, each with the DNS records it is waiting
// for, whether the backend has seen them, and which one is primary.
//
// Route: /api/ecosystem/product-domains?ecosystem=<id>
//   GET                  list         200 { domains }
//   POST { host }        add          201 the domain
//   POST /:id/check      check now    200 the domain
//   PATCH /:id { primary }           200 { domains }
//   DELETE /:id          remove       204
//
// The hub's `/api/:path*` rewrite forwards to the backend's own route, not through /v1, so the
// answer is the route's camelCase body. While the backend's `product_custom_domains` switch is off
// every call answers 404 `{ error: { code: "not_found" } }`, which `productDomainsAvailable` reads
// as "hide the section". Other refusals are `{ error: { code, message } }`; ProductDomainError
// keeps the status, the code and that sentence, so the section shows what the backend wrote.

import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseMutationResult,
  type UseQueryResult,
} from "@tanstack/react-query";
import { authedJson, authedRequest, httpStatus, isNotFound, withV1Query } from "../http";
import { PRODUCT_SITE_KEY } from "./product-site";

export type ProductDomainStatus = "pending" | "verified" | "failed" | "removing";

export type ProductDomainRecordType = "A" | "CNAME" | "TXT";

/** One DNS record the domain's owner has to set. */
export interface ProductDomainRecord {
  type: ProductDomainRecordType;
  /** The record's name, as the DNS host should be told it. */
  name: string;
  /** The record's value, exactly as it must be set. */
  value: string;
}

export interface ProductDomainRecordWire {
  type: ProductDomainRecordType;
  name: string;
  value: string;
}

export interface ProductDomainWire {
  id: string;
  host: string;
  status: ProductDomainStatus;
  isPrimary: boolean;
  records: ProductDomainRecordWire[];
  misconfigured: boolean;
  vercelVerified: boolean;
  error: string | null;
  createdAt: string;
  verifiedAt: string | null;
  /** Absent from a backend that predates it, which reads as never checked. */
  checkedAt?: string | null;
  expiresAt: string;
}

export interface ProductDomain {
  id: string;
  /** The host, as the owner typed it and the backend normalised it (`www.example.com`). */
  host: string;
  /** `pending` until the records are seen, `verified` once live, `failed` past `expiresAt`. */
  status: ProductDomainStatus;
  /** Whether this domain is the product's primary address. */
  isPrimary: boolean;
  /** The DNS records the owner has to set. */
  records: ProductDomainRecord[];
  /** Whether the host's DNS currently points somewhere else. */
  misconfigured: boolean;
  /** Whether the host has proved it belongs to this product. */
  vercelVerified: boolean;
  /** The backend's sentence about the last failed check, when there is one. Plain text. */
  error: string | null;
  createdAt: string;
  verifiedAt: string | null;
  /** When the backend last checked the records; null before the first check. */
  checkedAt: string | null;
  /** When a domain still pending is given up on. */
  expiresAt: string;
}

export const PRODUCT_DOMAINS_PATH = "/api/ecosystem/product-domains";

/** A refusal from the product-domains route. `message` is the backend's sentence. */
export class ProductDomainError extends Error {
  constructor(
    readonly status: number,
    message: string,
    /** The backend's machine code (`not_found`, ...), when it sent one. */
    readonly code?: string,
  ) {
    super(message);
    this.name = "ProductDomainError";
  }
}

const toProductDomainRecord = (w: ProductDomainRecordWire): ProductDomainRecord => ({
  type: w.type,
  name: w.name,
  value: w.value,
});

export const toProductDomain = (w: ProductDomainWire): ProductDomain => ({
  id: w.id,
  host: w.host,
  status: w.status,
  isPrimary: Boolean(w.isPrimary),
  records: (w.records ?? []).map(toProductDomainRecord),
  misconfigured: Boolean(w.misconfigured),
  vercelVerified: Boolean(w.vercelVerified),
  error: w.error ?? null,
  createdAt: w.createdAt,
  verifiedAt: w.verifiedAt ?? null,
  checkedAt: w.checkedAt ?? null,
  expiresAt: w.expiresAt,
});

/**
 * An HTTP failure as a ProductDomainError. The transport has already read the body: its message
 * is the backend's `error.message` (or top-level `message`), its code `error.code`. A failure with
 * no status (the network) is rethrown unchanged, so it is still reported as unexpected.
 */
function asProductDomainError(err: unknown): never {
  const status = httpStatus(err);
  if (status === undefined) throw err;
  const code = (err as { code?: unknown }).code;
  throw new ProductDomainError(status, (err as Error).message, typeof code === "string" ? code : undefined);
}

const url = (ecosystemId: string, domainId?: string, suffix = "") =>
  withV1Query(
    domainId === undefined
      ? PRODUCT_DOMAINS_PATH
      : `${PRODUCT_DOMAINS_PATH}/${encodeURIComponent(domainId)}${suffix}`,
    { ecosystem: ecosystemId },
  );

export const productDomainsApi = {
  async list(ecosystemId: string): Promise<ProductDomain[]> {
    try {
      const body = await authedJson<{ domains: ProductDomainWire[] }>(url(ecosystemId));
      return (body.domains ?? []).map(toProductDomain);
    } catch (err) {
      return asProductDomainError(err);
    }
  },

  /** Add a host; answers the new domain, pending until its records are seen. */
  async add(ecosystemId: string, host: string): Promise<ProductDomain> {
    try {
      return toProductDomain(
        await authedJson<ProductDomainWire>(url(ecosystemId), {
          method: "POST",
          body: JSON.stringify({ host }),
        }),
      );
    } catch (err) {
      return asProductDomainError(err);
    }
  },

  /** Ask the backend to look at the domain's records now; answers the domain as it stands. */
  async check(ecosystemId: string, domainId: string): Promise<ProductDomain> {
    try {
      return toProductDomain(
        await authedJson<ProductDomainWire>(url(ecosystemId, domainId, "/check"), { method: "POST" }),
      );
    } catch (err) {
      return asProductDomainError(err);
    }
  },

  /** Make the domain primary, or stop it being primary; answers every domain, as `list`. */
  async setPrimary(ecosystemId: string, domainId: string, primary: boolean): Promise<ProductDomain[]> {
    try {
      const body = await authedJson<{ domains: ProductDomainWire[] }>(url(ecosystemId, domainId), {
        method: "PATCH",
        body: JSON.stringify({ primary }),
      });
      return (body.domains ?? []).map(toProductDomain);
    } catch (err) {
      return asProductDomainError(err);
    }
  },

  /** Remove the domain. The answer is a 204, so this goes through `authedRequest` (bearer too). */
  async remove(ecosystemId: string, domainId: string): Promise<void> {
    try {
      await authedRequest(url(ecosystemId, domainId), { method: "DELETE" });
    } catch (err) {
      return asProductDomainError(err);
    }
  },
};

/**
 * Whether the product-domains feature answers at all. False for a 404 whose code is `not_found`
 * or absent, which is what the backend sends while its `product_custom_domains` switch is off, so
 * the section can hide itself. Any other error (or none) leaves it showing.
 */
export function productDomainsAvailable(err: unknown): boolean {
  if (!isNotFound(err)) return true;
  const code = (err as { code?: unknown }).code;
  return !(code === undefined || code === null || code === "not_found");
}

// ── Hooks ─────────────────────────────────────────────────────────────────────

export const PRODUCT_DOMAINS_KEY = (ecosystemId: string) => ["product-domains", ecosystemId] as const;

/**
 * The product's custom domains. Disabled until there is an id to ask about. A 404 is not retried:
 * the switch being off answers it every time. The error is a ProductDomainError for an HTTP
 * refusal, or a plain Error when the request never got an answer (the network).
 */
export function useProductDomains(
  ecosystemId: string | null | undefined,
): UseQueryResult<ProductDomain[], ProductDomainError | Error> {
  return useQuery<ProductDomain[], ProductDomainError | Error>({
    queryKey: PRODUCT_DOMAINS_KEY(ecosystemId ?? ""),
    queryFn: () => productDomainsApi.list(ecosystemId as string),
    enabled: Boolean(ecosystemId),
    retry: (count, err) => !isNotFound(err) && count < 1,
  });
}

/** Add a host; appends the new domain to the cached list. */
export function useAddProductDomain(
  ecosystemId: string,
): UseMutationResult<ProductDomain, ProductDomainError | Error, string> {
  const qc = useQueryClient();
  return useMutation<ProductDomain, ProductDomainError | Error, string>({
    mutationFn: (host) => productDomainsApi.add(ecosystemId, host),
    onSuccess: (domain) => {
      qc.setQueryData<ProductDomain[]>(PRODUCT_DOMAINS_KEY(ecosystemId), (old) => [
        ...(old ?? []).filter((d) => d.id !== domain.id),
        domain,
      ]);
    },
  });
}

/** Check a domain now; replaces its row in the cached list with the answer. */
export function useCheckProductDomain(
  ecosystemId: string,
): UseMutationResult<ProductDomain, ProductDomainError | Error, string> {
  const qc = useQueryClient();
  return useMutation<ProductDomain, ProductDomainError | Error, string>({
    mutationFn: (domainId) => productDomainsApi.check(ecosystemId, domainId),
    onSuccess: (domain) => {
      qc.setQueryData<ProductDomain[]>(PRODUCT_DOMAINS_KEY(ecosystemId), (old) =>
        old?.map((d) => (d.id === domain.id ? domain : d)),
      );
    },
  });
}

export interface SetPrimaryProductDomainInput {
  domainId: string;
  primary: boolean;
}

/**
 * Make a domain primary, or stop it being primary. Writes the answered list into the cache, then
 * invalidates the product site so its address follows the new primary.
 */
export function useSetPrimaryProductDomain(
  ecosystemId: string,
): UseMutationResult<ProductDomain[], ProductDomainError | Error, SetPrimaryProductDomainInput> {
  const qc = useQueryClient();
  return useMutation<ProductDomain[], ProductDomainError | Error, SetPrimaryProductDomainInput>({
    mutationFn: ({ domainId, primary }) => productDomainsApi.setPrimary(ecosystemId, domainId, primary),
    onSuccess: (domains) => {
      qc.setQueryData(PRODUCT_DOMAINS_KEY(ecosystemId), domains);
      void qc.invalidateQueries({ queryKey: PRODUCT_SITE_KEY(ecosystemId) });
    },
  });
}

/**
 * Remove a domain. On success its row is dropped from the cache. On a 502 the backend has left
 * the row `removing`, so the list is invalidated to show it. Either way the product site is
 * invalidated, since removing the primary moves the address back to the product's own.
 */
export function useRemoveProductDomain(
  ecosystemId: string,
): UseMutationResult<void, ProductDomainError | Error, string> {
  const qc = useQueryClient();
  return useMutation<void, ProductDomainError | Error, string>({
    mutationFn: (domainId) => productDomainsApi.remove(ecosystemId, domainId),
    onSuccess: (_void, domainId) => {
      qc.setQueryData<ProductDomain[]>(PRODUCT_DOMAINS_KEY(ecosystemId), (old) =>
        old?.filter((d) => d.id !== domainId),
      );
    },
    onError: (err) => {
      if (httpStatus(err) === 502) {
        void qc.invalidateQueries({ queryKey: PRODUCT_DOMAINS_KEY(ecosystemId) });
      }
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: PRODUCT_SITE_KEY(ecosystemId) });
    },
  });
}
