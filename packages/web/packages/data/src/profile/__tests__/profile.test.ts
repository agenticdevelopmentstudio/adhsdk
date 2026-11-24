// Pins the /v1 URL/method/body contract and the wire -> app mapping for the owner-scoped
// profile routes, with `fetch` stubbed (so `listAllV1`'s real paging runs) — mirrors access.test.ts.
//
// `?workspace=` is the whole reason the profile API is shared at all (a profile belongs to a
// PRINCIPAL, so the organizations site's Settings rail reads the same rows), and a contract test
// left behind in one host would have stopped seeing the code it names the moment the
// implementation moved.
import { describe, expect, it, vi, beforeEach } from "vitest";

import {
  listSocialLinks, createSocialLink, updateSocialLink, deleteSocialLink,
  listAddresses, createAddress, updateAddress,
  getPrivacyGrants, setPrivacyGrant,
} from "../profile";
import { getUsageSummary } from "../usage";

const fetchMock = vi.fn();

const respondWith = (body: unknown) =>
  fetchMock.mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => body,
    text: async () => JSON.stringify(body),
  });

const list = (data: unknown[], has_more = false) => ({ object: "list", data, has_more, url: "" });

beforeEach(() => {
  fetchMock.mockReset();
  respondWith(list([]));
  vi.stubGlobal("fetch", fetchMock);
});

const urlAt = (n = 0) => String(fetchMock.mock.calls[n]![0]);
const initAt = (n = 0) => (fetchMock.mock.calls[n]![1] ?? {}) as RequestInit;
const params = (n = 0) => new URL(urlAt(n), "http://x").searchParams;

const ownerCols = {
  deleted_at: null,
  ecosystem_id: "e1",
  owner_kind: "user",
  owner_id: "u1",
  author_kind: null,
  author_id: null,
  created: 1_700_000_000,
  updated: 1_700_000_060,
  sync_version: 3,
  sync_stamped_at: null,
  sync_txid: 9,
};

describe("profile api ?workspace= threading", () => {
  it("lists personal social links with no workspace param", async () => {
    await listSocialLinks();
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/content/social_links");
    expect(params().has("workspace")).toBe(false);
    expect(params().get("limit")).toBe("100");
  });

  it("lists org social links with ?workspace= when a slug is given", async () => {
    await listSocialLinks({ workspace: "acme" });
    expect(params().get("workspace")).toBe("acme");
  });

  it("encodes the workspace slug", async () => {
    await listAddresses({ workspace: "a/b" });
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/content/addresses");
    expect(urlAt()).toContain("workspace=a%2Fb");
  });

  it("drains every page of a list via starting_after", async () => {
    fetchMock
      .mockResolvedValueOnce({
        ok: true, status: 200,
        json: async () => list([{ id: "s1", ...ownerCols, platform: "a", url: "u", handle: "h", sort_order: 0 }], true),
        text: async () => "",
      })
      .mockResolvedValueOnce({
        ok: true, status: 200,
        json: async () => list([{ id: "s2", ...ownerCols, platform: "b", url: "u", handle: "h", sort_order: 1 }]),
        text: async () => "",
      });
    const rows = await listSocialLinks();
    expect(rows.map((r) => r.id)).toEqual(["s1", "s2"]);
    expect(params(1).get("starting_after")).toBe("s1");
  });

  it("maps a wire social link to the camelCase app shape with ISO timestamps", async () => {
    respondWith(list([{ id: "s1", ...ownerCols, platform: "github", url: "https://x", handle: "me", sort_order: 2 }]));
    expect(await listSocialLinks()).toEqual([
      {
        id: "s1",
        authorKind: null,
        authorId: null,
        deletedAt: null,
        ecosystemId: "e1",
        ownerKind: "user",
        ownerId: "u1",
        createdAt: new Date(1_700_000_000_000).toISOString(),
        updatedAt: new Date(1_700_000_060_000).toISOString(),
        syncVersion: 3,
        syncStampedAt: null,
        syncTxid: 9,
        platform: "github",
        url: "https://x",
        handle: "me",
        sortOrder: 2,
      },
    ]);
  });

  it("maps a wire address (postal_code -> postalCode)", async () => {
    respondWith(list([{
      id: "a1", ...ownerCols, label: "Home", line1: "1", line2: "", city: "c", region: "r",
      postal_code: "90210", country: "US",
    }]));
    const [a] = await listAddresses();
    expect(a!.postalCode).toBe("90210");
    expect(a!.createdAt).toBe(new Date(1_700_000_000_000).toISOString());
  });

  it("posts a create with the workspace query and a snake_case body", async () => {
    respondWith({ id: "s1", ...ownerCols, platform: "github", url: "https://x", handle: "", sort_order: 0 });
    await createSocialLink({ platform: "github", url: "https://x", handle: "", sortOrder: 4 }, { workspace: "acme" });
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/content/social_links");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual({
      platform: "github", url: "https://x", handle: "", sort_order: 4,
    });
  });

  it("posts an address create with postal_code", async () => {
    respondWith({ id: "a1", ...ownerCols, label: "Home", line1: "1", line2: "", city: "c", region: "r", postal_code: "p", country: "US" });
    await createAddress({ label: "Home", line1: "1", line2: "", city: "c", region: "r", postalCode: "p", country: "US" });
    expect(JSON.parse(String(initAt().body)).postal_code).toBe("p");
    expect(JSON.parse(String(initAt().body))).not.toHaveProperty("postalCode");
  });

  it("updates with POST on the item path + workspace query", async () => {
    respondWith({ id: "id1", ...ownerCols, platform: "github", url: "https://x", handle: "", sort_order: 0 });
    await updateSocialLink("id1", { platform: "github", url: "https://x", handle: "" }, { workspace: "acme" });
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/content/social_links/id1");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual({ platform: "github", url: "https://x", handle: "" });
  });

  it("updates an address with POST on the item path", async () => {
    respondWith({ id: "a1", ...ownerCols, label: "Home", line1: "1", line2: "", city: "c", region: "r", postal_code: "p", country: "US" });
    await updateAddress("a1", { label: "Home", line1: "1", line2: "", city: "c", region: "r", postalCode: "p", country: "US" });
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/content/addresses/a1");
    expect(initAt().method).toBe("POST");
  });

  it("deletes with id + workspace query", async () => {
    respondWith({ id: "id1", object: "content.social_link", deleted: true });
    await deleteSocialLink("id1", { workspace: "acme" });
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/content/social_links/id1");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("DELETE");
  });
});

describe("privacy grants ride /v1/account", () => {
  it("reads the `privacy` include and maps snake_case grants", async () => {
    respondWith({
      object: "account",
      privacy: { items: [{ target_table: "avatar", target_id: "u1", audience_mask: 3 }] },
    });
    expect(await getPrivacyGrants()).toEqual([
      { targetTable: "avatar", targetId: "u1", audienceMask: 3 },
    ]);
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/account");
    expect(params().getAll("include[]")).toEqual(["privacy"]);
  });

  it("reads an account with no privacy block as no grants", async () => {
    respondWith({ object: "account" });
    expect(await getPrivacyGrants()).toEqual([]);
  });

  it("writes a grant as POST /v1/account with a `privacy` body and maps the echo", async () => {
    respondWith({
      object: "account",
      privacy: { target_table: "social_links", target_id: "s1", audience_mask: 1 },
    });
    const g = await setPrivacyGrant("social_links", "s1", "public");
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/account");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual({
      privacy: { target_table: "social_links", target_id: "s1", audience_mask: 1 },
    });
    expect(g).toEqual({ targetTable: "social_links", targetId: "s1", audienceMask: 1 });
  });
});

describe("usage summary", () => {
  it("lists /v1/usage/summary with workspace and maps the snake_case row", async () => {
    respondWith(list([{
      kind: "self", scope: "user", principal_id: "u1", label: "Me", period_start: "2026-11-01",
      period_days: 30, tier: "free",
      limits: { quota_requests: 10, quota_bytes: null, quota_tokens: null, quota_cost_micros: 5, enforced: true },
      requests: 1, bytes: 2, tokens: 3, cost_micros: 4,
    }]));
    const rows = await getUsageSummary({ workspace: "acme" });
    expect(new URL(urlAt(), "http://x").pathname).toBe("/api/v1/usage/summary");
    expect(params().get("workspace")).toBe("acme");
    expect(rows).toEqual([{
      kind: "self", scope: "user", principalId: "u1", label: "Me", periodStart: "2026-11-01",
      periodDays: 30, tier: "free",
      limits: { quotaRequests: 10, quotaBytes: null, quotaTokens: null, quotaCostMicros: 5, enforced: true },
      requests: 1, bytes: 2, tokens: 3, costMicros: 4,
    }]);
  });
});
