import { describe, expect, it, vi, beforeEach } from "vitest";
import { accessApi, ACCESS_FEATURES } from "../access";

// `accessApi.listFeatures` is otherwise NEVER exercised: every consumer test mocks
// `@adh-sdk/data/access` wholesale (see TeamPermissionsPane.test.tsx), so neither the
// request it builds nor its response unwrap has ever run for real. That matters more than usual
// here — TeamPermissionsPane treats ANY thrown error as "this backend predates the endpoint" and
// silently degrades to the two-area fallback, so a wrong URL or a wrong response key would not
// surface as a crash or a wrong answer; it would just look exactly like an old backend.
//
// Every test title that starts `hub-domain-access-NNN` covers that conformance vector.

const fetchMock = vi.fn();
beforeEach(() => {
  fetchMock.mockReset();
  fetchMock.mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => ({ object: "list", data: [], has_more: false, url: "" }),
    text: async () => '{"object":"list","data":[],"has_more":false,"url":""}',
  });
  vi.stubGlobal("fetch", fetchMock);
});

const urlOf = () => String(fetchMock.mock.calls[0]![0]);

/** A /v1 list envelope around `data`. */
const list = (data: unknown[]) => ({ object: "list", data, has_more: false, url: "" });

/** Re-point the shared `fetch` stub at one specific JSON body. */
const respondWith = (body: unknown) =>
  fetchMock.mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => body,
    text: async () => JSON.stringify(body),
  });

describe("accessApi.listFeatures", () => {
  it("hub-domain-access-001 GETs the workspace-scoped features route", async () => {
    await accessApi.listFeatures("acme");
    expect(urlOf()).toContain("/api/v1/access/features");
    expect(urlOf()).toContain("workspace=acme");
  });

  it("hub-domain-access-002 encodes a workspace slug that needs escaping", async () => {
    await accessApi.listFeatures("a b/c");
    expect(new URL(urlOf(), "http://x").searchParams.get("workspace")).toBe("a b/c");
  });

  it("hub-domain-access-003 unwraps the list envelope to the bare array", async () => {
    respondWith(list([{ key: "projects", label: "Projects" }]));
    await expect(accessApi.listFeatures("acme")).resolves.toEqual([
      { key: "projects", label: "Projects" },
    ]);
  });

  it("hub-domain-access-004 preserves registration order across multiple rows", async () => {
    const rows = [
      { key: "projects", label: "Projects" },
      { key: "personas", label: "Personas" },
      { key: "audiences", label: "Audiences" },
    ];
    respondWith(list(rows));
    await expect(accessApi.listFeatures("acme")).resolves.toEqual(rows);
  });

  it("resolves an EMPTY list to an empty array (a valid, if unreadable, shape)", async () => {
    respondWith(list([]));
    await expect(accessApi.listFeatures("acme")).resolves.toEqual([]);
  });

  // The shape guard: every element must be an object with a string `key` and a string `label`
  // (the exact fields AccessFeatureRow declares in wire.ts). These are the two malformed-but-
  // plausible shapes review found reaching the caller as usable values via the old bare cast —
  // a crash (`.map` on a string) and a silently-broken editor (`feature: undefined` rows) — so
  // each of these MUST reject, not resolve, for the caller's existing catch/fallback to apply.
  it("hub-domain-access-005 rejects when `data` is a string, not an array", async () => {
    respondWith({ data: "abc" });
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects when `data` is an array of bare strings (no `label`)", async () => {
    respondWith(list(["projects", "personas"]));
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects when `data` is an object rather than an array", async () => {
    respondWith({ data: { projects: "Projects" } });
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("hub-domain-access-007 rejects when the `data` key is absent entirely", async () => {
    respondWith({});
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects when a row is missing `label`", async () => {
    respondWith(list([{ key: "projects" }]));
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects when a row's `key` is the wrong type", async () => {
    respondWith(list([{ key: 1, label: "Projects" }]));
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  // `""` is a string, so a `typeof` test alone accepts these — and a NON-empty array carrying one
  // clears the caller's `rows.length > 0` check too, which is the only other line of defence. Then
  // the empty value is live: the key is what a grant is submitted under, and the label is the sole
  // identifier of the column an admin ticks. Rejecting is the only place either can be caught.
  it("hub-domain-access-006 rejects a row whose `key` is the empty string", async () => {
    respondWith(list([{ key: "", label: "Projects" }]));
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects a row whose `label` is the empty string", async () => {
    respondWith(list([{ key: "projects", label: "" }]));
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects the whole list when ONE row among good ones is empty", async () => {
    respondWith(
      list([
        { key: "projects", label: "Projects" },
        { key: "", label: "" },
      ]),
    );
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });

  it("rejects a null row (a `typeof v === 'object'` near-miss)", async () => {
    respondWith(list([null]));
    await expect(accessApi.listFeatures("acme")).rejects.toThrow();
  });
});

// ---- The rest of accessApi: one test per remaining conformance vector -------------------

/** The method and parsed URL of the Nth fetch call. */
const callOf = (n = 0) => {
  const [url, init] = fetchMock.mock.calls[n]! as [string, RequestInit | undefined];
  const u = new URL(String(url), "http://x");
  return { method: init?.method ?? "GET", path: u.pathname, q: u.searchParams, body: init?.body };
};

const okJson = (body: unknown, status = 200) => ({
  ok: true,
  status,
  json: async () => body,
  text: async () => JSON.stringify(body),
});

const roleWire = {
  id: "r1",
  slug: "editor",
  name: "Editor",
  description: "",
  is_system: false,
  default_for: "",
  grants: [{ feature: "projects", item_verbs: "R", subitem_verbs: "R" }],
};
const roleRow = {
  id: "r1",
  slug: "editor",
  name: "Editor",
  description: "",
  isSystem: false,
  defaultFor: "",
  grants: [{ feature: "projects", itemVerbs: "R", subitemVerbs: "R" }],
};
const assignmentWire = {
  id: "a1",
  subject_kind: "customer",
  subject_id: "c1",
  scope_feature: "",
  scope_item_id: "",
  role_id: "r1",
};
const assignmentRow = {
  id: "a1",
  subjectKind: "customer",
  subjectId: "c1",
  scopeFeature: "",
  scopeItemId: "",
  roleId: "r1",
};

describe("accessApi conformance vectors (fallback, roles, assignments, items, effective, errors)", () => {
  it("hub-domain-access-008 the fallback feature list is the fixed two-entry set", () => {
    expect(ACCESS_FEATURES).toEqual([
      { key: "projects", label: "Projects" },
      { key: "personas", label: "Personas" },
    ]);
  });

  it("hub-domain-access-009 a malformed features response rejects; the fallback list is not substituted", async () => {
    respondWith(list([{ key: "", label: "x" }]));
    const err = await accessApi.listFeatures("acme").then(
      () => null,
      (e: Error) => e,
    );
    expect(err).toBeInstanceOf(Error);
    expect(err!.message).toBe("GET /v1/access/features returned a malformed feature list");
  });

  it("hub-domain-access-010 listRoles pages through /v1 and maps rows to camelCase", async () => {
    respondWith(list([roleWire]));
    await expect(accessApi.listRoles("acme")).resolves.toEqual([roleRow]);
    const c = callOf();
    expect(c.method).toBe("GET");
    expect(c.path).toBe("/api/v1/access/roles");
    expect(c.q.get("workspace")).toBe("acme");
    expect(c.q.get("limit")).toBe("100");
  });

  it("hub-domain-access-011 createRole POSTs the snake_case role body and maps the created role", async () => {
    respondWith(roleWire);
    const created = await accessApi.createRole("acme", { slug: "editor", name: "Editor", grants: [] });
    expect(created).toEqual(roleRow);
    const c = callOf();
    expect(c.method).toBe("POST");
    expect(c.path).toBe("/api/v1/access/roles");
    expect(c.q.get("workspace")).toBe("acme");
    expect(JSON.parse(c.body as string)).toEqual({ slug: "editor", name: "Editor", grants: [] });
  });

  it("hub-domain-access-012 updateRole never sends a slug, even if one is smuggled into the patch", async () => {
    respondWith(roleWire);
    await accessApi.updateRole("acme", "r1", { name: "Renamed", slug: "hacked" } as never);
    const c = callOf();
    expect(c.method).toBe("POST");
    expect(c.path).toBe("/api/v1/access/roles/r1");
    expect(c.q.get("workspace")).toBe("acme");
    expect(JSON.parse(c.body as string)).toEqual({ name: "Renamed" });
  });

  it("hub-domain-access-013 deleteRole DELETEs the role and resolves with no value", async () => {
    respondWith({ ignored: true });
    await expect(accessApi.deleteRole("acme", "role-1")).resolves.toBeUndefined();
    const c = callOf();
    expect(c.method).toBe("DELETE");
    expect(c.path).toBe("/api/v1/access/roles/role-1");
    expect(c.q.get("workspace")).toBe("acme");
  });

  it("hub-domain-access-014 listAssignments with no scope sends only the workspace", async () => {
    respondWith({ assignments: [assignmentWire] });
    const out = await accessApi.listAssignments("acme");
    expect(out).toEqual({ assignments: [assignmentRow] });
    const c = callOf();
    expect(c.method).toBe("GET");
    expect(c.path).toBe("/api/v1/access/role_assignments");
    expect(c.q.get("workspace")).toBe("acme");
    expect(c.q.has("feature")).toBe(false);
    expect(c.q.has("item_id")).toBe(false);
  });

  it("hub-domain-access-015 listAssignments with a scope adds feature and item_id, and passes `restricted` through", async () => {
    respondWith({ assignments: [], restricted: true });
    const out = await accessApi.listAssignments("acme", { feature: "projects", itemId: "p1" });
    expect(out).toEqual({ assignments: [], restricted: true });
    const c = callOf();
    expect(c.q.get("feature")).toBe("projects");
    expect(c.q.get("item_id")).toBe("p1");
  });

  it("hub-domain-access-016 putAssignment POSTs the snake_case assignment body and maps the result", async () => {
    respondWith(assignmentWire);
    const out = await accessApi.putAssignment("acme", {
      subjectKind: "customer",
      subjectId: "c1",
      roleId: "r1",
    });
    expect(out).toEqual(assignmentRow);
    const c = callOf();
    expect(c.method).toBe("POST");
    expect(c.path).toBe("/api/v1/access/role_assignments");
    expect(c.q.get("workspace")).toBe("acme");
    expect(JSON.parse(c.body as string)).toEqual({
      subject_kind: "customer",
      subject_id: "c1",
      role_id: "r1",
    });
  });

  it("hub-domain-access-017 deleteAssignment DELETEs the assignment and resolves with no value", async () => {
    await expect(accessApi.deleteAssignment("acme", "a1")).resolves.toBeUndefined();
    const c = callOf();
    expect(c.method).toBe("DELETE");
    expect(c.path).toBe("/api/v1/access/role_assignments/a1");
    expect(c.q.get("workspace")).toBe("acme");
  });

  it("hub-domain-access-018 restrictItem POSTs feature and item_id to the restrict route", async () => {
    respondWith({});
    await expect(accessApi.restrictItem("acme", "projects", "p1")).resolves.toBeUndefined();
    const c = callOf();
    expect(c.method).toBe("POST");
    expect(c.path).toBe("/api/v1/access/items/restrict");
    expect(c.q.get("workspace")).toBe("acme");
    expect(JSON.parse(c.body as string)).toEqual({ feature: "projects", item_id: "p1" });
  });

  it("hub-domain-access-019 restrictItem and restoreItem throw on a 204 because they parse a JSON body", async () => {
    fetchMock.mockResolvedValue({ ok: true, status: 204, json: async () => ({}), text: async () => "" });
    const msg = "Unexpected empty response (204 No Content); use authedRequest for endpoints with no body";
    await expect(accessApi.restrictItem("acme", "projects", "p1")).rejects.toThrow(msg);
    await expect(accessApi.restoreItem("acme", "projects", "p1")).rejects.toThrow(msg);
  });

  const effectiveWire = {
    item_verbs: "R",
    subitem_verbs: "R",
    restricted: false,
    decided_by: { R: { kind: "owner" } },
  };

  it("hub-domain-access-020 effective omits item_id when no item is given", async () => {
    respondWith(effectiveWire);
    const out = await accessApi.effective("acme", {
      feature: "projects",
      subjectKind: "customer",
      subjectId: "c1",
    });
    expect(out).toEqual({
      itemVerbs: "R",
      subitemVerbs: "R",
      restricted: false,
      decidedBy: { R: { kind: "owner" } },
    });
    const c = callOf();
    expect(c.path).toBe("/api/v1/access/effective_permissions");
    expect(c.q.get("workspace")).toBe("acme");
    expect(c.q.get("feature")).toBe("projects");
    expect(c.q.get("subject_kind")).toBe("customer");
    expect(c.q.get("subject_id")).toBe("c1");
    expect(c.q.has("item_id")).toBe(false);
  });

  it("hub-domain-access-021 effective adds item_id when an item is given", async () => {
    respondWith(effectiveWire);
    await accessApi.effective("acme", {
      feature: "projects",
      subjectKind: "customer",
      subjectId: "c1",
      itemId: "p1",
    });
    expect(callOf().q.get("item_id")).toBe("p1");
  });

  it("hub-domain-access-022 a 401 refreshes once and retries with the new token; a second 401 throws status 401", async () => {
    const errBody = { error: { message: "expired" } };
    fetchMock
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => errBody })
      .mockResolvedValueOnce(okJson({ token: "fresh-token" })) // the refresh call
      .mockResolvedValueOnce(okJson(list([{ key: "projects", label: "Projects" }])));
    await expect(accessApi.listFeatures("acme")).resolves.toEqual([{ key: "projects", label: "Projects" }]);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(callOf(1).path).toBe("/api/v1/auth/sessions/refresh");
    const retryInit = fetchMock.mock.calls[2]![1] as RequestInit;
    expect((retryInit.headers as Record<string, string>).Authorization).toBe("Bearer fresh-token");

    fetchMock.mockReset();
    fetchMock
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => errBody })
      .mockResolvedValueOnce(okJson({ token: "fresher-token" }))
      .mockResolvedValueOnce({ ok: false, status: 401, json: async () => errBody });
    await expect(accessApi.listFeatures("acme")).rejects.toMatchObject({ status: 401 });
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it("hub-domain-access-023 a 403 error carries its status and machine code", async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 403,
      json: async () => ({ error: { message: "forbidden", code: "no_manage_verb" } }),
    });
    await expect(accessApi.listRoles("acme")).rejects.toMatchObject({
      status: 403,
      code: "no_manage_verb",
      message: "forbidden",
    });
  });

  it("hub-domain-access-024 a 404 for a non-member rejects with status 404; the client sends one request per call", async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 404,
      json: async () => ({ error: { message: "not found" } }),
    });
    await expect(accessApi.listRoles("acme")).rejects.toMatchObject({ status: 404 });
    await expect(accessApi.listAssignments("acme")).rejects.toMatchObject({ status: 404 });
    await expect(
      accessApi.effective("acme", { feature: "projects", subjectKind: "customer", subjectId: "c1" }),
    ).rejects.toMatchObject({ status: 404 });
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });
});
