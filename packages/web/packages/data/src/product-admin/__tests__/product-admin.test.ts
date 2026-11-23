// Recipe: adhsdk data, the product admin clients (phase 6).
// Only the transport is stubbed, so the path, method, query and body each call puts on the wire
// are asserted: the ecosystem uuid on every call, POST where /v1 turns the backend's PUT into one.
import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import {
  adminSiteApi,
  DEFAULT_QUOTA_BYTES,
  fetchProductTotals,
  isAdminSeatProtected,
  productAdminApi,
} from "..";
import { authedJson, authedRequest } from "../../http";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);

const ECO = "0b9c4a52-6c3e-4d7e-9a1f-2f4c1d2e3a4b";
const CUST = "7a1e2b3c-4d5e-4f60-8a9b-0c1d2e3f4a5b";

const call = (m: typeof mockedJson | typeof mockedRequest, i = 0) => {
  const [url, init] = m.mock.calls[i] as [string, RequestInit | undefined];
  const u = new URL(url, "https://x.test");
  return { path: u.pathname, params: Object.fromEntries(u.searchParams), init };
};

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
  mockedRequest.mockResolvedValue(undefined);
});

describe("DEFAULT_QUOTA_BYTES", () => {
  it("is the backend's 5 GiB", () => {
    expect(DEFAULT_QUOTA_BYTES).toBe(5 * 1024 ** 3);
  });
});

describe("totals", () => {
  it("GETs the totals with the uuid and camel-cases the body", async () => {
    mockedJson.mockResolvedValueOnce({
      customers: 3,
      new7d: 1,
      new30d: 2,
      active7d: 1,
      active30d: 3,
      storage_bytes: 42,
      jobs_by_status: { done: 7, failed: 1 },
      pending_invitations: 4,
      pending_requests: 5,
    });
    const t = await fetchProductTotals(ECO);
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/product_admin/totals");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method ?? "GET").toBe("GET");
    expect(t).toEqual({
      customers: 3,
      new7d: 1,
      new30d: 2,
      active7d: 1,
      active30d: 3,
      storageBytes: 42,
      jobsByStatus: { done: 7, failed: 1 },
      pendingInvitations: 4,
      pendingRequests: 5,
    });
  });

  it("reads a body without jobs_by_status as no jobs", async () => {
    mockedJson.mockResolvedValueOnce({
      customers: 0,
      new7d: 0,
      new30d: 0,
      active7d: 0,
      active30d: 0,
      storage_bytes: 0,
      pending_invitations: 0,
      pending_requests: 0,
    });
    expect((await fetchProductTotals(ECO)).jobsByStatus).toEqual({});
  });
});

describe("productAdminApi", () => {
  it("lists one roster page with q and cursor and maps each row", async () => {
    mockedJson.mockResolvedValueOnce({
      items: [
        {
          id: CUST,
          email: "a@x.test",
          display_name: "A",
          avatar_url: "",
          external_id: null,
          created: 1_700_000_000,
          last_active_day: "2026-11-20",
          roles: [{ id: "r1", slug: "admin", name: "Admin" }],
          sets: ["s1"],
          storage_bytes: 10,
          quota_bytes: 20,
          paused: true,
        },
      ],
      next_cursor: "c2",
    });
    const page = await productAdminApi.customers(ECO, { q: "a@", cursor: "c1" });
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/product_admin/customers");
    expect(c.params).toEqual({ ecosystem: ECO, q: "a@", cursor: "c1" });
    expect(page.nextCursor).toBe("c2");
    expect(page.items[0]).toEqual({
      id: CUST,
      email: "a@x.test",
      displayName: "A",
      avatarUrl: null,
      externalId: null,
      createdAt: new Date(1_700_000_000 * 1000).toISOString(),
      lastActiveDay: "2026-11-20",
      roles: [{ id: "r1", slug: "admin", name: "Admin" }],
      sets: ["s1"],
      storageBytes: 10,
      quotaBytes: 20,
      paused: true,
    });
  });

  it("leaves q and cursor off when they are empty", async () => {
    mockedJson.mockResolvedValueOnce({ items: [], next_cursor: null });
    await productAdminApi.customers(ECO);
    expect(call(mockedJson).params).toEqual({ ecosystem: ECO });
  });

  it("pauses with POST and the reason", async () => {
    mockedJson.mockResolvedValueOnce({ paused: true });
    expect(await productAdminApi.pause(ECO, CUST, "spam")).toEqual({ paused: true });
    const c = call(mockedJson);
    expect(c.path).toBe(`/api/v1/product_admin/customers/${CUST}/pause`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("POST");
    expect(JSON.parse(String(c.init?.body))).toEqual({ reason: "spam" });
  });

  it("lifts a pause with DELETE", async () => {
    await productAdminApi.unpause(ECO, CUST);
    const c = call(mockedRequest);
    expect(c.path).toBe(`/api/v1/product_admin/customers/${CUST}/pause`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("DELETE");
  });

  it("sets the quota with POST (the backend's PUT) and reads quota_bytes back", async () => {
    mockedJson.mockResolvedValueOnce({ quota_bytes: 1024 });
    expect(await productAdminApi.setQuota(ECO, CUST, 1024)).toEqual({ quotaBytes: 1024 });
    const c = call(mockedJson);
    expect(c.path).toBe(`/api/v1/product_admin/customers/${CUST}/quota`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("POST");
    expect(JSON.parse(String(c.init?.body))).toEqual({ bytes: 1024 });
  });

  it("deletes a customer with DELETE", async () => {
    await productAdminApi.deleteCustomer(ECO, CUST);
    const c = call(mockedRequest);
    expect(c.path).toBe(`/api/v1/product_admin/customers/${CUST}`);
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("DELETE");
  });
});

describe("isAdminSeatProtected", () => {
  it("recognizes the 422 admin_seat_protected body", () => {
    const body = { error: { code: "admin_seat_protected", message: "no" } };
    expect(isAdminSeatProtected(new AuthHttpError(422, "no", undefined, body))).toBe(true);
    expect(isAdminSeatProtected(new AuthHttpError(422, "no", "admin_seat_protected"))).toBe(true);
  });

  it("refuses any other error", () => {
    expect(isAdminSeatProtected(new AuthHttpError(422, "no", "other"))).toBe(false);
    expect(isAdminSeatProtected(new AuthHttpError(403, "no", "admin_seat_protected"))).toBe(false);
    expect(isAdminSeatProtected(new Error("x"))).toBe(false);
  });
});

describe("adminSiteApi", () => {
  const siteWire = {
    id: "as1",
    host: "admin.example.test",
    application_id: "app1",
    client_id: "cl1",
    created: 1_700_000_000,
    updated: 1_700_000_100,
  };

  it("reads the site and the switch", async () => {
    mockedJson.mockResolvedValueOnce({ site: siteWire, enabled: true });
    const s = await adminSiteApi.get(ECO);
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/admin_site");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(s.enabled).toBe(true);
    expect(s.site).toMatchObject({ host: "admin.example.test", applicationId: "app1", clientId: "cl1" });
  });

  it("reads no site", async () => {
    mockedJson.mockResolvedValueOnce({ site: null, enabled: false });
    expect(await adminSiteApi.get(ECO)).toEqual({ site: null, enabled: false });
  });

  it("sets the site up with POST and the host", async () => {
    mockedJson.mockResolvedValueOnce({ site: siteWire, enabled: true });
    await adminSiteApi.put(ECO, "admin.example.test");
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/admin_site");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("POST");
    expect(JSON.parse(String(c.init?.body))).toEqual({ host: "admin.example.test" });
  });

  it("takes the site down with DELETE", async () => {
    await adminSiteApi.remove(ECO);
    const c = call(mockedRequest);
    expect(c.path).toBe("/api/v1/admin_site");
    expect(c.params).toEqual({ ecosystem: ECO });
    expect(c.init?.method).toBe("DELETE");
  });
});
