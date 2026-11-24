import { describe, expect, it, vi, beforeEach } from "vitest";
import { tokensApi } from "../tokens";
import { bucketAccessApi } from "../bucket-access";

// Conformance vectors for the security client
// (cookbook/adh/hub/security/security-client/conformance-test-vectors.md). Every vector id leads its test title.

type Reply = { status?: number; body?: unknown };
const fetchMock = vi.fn();

/** Queue one reply per fetch call (the last repeats). */
function reply(...replies: Reply[]) {
  fetchMock.mockReset();
  let i = 0;
  fetchMock.mockImplementation(async () => {
    const r = replies[Math.min(i++, replies.length - 1)]!;
    const status = r.status ?? 200;
    return {
      ok: status >= 200 && status < 300,
      status,
      json: async () => r.body,
      text: async () => JSON.stringify(r.body),
    };
  });
}

const url = (n = 0) => String(fetchMock.mock.calls[n]![0]);
const init = (n = 0) => (fetchMock.mock.calls[n]![1] ?? {}) as RequestInit;
const list = (data: unknown[]) => ({ object: "list", data, has_more: false, url: "" });
const errBody = (message: string, code?: string) => ({ error: { message, ...(code ? { code } : {}) } });

const tokenWire = { id: "t1", name: "ci", prefix: "abcd", created: 1767225600, expires_at: null, last_used_at: null };
const groupWire = {
  id: "g1", ecosystem_id: "e1", bucket_id: "b1", name: "Editors", description: "", kind: "custom",
  created: 1767225600, updated: 1767225600,
};
const memberWire = {
  id: "row-1", ecosystem_id: "e1", access_group_id: "g1", member_type: "persona", member_id: "p1",
  created: 1767225600, updated: 1767225600,
};
const grantWire = {
  id: "grant-1", ecosystem_id: "e1", access_group_id: "g1", target_type: "bucket_type", target_id: "bt1",
  crud: "C,R", created: 1767225600, updated: 1767225600,
};

beforeEach(() => {
  localStorage.clear();
  localStorage.setItem("auth_tokens", JSON.stringify({ accessToken: "tok-1", refreshToken: "" }));
  vi.stubGlobal("fetch", fetchMock);
  reply({ body: list([]) });
});

describe("security client conformance vectors", () => {
  it("hub-domain-security-001 token list reads the api_keys route and maps rows", async () => {
    reply({ body: list([tokenWire]) });
    const rows = await tokensApi.list();
    expect(new URL(url(), "http://x").pathname).toBe("/api/v1/api_keys");
    expect(init().method).toBeUndefined();
    expect(rows).toEqual([
      { id: "t1", name: "ci", prefix: "abcd", createdAt: "2026-01-01T00:00:00.000Z", expiresAt: null, lastUsedAt: null },
    ]);
  });

  it("hub-domain-security-002 token scopes unwraps the prefixes envelope", async () => {
    reply({ body: { prefixes: ["/content/markdown"] } });
    await expect(tokensApi.scopes()).resolves.toEqual(["/content/markdown"]);
    expect(url()).toBe("/api/v1/api_keys/scopes");
  });

  it("hub-domain-security-003 mint posts the name and scope and resolves the created token", async () => {
    reply({ status: 201, body: { ...tokenWire, token: "raw" } });
    const out = await tokensApi.mint({ name: "ci", scope: ["/content/markdown:read"] });
    expect(url()).toBe("/api/v1/api_keys");
    expect(init().method).toBe("POST");
    expect(JSON.parse(String(init().body))).toEqual({ name: "ci", scope: ["/content/markdown:read"] });
    expect(out.id).toBe("t1");
  });

  it("hub-domain-security-004 the minted secret is returned unmodified", async () => {
    reply({ status: 201, body: { ...tokenWire, token: "secret-raw-value" } });
    const out = await tokensApi.mint({ name: "ci" });
    expect(out.token).toBe("secret-raw-value");
  });

  it("hub-domain-security-005 revoke percent-encodes the id, sends DELETE and resolves undefined", async () => {
    reply({ status: 204 });
    await expect(tokensApi.revoke("tok 1")).resolves.toBeUndefined();
    expect(url()).toBe("/api/v1/api_keys/tok%201");
    expect(init().method).toBe("DELETE");
  });

  it("hub-domain-security-006 listing all groups unwraps the list envelope and maps rows", async () => {
    reply({ body: list([groupWire]) });
    const rows = await bucketAccessApi.listAllGroups();
    expect(new URL(url(), "http://x").pathname).toBe("/api/v1/bucket_access_groups");
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ id: "g1", bucketId: "b1", name: "Editors" });
  });

  it("hub-domain-security-007 group detail reads the group route and includes members and grants", async () => {
    reply({ body: { ...groupWire, members: [memberWire], grants: [grantWire] } });
    const out = await bucketAccessApi.getGroup("g1");
    expect(url()).toBe("/api/v1/bucket_access_groups/g1");
    expect(out.members).toHaveLength(1);
    expect(out.members[0]).toMatchObject({ id: "row-1", memberType: "persona", memberId: "p1" });
    expect(out.grants[0]).toMatchObject({ id: "grant-1", targetType: "bucket_type", crud: "C,R" });
  });

  it("hub-domain-security-008 create posts the trimmed name with the bucket in the body", async () => {
    reply({ status: 201, body: groupWire });
    await bucketAccessApi.createGroup("b1", { name: "  Editors  " });
    expect(url()).toBe("/api/v1/bucket_access_groups");
    expect(init().method).toBe("POST");
    const body = JSON.parse(String(init().body));
    expect(body).toEqual({ name: "Editors", bucket: "b1" });
    expect("description" in body).toBe(false);
  });

  it("hub-domain-security-009 create maps an already-exists conflict to the named friendly error", async () => {
    reply({ status: 409, body: errBody("Access group with that name already exists") });
    await expect(bucketAccessApi.createGroup("b1", { name: "Editors" })).rejects.toThrow(
      'An access list named "Editors" already exists.',
    );
  });

  it("hub-domain-security-010 update posts only the supplied fields", async () => {
    reply({ body: groupWire });
    await bucketAccessApi.updateGroup("g1", { description: "new" });
    expect(url()).toBe("/api/v1/bucket_access_groups/g1");
    expect(init().method).toBe("POST");
    expect(JSON.parse(String(init().body))).toEqual({ description: "new" });
  });

  it("hub-domain-security-011 update with no name maps a conflict to an empty-name message", async () => {
    reply({ status: 409, body: errBody("already exists") });
    await expect(bucketAccessApi.updateGroup("g1", {})).rejects.toThrow('An access list named "" already exists.');
  });

  it("hub-domain-security-012 delete propagates the backend 409 message unmodified", async () => {
    reply({ status: 409, body: { error: "cannot delete the everyone group" } });
    await expect(bucketAccessApi.deleteGroup("everyone-group-id")).rejects.toMatchObject({
      status: 409,
      message: "cannot delete the everyone group",
    });
    expect(init().method).toBe("DELETE");
    expect(url()).toBe("/api/v1/bucket_access_groups/everyone-group-id");
  });

  it("hub-domain-security-013 adding a member posts the snake_case member fields", async () => {
    reply({ status: 201, body: memberWire });
    await bucketAccessApi.addMember("g1", { memberType: "persona", memberId: "p1" });
    expect(url()).toBe("/api/v1/bucket_access_groups/g1/members");
    expect(init().method).toBe("POST");
    expect(JSON.parse(String(init().body))).toEqual({ member_type: "persona", member_id: "p1" });
  });

  it("hub-domain-security-014 adding a duplicate member maps the conflict to the friendly message", async () => {
    reply({ status: 409, body: errBody("member already exists") });
    await expect(bucketAccessApi.addMember("g1", { memberType: "user", memberId: "u1" })).rejects.toThrow(
      "That member is already in this access list.",
    );
  });

  it("hub-domain-security-015 removing a member deletes by membership row id", async () => {
    reply({ status: 204 });
    await expect(bucketAccessApi.removeMember("g1", "row-42")).resolves.toBeUndefined();
    expect(url()).toBe("/api/v1/bucket_access_groups/g1/members/row-42");
    expect(init().method).toBe("DELETE");
  });

  it("hub-domain-security-016 upserting a grant posts the snake_case body and resolves the mapped grant", async () => {
    reply({ body: grantWire });
    const out = await bucketAccessApi.upsertGrant("g1", { targetType: "bucket_type", targetId: "bt1", crud: "C,R" });
    expect(url()).toBe("/api/v1/bucket_access_groups/g1/grants");
    expect(init().method).toBe("POST");
    expect(JSON.parse(String(init().body))).toEqual({ target_type: "bucket_type", target_id: "bt1", crud: "C,R" });
    expect(out).toMatchObject({ id: "grant-1", targetType: "bucket_type", targetId: "bt1", crud: "C,R" });
  });

  it("hub-domain-security-017 a grant upsert 404 propagates with its status", async () => {
    reply({ status: 404, body: errBody("target not found") });
    await expect(
      bucketAccessApi.upsertGrant("g1", { targetType: "bucket_type", targetId: "missing", crud: "R" }),
    ).rejects.toMatchObject({ status: 404 });
  });

  it("hub-domain-security-018 deleting a grant sends DELETE to the grant route", async () => {
    reply({ status: 204 });
    await expect(bucketAccessApi.deleteGrant("g1", "grant-1")).resolves.toBeUndefined();
    expect(url()).toBe("/api/v1/bucket_access_groups/g1/grants/grant-1");
    expect(init().method).toBe("DELETE");
  });

  it("hub-domain-security-019 an empty crud string is sent unchanged", async () => {
    reply({ body: { ...grantWire, crud: "" } });
    await bucketAccessApi.upsertGrant("g1", { targetType: "row", targetId: "r1", crud: "" });
    expect(JSON.parse(String(init().body)).crud).toBe("");
  });

  it("hub-domain-security-020 a group id with unsafe characters is percent-encoded in the URL", async () => {
    reply({ body: { ...groupWire, members: [], grants: [] } });
    await bucketAccessApi.getGroup("a b/c");
    expect(url()).toContain("a%20b%2Fc");
    expect(url()).not.toContain("a b/c");
  });

  it("hub-domain-security-021 token revoke and group delete encode the same segment", async () => {
    reply({ status: 204 });
    await tokensApi.revoke("a/b");
    await bucketAccessApi.deleteGroup("a/b");
    expect(url(0).split("/").pop()).toBe("a%2Fb");
    expect(url(1).split("/").pop()).toBe("a%2Fb");
  });

  it("hub-domain-security-022 a 401 is retried once with the refreshed token and a second 401 throws", async () => {
    reply({ status: 401, body: errBody("expired") }, { body: { token: "tok-2" } }, { body: list([]) });
    await expect(tokensApi.list()).resolves.toEqual([]);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect((init(2).headers as Record<string, string>).Authorization).toBe("Bearer tok-2");

    localStorage.setItem("auth_tokens", JSON.stringify({ accessToken: "tok-3", refreshToken: "" }));
    reply({ status: 401, body: errBody("expired") }, { body: { token: "tok-4" } }, { status: 401, body: errBody("still") });
    await expect(tokensApi.list()).rejects.toMatchObject({ status: 401 });
  });

  it("hub-domain-security-023 a 403 from a grant upsert carries status and code", async () => {
    reply({ status: 403, body: errBody("forbidden", "no_manage_verb") });
    await expect(
      bucketAccessApi.upsertGrant("g1", { targetType: "bucket", targetId: "b1", crud: "R" } as never),
    ).rejects.toMatchObject({ status: 403, code: "no_manage_verb" });
  });

  it("hub-domain-security-024 two token list calls issue two requests with no cache", async () => {
    await tokensApi.list();
    await tokensApi.list();
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});
