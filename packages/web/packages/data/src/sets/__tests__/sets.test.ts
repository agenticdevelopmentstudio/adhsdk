// Recipe: adhsdk data, the web sets client (phase 5).
// Only the transport is stubbed, so the URL and body the client puts on the wire are asserted.
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import {
  asSetRefusedError,
  isEffectiveSets,
  SetRefusedError,
  setEntryFeatures,
  setsApi,
  toSetEntries,
  toSetsAnswer,
} from "..";
import { toCatalogFeature } from "../../ecosystems/ecosystem-features";
import { authedJson, authedRequest, listAllV1 } from "../../http";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);
const mockedList = vi.mocked(listAllV1);

const setWire = (over: Record<string, unknown> = {}) => ({
  id: "s-1",
  slug: "pro",
  name: "Pro",
  description: "",
  is_default: false,
  is_personal: false,
  personal_customer_id: null,
  contains: ["s-0"],
  values: [{ kind: "limit", key: "usage.tier", value: "pro" }],
  ...over,
});

const body = (i = 0) => JSON.parse(String((mockedJson.mock.calls[i]![1] as RequestInit).body));
const url = (i = 0) => String(mockedJson.mock.calls[i]![0]);

const refusal = (error: Record<string, unknown>) =>
  new AuthHttpError(422, "refused", "set_refused", { error: { type: "invalid_request_error", ...error } });

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
  mockedList.mockReset();
});

describe("setsApi: sets", () => {
  it("lists the ecosystem's sets by name, camel-cased; personal sets only when asked", async () => {
    mockedList.mockResolvedValueOnce([setWire({ id: "s-2", name: "Team" }), setWire()]);
    const sets = await setsApi.list("eco 1");
    expect(mockedList).toHaveBeenCalledWith("/api/v1/sets?ecosystem=eco+1");
    expect(sets.map((s) => s.name)).toEqual(["Pro", "Team"]);
    expect(sets[0]).toEqual({
      id: "s-1",
      slug: "pro",
      name: "Pro",
      description: "",
      isDefault: false,
      isPersonal: false,
      personalCustomerId: null,
      contains: ["s-0"],
      values: [{ kind: "limit", key: "usage.tier", value: "pro" }],
    });

    mockedList.mockResolvedValueOnce([]);
    await setsApi.list("eco-1", { personal: true });
    expect(mockedList).toHaveBeenLastCalledWith("/api/v1/sets?ecosystem=eco-1&personal=true");
  });

  it("creates and edits with snake_case bodies, sending only what is given", async () => {
    mockedJson.mockResolvedValue(setWire());
    await setsApi.create("eco-1", { slug: "pro", name: "Pro", isDefault: true });
    expect(url()).toBe("/api/v1/sets?ecosystem=eco-1");
    expect(body()).toEqual({ slug: "pro", name: "Pro", is_default: true });

    await setsApi.create("eco-1", { slug: "me", name: "Me", personalCustomerId: "c-1" });
    expect(body(1)).toEqual({ slug: "me", name: "Me", personal_customer_id: "c-1" });

    await setsApi.edit("eco-1", "s-1", { name: "Pro plus" });
    expect(url(2)).toBe("/api/v1/sets/s-1?ecosystem=eco-1");
    expect((mockedJson.mock.calls[2]![1] as RequestInit).method).toBe("POST");
    expect(body(2)).toEqual({ name: "Pro plus" });
  });

  it("replaces containment and values on their own routes", async () => {
    mockedJson.mockResolvedValue(setWire());
    await setsApi.setMembers("eco-1", "s-1", ["s-0", "s-3"]);
    expect(url()).toBe("/api/v1/sets/s-1/members?ecosystem=eco-1");
    expect(body()).toEqual({ contains: ["s-0", "s-3"] });

    const values = [
      { kind: "permission" as const, key: "storage", value: true },
      { kind: "limit" as const, key: "storage.bytes", value: 1024 },
    ];
    await setsApi.setValues("eco-1", "s-1", values);
    expect(url(1)).toBe("/api/v1/sets/s-1/values?ecosystem=eco-1");
    expect(body(1)).toEqual({ values });
  });

  it("deletes by id", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await setsApi.remove("eco-1", "s-1");
    const [u, init] = mockedRequest.mock.calls[0] as [string, RequestInit];
    expect(u).toBe("/api/v1/sets/s-1?ecosystem=eco-1");
    expect(init.method).toBe("DELETE");
  });
});

describe("setsApi: grants and effective answers", () => {
  it("lists a customer's grants, owner_id read as the customer", async () => {
    mockedList.mockResolvedValueOnce([
      {
        id: "g-1",
        ecosystem_id: "eco-1",
        owner_id: "c-1",
        set_id: "s-1",
        source: "direct",
        billing_account_id: null,
        granted_by: "u-1",
        granted_at: "2026-11-01T00:00:00.000Z",
        revoked_at: null,
        revoke_reason: null,
      },
    ]);
    const grants = await setsApi.grants("eco-1", "c-1");
    expect(mockedList).toHaveBeenCalledWith("/api/v1/set_grants?ecosystem=eco-1&customer=c-1");
    expect(grants[0]).toMatchObject({ customerId: "c-1", setId: "s-1", source: "direct", revokedAt: null });
  });

  it("grants, reporting what the grant revoked, and revokes by grant id", async () => {
    mockedJson.mockResolvedValueOnce({ grant_id: "g-2", revoked: ["g-1"] });
    expect(await setsApi.grant("eco-1", { customerId: "c-1", setId: "s-2" })).toEqual({
      grantId: "g-2",
      revoked: ["g-1"],
    });
    expect(url()).toBe("/api/v1/set_grants?ecosystem=eco-1");
    expect(body()).toEqual({ customer_id: "c-1", set_id: "s-2" });

    mockedRequest.mockResolvedValueOnce(undefined);
    await setsApi.revoke("eco-1", "g-2");
    expect(mockedRequest.mock.calls[0]![0]).toBe("/api/v1/set_grants/g-2?ecosystem=eco-1");
  });

  it("reads the effective answer in each of its three forms", async () => {
    mockedJson.mockResolvedValueOnce({
      held: ["s-1"],
      permissions: ["storage"],
      read_only: [],
      limits: { "usage.tier": "pro" },
      valid_until: null,
    });
    const a = await setsApi.effective("eco-1", "c-1");
    expect(url()).toBe("/api/v1/set_grants/effective/c-1?ecosystem=eco-1");
    expect(a).toEqual({
      held: ["s-1"],
      permissions: ["storage"],
      readOnly: [],
      limits: { "usage.tier": "pro" },
      validUntil: null,
    });
    expect(isEffectiveSets(a)).toBe(true);

    expect(toSetsAnswer(null)).toBeNull();
    expect(toSetsAnswer(undefined)).toBeNull();
    const unresolved = toSetsAnswer({ error: "unresolved" });
    expect(unresolved).toEqual({ error: "unresolved" });
    expect(isEffectiveSets(unresolved)).toBe(false);
    expect(isEffectiveSets(null)).toBe(false);
  });

  it("sets or clears the set an offer sells", async () => {
    mockedJson.mockResolvedValue({ offer_id: "o-1", set_id: null });
    await setsApi.setOfferSet("eco-1", "o-1", "s-1");
    expect(url()).toBe("/api/v1/offers/o-1/set?ecosystem=eco-1");
    expect(body()).toEqual({ set_id: "s-1" });
    await setsApi.setOfferSet("eco-1", "o-1", null);
    expect(body(1)).toEqual({ set_id: null });
  });
});

describe("refusals", () => {
  it("turns a 422 set_refused into a SetRefusedError carrying the rule", async () => {
    mockedJson.mockRejectedValueOnce(
      refusal({ code: "set_refused", message: "a containment loop", rule: 6 }),
    );
    const err = await setsApi.setMembers("eco-1", "s-1", ["s-1"]).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(SetRefusedError);
    expect((err as SetRefusedError).refusal).toEqual({ rule: 6, message: "a containment loop" });
  });

  it("keeps the limits, containers and holder count a refusal names", () => {
    const e = asSetRefusedError(
      refusal({ code: "set_refused", message: "m", rule: 8, limits: ["usage.tier"], containers: ["s-9"], customers: 2 }),
    );
    expect(e?.refusal).toEqual({ rule: 8, message: "m", limits: ["usage.tier"], containers: ["s-9"], customers: 2 });
  });

  it("leaves every other error as it was", async () => {
    expect(asSetRefusedError(new AuthHttpError(422, "bad", "invalid", { error: { code: "invalid" } }))).toBeNull();
    expect(asSetRefusedError(new AuthHttpError(400, "bad"))).toBeNull();
    expect(asSetRefusedError(new Error("network"))).toBeNull();

    const plain = new AuthHttpError(403, "forbidden");
    mockedJson.mockRejectedValueOnce(plain);
    await expect(setsApi.create("eco-1", { slug: "a", name: "A" })).rejects.toBe(plain);
  });
});

describe("the catalog's setEntries", () => {
  it("maps set_entries onto the catalog feature, and drops an empty one", () => {
    const base = { key: "storage", label: "Storage", description: "", subscription_tier: "free" as const };
    const f = toCatalogFeature({
      ...base,
      set_entries: { permission: true, limits: [{ key: "storage.bytes", type: "bytes", label: "Storage" }] },
    });
    expect(f.setEntries).toEqual({
      permission: true,
      limits: [{ key: "storage.bytes", type: "bytes", label: "Storage" }],
    });
    expect(toCatalogFeature(base).setEntries).toBeUndefined();
    expect(toSetEntries({ limits: [] })).toBeUndefined();
  });

  it("keeps only the features that contribute, in catalog order", () => {
    const rows = setEntryFeatures([
      { key: "b", label: "B", setEntries: { permission: true } },
      { key: "a", label: "A" },
      { key: "c", label: "C", setEntries: { limits: [{ key: "usage.tier", type: "tier", label: "Tier" }] } },
    ]);
    expect(rows.map((r) => r.key)).toEqual(["b", "c"]);
  });
});
