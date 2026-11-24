import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { ORGANIZATIONS_QUERY_KEY, organizationsApi } from "../organizations";
import { workspaceMembersApi } from "../members";
import { WORKSPACES_QUERY_KEY } from "../../workspaces";

// Conformance vectors for the organizations + roster clients
// (cookbook/adh/hub/organizations/conformance-test-vectors.md). Every vector id leads its test title.

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
const org = { id: "org-1", slug: "acme", name: "Acme" };
const errBody = (message: string, code?: string) => ({ error: { message, ...(code ? { code } : {}) } });

beforeEach(() => {
  localStorage.clear();
  localStorage.setItem("auth_tokens", JSON.stringify({ accessToken: "tok-1", refreshToken: "" }));
  vi.stubGlobal("fetch", fetchMock);
  reply({ body: list([]) });
});

describe("organizations conformance vectors", () => {
  it("hub-domain-organizations-001 rdid is absent on a read shape and present on a create shape", async () => {
    reply({ body: org });
    const read = await organizationsApi.resolve("org-1");
    expect("rdid" in read).toBe(false);
    reply({
      status: 201,
      body: {
        organization: { ...org, rdid: "org.acme" },
        namespace: { id: "ns", owner_kind: "customer", owner_id: "c1", slug: null, name: null, rdid: null },
        team_id: "t1",
        ecosystem: { id: "e1", slug: "acme", rdid: "org.acme.e" },
      },
    });
    const created = await organizationsApi.create({ slug: "acme", name: "Acme" }, "personal");
    expect(created.organization.rdid).toBe("org.acme");
  });

  it("hub-domain-organizations-002 a list row carries only id, slug, name and description", async () => {
    reply({ body: list([{ ...org, description: "d", owner_kind: "customer", owner_id: "c1" }]) });
    const rows = await organizationsApi.list("acme");
    expect(rows).toEqual([{ id: "org-1", slug: "acme", name: "Acme", description: "d" }]);
    expect(Object.keys(rows[0]!)).not.toContain("ownerKind");
    expect(Object.keys(rows[0]!)).not.toContain("ownerId");
  });

  it("hub-domain-organizations-003 a create input of only slug and name is sent as exactly those two fields", async () => {
    reply({ status: 201, body: { organization: org, namespace: { id: "n", owner_kind: "customer", owner_id: "c", slug: null, name: null, rdid: null }, team_id: "t", ecosystem: { id: "e", slug: "s", rdid: "r" } } });
    await organizationsApi.create({ slug: "acme", name: "Acme" }, "personal");
    expect(JSON.parse(String(init().body))).toEqual({ slug: "acme", name: "Acme" });
  });

  it("hub-domain-organizations-004 a rename input with only slug is accepted and sent as only slug", async () => {
    reply({ body: org });
    await organizationsApi.rename("org-1", { slug: "acme2" });
    expect(JSON.parse(String(init().body))).toEqual({ slug: "acme2" });
  });

  it("hub-domain-organizations-005 create posts to the workspace-scoped route and maps the 201 body", async () => {
    reply({
      status: 201,
      body: {
        organization: { ...org, rdid: "org.acme" },
        namespace: { id: "ns1", owner_kind: "customer", owner_id: "c1", slug: "acme", name: "Acme", rdid: "org.acme" },
        team_id: "team-1",
        ecosystem: { id: "e1", slug: "acme", rdid: "org.acme.e" },
      },
    });
    const out = await organizationsApi.create({ slug: "acme", name: "Acme" }, "personal");
    expect(url()).toBe("/api/v1/organizations?workspace=personal");
    expect(init().method).toBe("POST");
    expect(init().body).toBe('{"slug":"acme","name":"Acme"}');
    expect(out).toEqual({
      organization: { ...org, rdid: "org.acme" },
      namespace: { id: "ns1", ownerKind: "customer", ownerId: "c1", slug: "acme", name: "Acme", rdid: "org.acme" },
      teamId: "team-1",
      ecosystem: { id: "e1", slug: "acme", rdid: "org.acme.e" },
    });
  });

  it("hub-domain-organizations-006 restore posts to the restore route and resolves the organization body", async () => {
    reply({ body: org });
    await expect(organizationsApi.restore("org-1")).resolves.toEqual(org);
    expect(url()).toBe("/api/v1/organizations/org-1/restore");
    expect(init().method).toBe("POST");
  });

  it("hub-domain-organizations-008 a null email and displayName stay null", async () => {
    reply({ body: list([{ user_id: "u1", email: null, display_name: null, is_admin: false, added_at: "2026-01-01" }]) });
    const { members } = await workspaceMembersApi.list("acme");
    expect(members[0]!.email).toBeNull();
    expect(members[0]!.displayName).toBeNull();
  });

  it("hub-domain-organizations-009 the roster row carries the wire is_admin flag as isAdmin", async () => {
    reply({ body: list([{ user_id: "u1", email: "a@b.com", display_name: "A", is_admin: true, added_at: "2026-01-01" }]) });
    const { members } = await workspaceMembersApi.list("acme");
    expect(members[0]!.isAdmin).toBe(true);
  });

  it("hub-domain-organizations-010 the roster row carries the wire added_at as addedAt unchanged", async () => {
    reply({ body: list([{ user_id: "u1", email: "a@b.com", display_name: "A", is_admin: false, added_at: "2026-01-01" }]) });
    const { members } = await workspaceMembersApi.list("acme");
    expect(members[0]!.addedAt).toBe("2026-01-01");
  });

  it("hub-domain-organizations-011 list is scoped to the workspace query and maps rows to an array", async () => {
    reply({ body: list([org]) });
    const rows = await organizationsApi.list("acme");
    expect(new URL(url(), "http://x").pathname).toBe("/api/v1/organizations");
    expect(new URL(url(), "http://x").searchParams.get("workspace")).toBe("acme");
    expect(rows).toEqual([org]);
  });

  it("hub-domain-organizations-012 the workspace slug is encoded in the list query and the roster path", async () => {
    await organizationsApi.list("a b/c");
    expect(url()).not.toContain("a b/c");
    expect(new URL(url(), "http://x").searchParams.get("workspace")).toBe("a b/c");
    reply({ body: list([]) });
    await workspaceMembersApi.list("a b/c");
    expect(url()).toContain("/api/v1/workspaces/a%20b%2Fc/members");
  });

  it.skip("hub-domain-organizations-013 list semantics per workspace kind are server-side; the client has nothing to assert", () => {});

  it("hub-domain-organizations-014 resolve passes a rdid, a UUID and a slug through unmodified", async () => {
    for (const key of ["org.acme", "11111111-1111-1111-1111-111111111111", "acme"]) {
      reply({ body: org });
      await organizationsApi.resolve(key);
      expect(url()).toBe(`/api/v1/organizations/${key}`);
      expect(init().method).toBeUndefined();
    }
  });

  it("hub-domain-organizations-015 resolve rejects with the plain 404 HTTP error", async () => {
    reply({ status: 404, body: errBody("not found") });
    await expect(organizationsApi.resolve("missing")).rejects.toMatchObject({ status: 404, message: "not found" });
  });

  it("hub-domain-organizations-016 create maps an already-exists 409 to the friendly message", async () => {
    reply({ status: 409, body: errBody("organization already exists") });
    await expect(organizationsApi.create({ slug: "acme", name: "Acme" }, "personal")).rejects.toThrow(
      "An organization with that slug already exists.",
    );
  });

  it("hub-domain-organizations-017 rename posts only the defined fields", async () => {
    reply({ body: org });
    await organizationsApi.rename("org-1", { slug: "acme2", description: undefined });
    expect(url()).toBe("/api/v1/organizations/org-1");
    expect(init().method).toBe("POST");
    expect(init().body).toBe('{"slug":"acme2"}');
  });

  it("hub-domain-organizations-018 rename maps an already-exists 409 to the friendly message", async () => {
    reply({ status: 409, body: errBody("slug already exists") });
    await expect(organizationsApi.rename("org-1", { slug: "x" })).rejects.toThrow(
      "That organization slug is already taken.",
    );
  });

  it("hub-domain-organizations-019 archive sends DELETE and resolves to nothing on a 204", async () => {
    reply({ status: 204 });
    await expect(organizationsApi.archive("org-1")).resolves.toBeUndefined();
    expect(url()).toBe("/api/v1/organizations/org-1");
    expect(init().method).toBe("DELETE");
  });

  it("hub-domain-organizations-020 restore maps any 409 to the handle-taken message by status", async () => {
    reply({ status: 409, body: errBody("that organization handle has been taken") });
    await expect(organizationsApi.restore("org-1")).rejects.toThrow(
      "That organization's handle has been taken, so it can't be restored.",
    );
  });

  it("hub-domain-organizations-021 the organizations cache key is a one-element prefix distinct from the workspaces key", () => {
    expect(ORGANIZATIONS_QUERY_KEY).toEqual(["organizations"]);
    expect(ORGANIZATIONS_QUERY_KEY).not.toEqual(WORKSPACES_QUERY_KEY);
  });

  it("hub-domain-organizations-022 the roster list reads the members route and wraps rows in a members envelope", async () => {
    reply({ body: list([{ user_id: "u1", email: "a@b.com", display_name: "A", is_admin: true, added_at: "2026-01-01" }]) });
    const out = await workspaceMembersApi.list("acme");
    expect(new URL(url(), "http://x").pathname).toBe("/api/v1/workspaces/acme/members");
    expect(init().method).toBeUndefined();
    expect(out).toEqual({
      members: [{ userId: "u1", email: "a@b.com", displayName: "A", isAdmin: true, addedAt: "2026-01-01" }],
    });
  });

  it.skip("hub-domain-organizations-023 distinct-customer rows are a backend guarantee; the client does not dedupe", () => {});

  it("hub-domain-organizations-024 the roster rejects a 404 with a plain HTTP error for either cause", async () => {
    reply({ status: 404, body: errBody("not found") });
    await expect(workspaceMembersApi.list("nobody")).rejects.toMatchObject({ status: 404 });
    reply({ status: 404, body: errBody("not found") });
    await expect(workspaceMembersApi.list("not-mine")).rejects.toMatchObject({ status: 404 });
  });

  it("hub-domain-organizations-025 a 401 is retried once with the refreshed token and a second 401 throws", async () => {
    reply({ status: 401, body: errBody("expired") }, { body: { token: "tok-2" } }, { body: org });
    await expect(organizationsApi.resolve("org-1")).resolves.toEqual(org);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect((init(0).headers as Record<string, string>).Authorization).toBe("Bearer tok-1");
    expect((init(2).headers as Record<string, string>).Authorization).toBe("Bearer tok-2");

    localStorage.setItem("auth_tokens", JSON.stringify({ accessToken: "tok-3", refreshToken: "" }));
    reply({ status: 401, body: errBody("expired") }, { body: { token: "tok-4" } }, { status: 401, body: errBody("still expired") });
    await expect(organizationsApi.resolve("org-1")).rejects.toMatchObject({ status: 401 });
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it("hub-domain-organizations-026 a 403 from create or rename rejects with the status and no client-side role check", async () => {
    reply({ status: 403, body: errBody("forbidden") });
    await expect(organizationsApi.create({ slug: "a", name: "A" }, "acme")).rejects.toMatchObject({ status: 403 });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    reply({ status: 403, body: errBody("forbidden") });
    await expect(organizationsApi.rename("org-1", { slug: "b" })).rejects.toMatchObject({ status: 403 });
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("hub-domain-organizations-027 two list calls issue two requests with no cache", async () => {
    await organizationsApi.list("acme");
    await organizationsApi.list("acme");
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("hub-domain-organizations-028 every operation sends the shared client's bearer token and the source never sets Authorization", async () => {
    const ops: Array<() => Promise<unknown>> = [
      () => organizationsApi.list("acme"),
      () => organizationsApi.resolve("org-1"),
      () => organizationsApi.rename("org-1", { name: "x" }),
      () => organizationsApi.restore("org-1"),
      () => workspaceMembersApi.list("acme"),
    ];
    for (const op of ops) {
      reply({ body: { ...org, object: "list", data: [], has_more: false } });
      await op();
      expect((init().headers as Record<string, string>).Authorization).toBe("Bearer tok-1");
    }
    for (const f of ["organizations.ts", "members.ts"]) {
      expect(readFileSync(resolve(__dirname, "..", f), "utf8")).not.toMatch(/Authorization/);
    }
  });

  it("hub-domain-organizations-029 a 403 from archive carries status and code", async () => {
    reply({ status: 403, body: errBody("forbidden", "not_site_admin") });
    await expect(organizationsApi.archive("org-1")).rejects.toMatchObject({ status: 403, code: "not_site_admin" });
  });
});
