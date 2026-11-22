// Recipe: adhsdk ecosystem-config, the web sign-up list client (phase 5).
// Only the transport is stubbed, so the URL and body the client puts on the wire are asserted.
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));

import { signupListApi } from "../signup-list";
import { authedJson, authedRequest, listAllV1 } from "../../http";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);
const mockedList = vi.mocked(listAllV1);

const row = (over: Record<string, unknown> = {}) => ({
  id: "e-1",
  email: "a@example.com",
  role_id: "r-1",
  set_id: null,
  created: 1767225600,
  granted_at: null,
  granted_customer_id: null,
  ...over,
});

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
  mockedList.mockReset();
});

describe("signupListApi", () => {
  it("lists the ecosystem's entries, camel-cased and sorted by email", async () => {
    mockedList.mockResolvedValueOnce([
      row({ id: "e-2", email: "z@example.com", role_id: null, granted_at: "2026-11-01T00:00:00.000Z", granted_customer_id: "c-1" }),
      row(),
    ]);
    const entries = await signupListApi.list("eco 1");
    expect(mockedList).toHaveBeenCalledWith("/api/v1/ecosystems/eco%201/signup_list_entries");
    expect(entries.map((e) => e.email)).toEqual(["a@example.com", "z@example.com"]);
    expect(entries[0]).toEqual({
      id: "e-1",
      email: "a@example.com",
      roleId: "r-1",
      setId: null,
      createdAt: "2026-01-01T00:00:00.000Z",
      grantedAt: null,
      grantedCustomerId: null,
    });
    expect(entries[1]).toMatchObject({ roleId: null, grantedCustomerId: "c-1" });
  });

  it("adds by POST with the email and the role, null when none is chosen", async () => {
    mockedJson.mockResolvedValueOnce(row());
    const entry = await signupListApi.put("eco-1", { email: "a@example.com", roleId: "r-1" });
    const [url, init] = mockedJson.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("/api/v1/ecosystems/eco-1/signup_list_entries");
    expect(init.method).toBe("POST");
    expect(JSON.parse(String(init.body))).toEqual({ email: "a@example.com", role_id: "r-1" });
    expect(entry.roleId).toBe("r-1");

    mockedJson.mockResolvedValueOnce(row({ role_id: null }));
    await signupListApi.put("eco-1", { email: "b@example.com" });
    const [, second] = mockedJson.mock.calls[1] as [string, RequestInit];
    expect(JSON.parse(String(second.body))).toEqual({ email: "b@example.com", role_id: null });
  });

  it("removes one entry by its id", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await signupListApi.remove("eco-1", "e-1");
    const [url, init] = mockedRequest.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("/api/v1/ecosystems/eco-1/signup_list_entries/e-1");
    expect(init.method).toBe("DELETE");
  });
});
