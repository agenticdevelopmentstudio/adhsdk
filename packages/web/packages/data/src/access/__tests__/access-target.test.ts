import { describe, expect, it, vi, beforeEach } from "vitest";
import { accessApi, accessTargetKey, accessTargetQuery } from "../access";

// Phase 5: every access call names exactly one target, `?workspace=<slug>` or
// `?ecosystem=<id>` (the backend 400s both, and neither). A bare string stays a workspace slug.

const fetchMock = vi.fn();
const list = (data: unknown[]) => ({
  object: "list",
  data,
  has_more: false,
  url: "",
});
beforeEach(() => {
  fetchMock.mockReset();
  fetchMock.mockImplementation(async () => {
    const body = list([]);
    return {
      ok: true,
      status: 200,
      json: async () => body,
      text: async () => JSON.stringify(body),
    };
  });
  vi.stubGlobal("fetch", fetchMock);
});

const params = (i = 0) =>
  new URL(String(fetchMock.mock.calls[i]![0]), "http://x").searchParams;

const ECO = { ecosystem: "eco-1" } as const;
const WS = { workspace: "acme" } as const;

// The request is what is under test; a body the empty stub cannot map is beside the point.
const calls: Array<[string, (t: typeof ECO | typeof WS) => Promise<unknown>]> =
  [
    ["listFeatures", (t) => accessApi.listFeatures(t).catch(() => undefined)],
    ["listRoles", (t) => accessApi.listRoles(t)],
    [
      "createRole",
      (t) =>
        accessApi
          .createRole(t, { slug: "r", name: "R", grants: [] })
          .catch(() => undefined),
    ],
    [
      "updateRole",
      (t) =>
        accessApi.updateRole(t, "role-1", { name: "R" }).catch(() => undefined),
    ],
    ["deleteRole", (t) => accessApi.deleteRole(t, "role-1")],
    [
      "listAssignments",
      (t) => accessApi.listAssignments(t).catch(() => undefined),
    ],
    [
      "putAssignment",
      (t) =>
        accessApi
          .putAssignment(t, {
            subjectKind: "customer",
            subjectId: "c",
            roleId: "r",
          })
          .catch(() => undefined),
    ],
    ["deleteAssignment", (t) => accessApi.deleteAssignment(t, "a-1")],
    ["listSubjects", (t) => accessApi.listSubjects(t)],
  ];

describe("access target", () => {
  for (const [name, call] of calls) {
    it(`${name} sends ?ecosystem= for an ecosystem target, never ?workspace=`, async () => {
      await call(ECO);
      expect(params().get("ecosystem")).toBe("eco-1");
      expect(params().has("workspace")).toBe(false);
    });

    it(`${name} sends ?workspace= for a workspace target, never ?ecosystem=`, async () => {
      await call(WS);
      expect(params().get("workspace")).toBe("acme");
      expect(params().has("ecosystem")).toBe(false);
    });
  }

  it("a bare string is a workspace slug", async () => {
    await accessApi.listRoles("acme");
    expect(params().get("workspace")).toBe("acme");
    expect(params().has("ecosystem")).toBe(false);
    expect(accessTargetQuery("acme")).toEqual({ workspace: "acme" });
  });

  it("keys a workspace target as before and an ecosystem target apart", () => {
    expect(accessTargetKey("acme")).toBe("workspace:acme");
    expect(accessTargetKey(WS)).toBe("workspace:acme");
    expect(accessTargetKey(ECO)).toBe("ecosystem:eco-1");
  });

  it("listSubjects reads the realm's product users and passes the search", async () => {
    const body = list([
      {
        kind: "customer",
        id: "c1",
        label: "Ada",
        email: "ada@example.test",
        slug: "ada",
      },
    ]);
    fetchMock.mockImplementation(async () => ({
      ok: true,
      status: 200,
      json: async () => body,
      text: async () => JSON.stringify(body),
    }));
    const rows = await accessApi.listSubjects(ECO, { q: "ad" });
    expect(String(fetchMock.mock.calls[0]![0])).toContain(
      "/api/v1/access/subjects",
    );
    expect(params().get("q")).toBe("ad");
    expect(rows).toEqual([
      {
        kind: "customer",
        id: "c1",
        label: "Ada",
        email: "ada@example.test",
        slug: "ada",
      },
    ]);
  });
});
