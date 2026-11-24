// Every test in packages/data/src lives under a `__tests__/` sibling — no exceptions.
// One `it` per row of cookbook/adh/hub/profile/conformance-test-vectors.md, titled by its vector id.
// Vectors whose expectation is a doc comment, a type-level constraint, or "no X appears anywhere in
// the source" cannot be exercised by a runtime assertion and are skipped with that reason.
import { describe, expect, it, vi, beforeEach } from "vitest";

import * as profile from "../profile";
import * as usage from "../usage";
import {
  addressesKey,
  createAddress,
  deleteAddress,
  getPrivacyGrants,
  listAddresses,
  listSocialLinks,
  resolvePrivacyLevel,
  setPrivacyGrant,
  socialLinksKey,
  updateAddress,
  PRIVACY_KEY,
  type PrivacyGrant,
} from "../profile";
import { getUsageSummary, usageSummaryKey } from "../usage";

const fetchMock = vi.fn();

const respondWith = (body: unknown) =>
  fetchMock.mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => body,
    text: async () => JSON.stringify(body),
  });

const list = (data: unknown[]) => ({ object: "list", data, has_more: false, url: "" });

beforeEach(() => {
  fetchMock.mockReset();
  respondWith(list([]));
  vi.stubGlobal("fetch", fetchMock);
});

const urlAt = (n = 0) => String(fetchMock.mock.calls[n]![0]);
const initAt = (n = 0) => (fetchMock.mock.calls[n]![1] ?? {}) as RequestInit;
const pathAt = (n = 0) => new URL(urlAt(n), "http://x").pathname;
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

const addressRow = {
  id: "addr1",
  ...ownerCols,
  label: "Home",
  line1: "1 Main St",
  line2: "",
  city: "Springfield",
  region: "IL",
  postal_code: "62701",
  country: "US",
};

const ADDRESS_INPUT = {
  label: "Home",
  line1: "1 Main St",
  line2: "",
  city: "Springfield",
  region: "IL",
  postalCode: "62701",
  country: "US",
};

const ADDRESS_BODY = {
  label: "Home",
  line1: "1 Main St",
  line2: "",
  city: "Springfield",
  region: "IL",
  postal_code: "62701",
  country: "US",
};

const grant = (audienceMask: number): PrivacyGrant => ({
  targetTable: "addresses",
  targetId: "a1",
  audienceMask,
});

describe("profile conformance vectors", () => {
  it("hub-domain-profile-001 lists social links at the v1 path with no workspace query", async () => {
    await listSocialLinks();
    expect(pathAt()).toBe("/api/v1/content/social_links");
    expect(params().has("workspace")).toBe(false);
  });

  it("hub-domain-profile-002 lists social links with ?workspace=acme", async () => {
    await listSocialLinks({ workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/content/social_links");
    expect(params().get("workspace")).toBe("acme");
  });

  it("hub-domain-profile-003 percent-encodes the workspace slug on the addresses list", async () => {
    await listAddresses({ workspace: "a/b" });
    expect(pathAt()).toBe("/api/v1/content/addresses");
    expect(urlAt()).toContain("workspace=a%2Fb");
  });

  it("hub-domain-profile-004 omits ?workspace= on the addresses list when absent", async () => {
    await listAddresses();
    expect(pathAt()).toBe("/api/v1/content/addresses");
    expect(urlAt()).not.toContain("workspace");
  });

  it("hub-domain-profile-005 posts a social-link create with the workspace query and verbatim body", async () => {
    respondWith({ id: "s1", ...ownerCols, platform: "github", url: "https://x", handle: "", sort_order: 0 });
    const created = await profile.createSocialLink(
      { platform: "github", url: "https://x", handle: "" },
      { workspace: "acme" },
    );
    expect(pathAt()).toBe("/api/v1/content/social_links");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("POST");
    expect(initAt().body).toBe(JSON.stringify({ platform: "github", url: "https://x", handle: "" }));
    expect(created.platform).toBe("github");
    expect(created.id).toBe("s1");
  });

  it("hub-domain-profile-006 posts a social-link update on the item path with the workspace query", async () => {
    respondWith({ id: "id1", ...ownerCols, platform: "github", url: "https://x", handle: "", sort_order: 0 });
    await profile.updateSocialLink(
      "id1",
      { platform: "github", url: "https://x", handle: "" },
      { workspace: "acme" },
    );
    expect(pathAt()).toBe("/api/v1/content/social_links/id1");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("POST");
    expect(initAt().body).toBe(JSON.stringify({ platform: "github", url: "https://x", handle: "" }));
  });

  it("hub-domain-profile-007 deletes a social link and resolves with no value", async () => {
    respondWith({ id: "id1", deleted: true });
    const result = await profile.deleteSocialLink("id1", { workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/content/social_links/id1");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("DELETE");
    expect(result).toBeUndefined();
  });

  it("hub-domain-profile-008 posts an address create with the workspace query and snake_case body", async () => {
    respondWith(addressRow);
    await createAddress(ADDRESS_INPUT, { workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/content/addresses");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual(ADDRESS_BODY);
  });

  it("hub-domain-profile-009 posts an address update on the item path with the workspace query", async () => {
    respondWith(addressRow);
    await updateAddress("addr1", ADDRESS_INPUT, { workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/content/addresses/addr1");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual(ADDRESS_BODY);
  });

  it("hub-domain-profile-010 deletes an address and resolves with no value", async () => {
    respondWith({ id: "addr1", deleted: true });
    const result = await deleteAddress("addr1", { workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/content/addresses/addr1");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method).toBe("DELETE");
    expect(result).toBeUndefined();
  });

  it("hub-domain-profile-011 namespaces the social-links key by owner", () => {
    const self = socialLinksKey();
    const org = socialLinksKey("acme");
    expect(self).toEqual(["profile", "social-links", "self"]);
    expect(org).toEqual(["profile", "social-links", "org", "acme"]);
    const isPrefix = (a: readonly string[], b: readonly string[]) => a.every((s, i) => b[i] === s);
    expect(isPrefix(self, org)).toBe(false);
    expect(isPrefix(org, self)).toBe(false);
    expect(addressesKey("acme")).toEqual(["profile", "addresses", "org", "acme"]);
  });

  it("hub-domain-profile-012 namespaces the usage-summary key by owner", () => {
    expect(usageSummaryKey("acme")).toEqual(["usage", "summary", "org", "acme"]);
    expect(usageSummaryKey()).toEqual(["usage", "summary", "self"]);
  });

  it("hub-domain-profile-013 exports the privacy key but not the un-namespaced root keys", () => {
    const exported = [...Object.keys(profile), ...Object.keys(usage)];
    expect(exported).not.toContain("SOCIAL_LINKS_KEY");
    expect(exported).not.toContain("ADDRESSES_KEY");
    expect(exported).not.toContain("USAGE_SUMMARY_KEY");
    expect(PRIVACY_KEY).toEqual(["account", "privacy"]);
  });

  it("hub-domain-profile-014 unwraps the privacy envelope to a bare camelCase array", async () => {
    respondWith({
      object: "account",
      privacy: { items: [{ target_table: "addresses", target_id: "a1", audience_mask: 1 }] },
    });
    expect(await getPrivacyGrants()).toEqual([{ targetTable: "addresses", targetId: "a1", audienceMask: 1 }]);
    expect(pathAt()).toBe("/api/v1/account");
    expect(params().getAll("include[]")).toEqual(["privacy"]);
  });

  it("hub-domain-profile-015 takes no workspace parameter on the privacy list and set operations", async () => {
    expect(getPrivacyGrants.length).toBe(0);
    expect(setPrivacyGrant.length).toBe(3);
    respondWith({ object: "account", privacy: { items: [] } });
    await (getPrivacyGrants as (...a: unknown[]) => Promise<unknown>)({ workspace: "acme" });
    expect(urlAt()).not.toContain("workspace");
  });

  it("hub-domain-profile-016 posts the privacy grant with the public audience mask", async () => {
    respondWith({ object: "account" });
    const result = await setPrivacyGrant("addresses", "a1", "public");
    expect(pathAt()).toBe("/api/v1/account");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual({
      privacy: { target_table: "addresses", target_id: "a1", audience_mask: 1 },
    });
    expect(result).toEqual({ targetTable: "addresses", targetId: "a1", audienceMask: 1 });
  });

  it("hub-domain-profile-017 resolves only-me for an empty grant list", () => {
    expect(resolvePrivacyLevel([], "addresses", "a1")).toBe("only-me");
  });

  it("hub-domain-profile-018 resolves from the first matching grant", () => {
    expect(resolvePrivacyLevel([grant(2), grant(1)], "addresses", "a1")).toBe("hub");
  });

  it("hub-domain-profile-019 resolves public when both audience bits are set", () => {
    expect(resolvePrivacyLevel([grant(3)], "addresses", "a1")).toBe("public");
  });

  it("hub-domain-profile-020 resolves hub for audience mask 2", () => {
    expect(resolvePrivacyLevel([grant(2)], "addresses", "a1")).toBe("hub");
  });

  it("hub-domain-profile-021 resolves only-me when the mask sets neither audience bit", () => {
    expect(resolvePrivacyLevel([grant(4)], "addresses", "a1")).toBe("only-me");
  });

  it("hub-domain-profile-022 reads the usage summary with the workspace query", async () => {
    respondWith(list([]));
    const rows = await getUsageSummary({ workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/usage/summary");
    expect(params().get("workspace")).toBe("acme");
    expect(initAt().method ?? "GET").toBe("GET");
    expect(rows).toEqual([]);
  });

  it("hub-domain-profile-023 omits ?workspace= on the usage summary when absent", async () => {
    await getUsageSummary();
    expect(pathAt()).toBe("/api/v1/usage/summary");
    expect(urlAt()).not.toContain("workspace");
  });

  it("hub-domain-profile-024 sends only the workspace slug, never a caller-chosen principal", async () => {
    await getUsageSummary({ workspace: "acme", principal: "u2", subjects: ["u3"] } as never);
    expect([...params().keys()].filter((k) => k !== "limit" && k !== "starting_after")).toEqual(["workspace"]);
  });

  it.skip("hub-domain-profile-025 write shapes reject id/missing syncTxid — type-level constraint, no runtime behavior", () => {});
  it.skip("hub-domain-profile-026 sortOrder doc comment — a source comment, not behavior", () => {});

  it("hub-domain-profile-027 accepts a target table the client has never declared", async () => {
    respondWith({ object: "account" });
    const result = await setPrivacyGrant("table_added_later" as never, "x1", "hub");
    expect(JSON.parse(String(initAt().body)).privacy.target_table).toBe("table_added_later");
    expect(result.audienceMask).toBe(2);
  });

  it.skip("hub-domain-profile-028 usage-limits enforced doc comment — a source comment, not behavior", () => {});
  it.skip("hub-domain-profile-029 usage-row kind doc comment — a source comment, not behavior", () => {});
  it.skip("hub-domain-profile-030 no mutable module state and no response validation — structural, verified by reading the function bodies", () => {});
  it.skip("hub-domain-profile-031 only the shared HTTP helper's calls are imported — structural, verified by reading the imports", () => {});

  it("hub-domain-profile-032 rejects with the shared client's error on a non-2xx response", async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 500,
      statusText: "Server Error",
      json: async () => ({ error: { message: "boom" } }),
      text: async () => JSON.stringify({ error: { message: "boom" } }),
    });
    await expect(listSocialLinks()).rejects.toThrow();
    await expect(setPrivacyGrant("addresses", "a1", "hub")).rejects.toThrow();
  });

  it.skip("hub-domain-profile-033 set operation has no caller-identity branching — structural, verified by reading the function body", () => {});
  it.skip("hub-domain-profile-034 no client-side storage call in this domain's source — a source search, not behavior", () => {});
});
