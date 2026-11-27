// Recipe: adhsdk data, the product-sites client (phase 5).
// Only the transport is stubbed, so the path, method, query and body each call puts on the wire
// are asserted, and the hooks' own retry and cache rules are the ones under test. Refusals are
// built by the transport's own `responseError` from the backend's real bodies, so the sentence a
// ProductSiteError carries is the one the backend wrote.
import type { ReactNode } from "react";
import { renderHook, waitFor, cleanup, act } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
}));

import { responseError } from "@adh-sdk/auth/client";
import {
  PRODUCT_SITE_KEY,
  PRODUCT_SITE_PATH,
  ProductSiteError,
  productSiteApi,
  useProductSite,
  useUpdateProductSite,
} from "..";
import { authedJson } from "../../http";

const mockedJson = vi.mocked(authedJson);

const ECO = "0b9c4a52-6c3e-4d7e-9a1f-2f4c1d2e3a4b";

const wire = {
  ecosystemId: ECO,
  handle: "notes",
  primaryOrigin: "https://notes.agenticdeveloperhub.com",
  subdomainOrigin: "https://notes.agenticdeveloperhub.com",
  adminEnabled: true,
  adminClientId: "cl1",
  consoleLive: true,
  contentGated: false,
};

/** The error the transport throws for a non-ok response with this JSON body. */
const refusal = (status: number, body: unknown) =>
  responseError(new Response(JSON.stringify(body), { status }), `HTTP ${status}`);

const call = (i = 0) => {
  const [url, init] = mockedJson.mock.calls[i] as [string, RequestInit | undefined];
  const u = new URL(url, "https://x.test");
  return { path: u.pathname, params: Object.fromEntries(u.searchParams), init };
};

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

describe("productSiteApi", () => {
  it("reads the site from the backend's own route", async () => {
    mockedJson.mockResolvedValueOnce(wire);
    expect(await productSiteApi.get(ECO)).toEqual(wire);
    const c = call();
    expect(PRODUCT_SITE_PATH).toBe("/api/ecosystem/product-site");
    expect(c.path).toBe("/api/ecosystem/product-site");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBeUndefined();
  });

  it("reads a backend without consoleLive or contentGated as neither", async () => {
    const { consoleLive: _l, contentGated: _g, ...older } = wire;
    mockedJson.mockResolvedValueOnce(older);
    const s = await productSiteApi.get(ECO);
    expect(s.consoleLive).toBe(false);
    expect(s.contentGated).toBe(false);
  });

  it("reads a backend without subdomainOrigin as null", async () => {
    const { subdomainOrigin: _s, ...older } = wire;
    mockedJson.mockResolvedValueOnce(older);
    expect((await productSiteApi.get(ECO)).subdomainOrigin).toBeNull();
  });

  it("changes the site with PATCH and only the fields given", async () => {
    mockedJson.mockResolvedValueOnce({ ...wire, handle: "jots" });
    expect((await productSiteApi.update(ECO, { handle: "jots" })).handle).toBe("jots");
    const c = call();
    expect(c.path).toBe("/api/ecosystem/product-site");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("PATCH");
    expect(JSON.parse(String(c.init?.body))).toEqual({ handle: "jots" });
  });

  it("surfaces a coded 409 with its code and the backend's sentence", async () => {
    const message =
      "notes.agenticdeveloperhub.com is already another product's address. Choose another handle.";
    mockedJson.mockRejectedValueOnce(
      await refusal(409, { error: { code: "product_site_handle_taken", message } }),
    );
    const err = await productSiteApi.update(ECO, { handle: "notes" }).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ProductSiteError);
    expect(err).toMatchObject({ status: 409, code: "product_site_handle_taken", message });
  });

  it("surfaces a 400 HTTPException's sentence", async () => {
    const message = "admin is reserved";
    mockedJson.mockRejectedValueOnce(await refusal(400, { error: { message } }));
    const err = await productSiteApi.update(ECO, { handle: "admin" }).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ProductSiteError);
    expect(err).toMatchObject({ status: 400, message });
    expect((err as ProductSiteError).code).toBeUndefined();
  });

  it("surfaces a top-level { message } body's sentence", async () => {
    mockedJson.mockRejectedValueOnce(await refusal(400, { message: "handle is too long" }));
    const err = await productSiteApi.update(ECO, { handle: "x" }).catch((e: unknown) => e);
    expect(err).toMatchObject({ status: 400, message: "handle is too long" });
  });

  it("passes a failure with no status through unchanged", async () => {
    const offline = new TypeError("Failed to fetch");
    mockedJson.mockRejectedValueOnce(offline);
    await expect(productSiteApi.get(ECO)).rejects.toBe(offline);
  });
});

describe("useProductSite", () => {
  // A workspace ecosystem is not a product, and AllDataPane asks about it anyway.
  it("asks once when the ecosystem answers 404", async () => {
    mockedJson.mockRejectedValue(await refusal(404, { error: { message: "ecosystem not found" } }));
    const { wrapper } = setup();
    const { result } = renderHook(() => useProductSite(ECO), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(mockedJson).toHaveBeenCalledTimes(1);
    expect(result.current.error).toMatchObject({ status: 404 });
  });

  it("still retries any other failure once", async () => {
    mockedJson.mockRejectedValue(await refusal(500, {}));
    const { wrapper } = setup();
    const { result } = renderHook(() => useProductSite(ECO), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(mockedJson).toHaveBeenCalledTimes(2);
  });

  it("does not ask without an ecosystem", () => {
    const { wrapper } = setup();
    renderHook(() => useProductSite(null), { wrapper });
    expect(mockedJson).not.toHaveBeenCalled();
  });
});

describe("useUpdateProductSite", () => {
  it("writes the answer into the site's query", async () => {
    mockedJson.mockResolvedValueOnce({ ...wire, adminEnabled: false });
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_SITE_KEY(ECO), wire);
    const { result } = renderHook(() => useUpdateProductSite(ECO), { wrapper });
    await act(() => result.current.mutateAsync({ adminEnabled: false }));
    expect(qc.getQueryData(PRODUCT_SITE_KEY(ECO))).toEqual({ ...wire, adminEnabled: false });
    expect(mockedJson).toHaveBeenCalledTimes(1);
  });

  it("leaves the query alone when refused", async () => {
    mockedJson.mockRejectedValueOnce(
      await refusal(409, { error: { code: "product_sites_unconfigured", message: "no base domain" } }),
    );
    const { qc, wrapper } = setup();
    qc.setQueryData(PRODUCT_SITE_KEY(ECO), wire);
    const { result } = renderHook(() => useUpdateProductSite(ECO), { wrapper });
    await act(() => result.current.mutateAsync({ adminEnabled: true }).catch(() => undefined));
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toMatchObject({ code: "product_sites_unconfigured" });
    expect(qc.getQueryData(PRODUCT_SITE_KEY(ECO))).toEqual(wire);
  });
});
