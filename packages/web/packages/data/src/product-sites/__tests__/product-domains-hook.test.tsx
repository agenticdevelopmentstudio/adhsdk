// Recipe: adhsdk data, the product-domains client (phase 8).
// Only the transport is stubbed, so the path, method, query and body each call puts on the wire
// are asserted, and the hooks' own retry and cache rules are the ones under test. Refusals are
// built by the transport's own `responseError` from the backend's real bodies, so the sentence and
// code a ProductDomainError carries are the ones the backend wrote.
import type { ReactNode } from "react";
import { renderHook, waitFor, cleanup, act } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { responseError } from "@adh-sdk/auth/client";
import {
  PRODUCT_DOMAINS_KEY,
  PRODUCT_DOMAINS_PATH,
  PRODUCT_SITE_KEY,
  ProductDomainError,
  productDomainsApi,
  productDomainsAvailable,
  useAddProductDomain,
  useCheckProductDomain,
  useProductDomains,
  useRemoveProductDomain,
  useSetPrimaryProductDomain,
  type ProductDomain,
} from "..";
import { authedJson, authedRequest } from "../../http";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);

const ECO = "0b9c4a52-6c3e-4d7e-9a1f-2f4c1d2e3a4b";
const D1 = "7f3e2d1c-0b9a-4c8d-9e7f-6a5b4c3d2e1f";
const D2 = "1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d";

const wireDomain = {
  id: D1,
  host: "www.example.com",
  status: "pending" as const,
  isPrimary: false,
  records: [
    { type: "CNAME" as const, name: "www", value: "cname.vercel-dns.com" },
    { type: "TXT" as const, name: "_vercel", value: "vc-domain-verify=www.example.com,abc123" },
  ],
  misconfigured: true,
  vercelVerified: false,
  error: null,
  createdAt: "2026-11-26T10:00:00.000Z",
  verifiedAt: null,
  checkedAt: "2026-11-26T10:05:00.000Z",
  expiresAt: "2026-12-03T10:00:00.000Z",
};

const verified: ProductDomain = {
  ...wireDomain,
  id: D2,
  host: "example.com",
  status: "verified",
  isPrimary: true,
  records: [{ type: "A", name: "@", value: "76.76.21.21" }],
  misconfigured: false,
  vercelVerified: true,
  verifiedAt: "2026-11-26T11:00:00.000Z",
};

/** The backend's 502 sentence when Vercel does not let a removed domain go. */
const REMOVE_502 = "Vercel did not let the domain go; it is being removed, try again in a minute";

/** The error the transport throws for a non-ok response with this JSON body. */
const refusal = (status: number, body: unknown) =>
  responseError(new Response(JSON.stringify(body), { status }), `HTTP ${status}`);

const switchOff = () => refusal(404, { error: { code: "not_found", message: "not found" } });

const callOf = (mock: typeof mockedJson | typeof mockedRequest, i = 0) => {
  const [url, init] = mock.mock.calls[i] as [string, RequestInit | undefined];
  const u = new URL(url, "https://x.test");
  return { path: u.pathname, params: Object.fromEntries(u.searchParams), init };
};
const call = (i = 0) => callOf(mockedJson, i);

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

// The provider's own default, retry once, with no delay so a retry lands inside the test.
function setup() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: 1, retryDelay: 0 } } });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  );
  return { qc, wrapper };
}

describe("productDomainsApi", () => {
  it("lists the domains from the backend's own route", async () => {
    mockedJson.mockResolvedValueOnce({ domains: [wireDomain] });
    expect(await productDomainsApi.list(ECO)).toEqual([wireDomain]);
    const c = call();
    expect(PRODUCT_DOMAINS_PATH).toBe("/api/ecosystem/product-domains");
    expect(c.path).toBe("/api/ecosystem/product-domains");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBeUndefined();
  });

  it("maps only the fields it knows", async () => {
    mockedJson.mockResolvedValueOnce({
      domains: [{ ...wireDomain, extra: "x", records: [{ ...wireDomain.records[0], ttl: 60 }] }],
    });
    const [d] = await productDomainsApi.list(ECO);
    expect(d).not.toHaveProperty("extra");
    expect(d?.records[0]).toEqual(wireDomain.records[0]);
  });

  it("reads a backend without checkedAt as never checked", async () => {
    const { checkedAt: _c, ...older } = wireDomain;
    mockedJson.mockResolvedValueOnce({ domains: [older] });
    const [d] = await productDomainsApi.list(ECO);
    expect(d?.checkedAt).toBeNull();
  });

  it("adds a host with POST { host }", async () => {
    mockedJson.mockResolvedValueOnce(wireDomain);
    expect(await productDomainsApi.add(ECO, "www.example.com")).toEqual(wireDomain);
    const c = call();
    expect(c.path).toBe("/api/ecosystem/product-domains");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("POST");
    expect(JSON.parse(String(c.init?.body))).toEqual({ host: "www.example.com" });
  });

  it("checks a domain with POST /:id/check and no body", async () => {
    mockedJson.mockResolvedValueOnce({ ...wireDomain, status: "verified" });
    expect((await productDomainsApi.check(ECO, D1)).status).toBe("verified");
    const c = call();
    expect(c.path).toBe(`/api/ecosystem/product-domains/${D1}/check`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("POST");
    expect(c.init?.body).toBeUndefined();
  });

  it("sets the primary with PATCH /:id { primary } and answers the list", async () => {
    mockedJson.mockResolvedValueOnce({ domains: [verified, wireDomain] });
    expect(await productDomainsApi.setPrimary(ECO, D2, true)).toEqual([verified, wireDomain]);
    const c = call();
    expect(c.path).toBe(`/api/ecosystem/product-domains/${D2}`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("PATCH");
    expect(JSON.parse(String(c.init?.body))).toEqual({ primary: true });
  });

  it("removes a domain with DELETE /:id through the no-body transport", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await expect(productDomainsApi.remove(ECO, D1)).resolves.toBeUndefined();
    const c = callOf(mockedRequest);
    expect(c.path).toBe(`/api/ecosystem/product-domains/${D1}`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("DELETE");
    expect(mockedJson).not.toHaveBeenCalled();
  });

  it("path-encodes the domain id", async () => {
    mockedJson.mockResolvedValueOnce(wireDomain);
    await productDomainsApi.check(ECO, "a/b");
    const [url] = mockedJson.mock.calls[0] as [string];
    expect(url).toContain("/api/ecosystem/product-domains/a%2Fb/check");
  });

  it("surfaces a coded refusal with its code and the backend's sentence", async () => {
    const message = "www.example.com is already another product's domain.";
    mockedJson.mockRejectedValueOnce(
      await refusal(409, { error: { code: "product_domain_taken", message } }),
    );
    const err = await productDomainsApi.add(ECO, "www.example.com").catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ProductDomainError);
    expect(err).toMatchObject({ status: 409, code: "product_domain_taken", message });
  });

  it("surfaces a refused DELETE as a ProductDomainError", async () => {
    mockedRequest.mockRejectedValueOnce(
      await refusal(502, { error: { code: "product_domain_vercel_unavailable", message: REMOVE_502 } }),
    );
    const err = await productDomainsApi.remove(ECO, D1).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ProductDomainError);
    expect(err).toMatchObject({
      status: 502,
      code: "product_domain_vercel_unavailable",
      message: REMOVE_502,
    });
  });

  it("passes a failure with no status through unchanged", async () => {
    const offline = new TypeError("Failed to fetch");
    mockedJson.mockRejectedValueOnce(offline);
    await expect(productDomainsApi.list(ECO)).rejects.toBe(offline);
  });
});

describe("productDomainsAvailable", () => {
  it("is false for the switch's 404 not_found", async () => {
    mockedJson.mockRejectedValueOnce(await switchOff());
    const err = await productDomainsApi.list(ECO).catch((e: unknown) => e);
    expect(productDomainsAvailable(err)).toBe(false);
  });

  it("is false for a 404 with no code", () => {
    expect(productDomainsAvailable(new ProductDomainError(404, "not found"))).toBe(false);
  });

  it("is true for a 404 with another code, any other refusal, or none", () => {
    expect(productDomainsAvailable(new ProductDomainError(404, "gone", "product_domain_not_found"))).toBe(true);
    expect(productDomainsAvailable(new ProductDomainError(500, "boom"))).toBe(true);
    expect(productDomainsAvailable(new TypeError("Failed to fetch"))).toBe(true);
    expect(productDomainsAvailable(null)).toBe(true);
  });
});

describe("useProductDomains", () => {
  it("asks once when the switch answers 404", async () => {
    mockedJson.mockRejectedValue(await switchOff());
    const { wrapper } = setup();
    const { result } = renderHook(() => useProductDomains(ECO), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(mockedJson).toHaveBeenCalledTimes(1);
    expect(result.current.error).toMatchObject({ status: 404, code: "not_found" });
  });

  it("still retries any other failure once", async () => {
    mockedJson.mockRejectedValue(await refusal(500, {}));
    const { wrapper } = setup();
    const { result } = renderHook(() => useProductDomains(ECO), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(mockedJson).toHaveBeenCalledTimes(2);
  });

  it("does not ask without an ecosystem", () => {
    const { wrapper } = setup();
    renderHook(() => useProductDomains(null), { wrapper });
    expect(mockedJson).not.toHaveBeenCalled();
  });
});

describe("useAddProductDomain", () => {
  it("appends the new domain to the list", async () => {
    mockedJson.mockResolvedValueOnce(wireDomain);
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified]);
    const { result } = renderHook(() => useAddProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync("www.example.com"));
    expect(qc.getQueryData(PRODUCT_DOMAINS_KEY(ECO))).toEqual([verified, wireDomain]);
  });

  it("leaves the list alone when refused", async () => {
    mockedJson.mockRejectedValueOnce(
      await refusal(400, { error: { code: "product_domain_invalid", message: "not a host" } }),
    );
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified]);
    const { result } = renderHook(() => useAddProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync("nope").catch(() => undefined));
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toMatchObject({ code: "product_domain_invalid" });
    expect(qc.getQueryData(PRODUCT_DOMAINS_KEY(ECO))).toEqual([verified]);
  });
});

describe("useCheckProductDomain", () => {
  it("replaces the checked row in the list", async () => {
    const after = { ...wireDomain, status: "verified" as const, misconfigured: false };
    mockedJson.mockResolvedValueOnce(after);
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified, wireDomain]);
    const { result } = renderHook(() => useCheckProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync(D1));
    expect(qc.getQueryData(PRODUCT_DOMAINS_KEY(ECO))).toEqual([verified, after]);
  });
});

describe("useSetPrimaryProductDomain", () => {
  it("sets the list and invalidates the product site", async () => {
    const demoted = { ...verified, isPrimary: false };
    const promoted = { ...wireDomain, status: "verified" as const, isPrimary: true };
    mockedJson.mockResolvedValueOnce({ domains: [demoted, promoted] });
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified, wireDomain]);
    const invalidate = vi.spyOn(qc, "invalidateQueries");
    const { result } = renderHook(() => useSetPrimaryProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync({ domainId: D1, primary: true }));
    expect(qc.getQueryData(PRODUCT_DOMAINS_KEY(ECO))).toEqual([demoted, promoted]);
    expect(invalidate).toHaveBeenCalledWith({ queryKey: PRODUCT_SITE_KEY(ECO) });
  });
});

describe("useRemoveProductDomain", () => {
  it("drops the row and invalidates the product site", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified, wireDomain]);
    const invalidate = vi.spyOn(qc, "invalidateQueries");
    const { result } = renderHook(() => useRemoveProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync(D2));
    expect(qc.getQueryData(PRODUCT_DOMAINS_KEY(ECO))).toEqual([wireDomain]);
    expect(invalidate).toHaveBeenCalledWith({ queryKey: PRODUCT_SITE_KEY(ECO) });
    expect(invalidate).not.toHaveBeenCalledWith({ queryKey: PRODUCT_DOMAINS_KEY(ECO) });
  });

  it("invalidates the list on a 502, since the row is left removing", async () => {
    mockedRequest.mockRejectedValueOnce(
      await refusal(502, { error: { code: "product_domain_vercel_unavailable", message: REMOVE_502 } }),
    );
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified, wireDomain]);
    const invalidate = vi.spyOn(qc, "invalidateQueries");
    const { result } = renderHook(() => useRemoveProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync(D1).catch(() => undefined));
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(invalidate).toHaveBeenCalledWith({ queryKey: PRODUCT_DOMAINS_KEY(ECO) });
    expect(invalidate).toHaveBeenCalledWith({ queryKey: PRODUCT_SITE_KEY(ECO) });
  });

  it("leaves the list alone on another refusal", async () => {
    mockedRequest.mockRejectedValueOnce(
      await refusal(409, { error: { code: "product_domain_busy", message: "busy" } }),
    );
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_DOMAINS_KEY(ECO), [verified, wireDomain]);
    const invalidate = vi.spyOn(qc, "invalidateQueries");
    const { result } = renderHook(() => useRemoveProductDomain(ECO), { wrapper });
    await act(() => result.current.mutateAsync(D1).catch(() => undefined));
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(qc.getQueryData(PRODUCT_DOMAINS_KEY(ECO))).toEqual([verified, wireDomain]);
    expect(invalidate).not.toHaveBeenCalledWith({ queryKey: PRODUCT_DOMAINS_KEY(ECO) });
  });
});
