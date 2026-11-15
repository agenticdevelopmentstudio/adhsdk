// Conformance vectors for the monitored-sites client (cookbook adh/hub/monitored-sites).
// Only `fetch` is stubbed: the real `authedJson` / `authedRequest` / `listAllV1`, the
// 401 refresh waterfall and the wire <-> view mappers all run.
import { beforeEach, describe, expect, it } from "vitest";

import {
  toGroup,
  toSite,
  toEndpoint,
  listGroups,
  createGroup,
  updateGroup,
  deleteGroup,
  listSites,
  createSite,
  updateSite,
  deleteSite,
  listEndpoints,
  createEndpoint,
  updateEndpoint,
  deleteEndpoint,
} from "../monitored-sites";
import { fetchMock, initAt, installFetch, paramsAt, pathAt, bodyAt, respondOnce, respondWith, v1List } from "../../__tests__/v1-fetch";

beforeEach(() => installFetch());

const T0 = 1700000000;
const groupRow = { id: "g1", slug: "grp", name: "Grp", retention_days: 30, created: T0, updated: T0 };
const siteRow = { id: "s1", slug: "site", name: "Site", site_group_id: "g1", created: T0, updated: T0 };
const endpointRow = {
  id: "e1", site_id: "s1", url: "https://x", kind: "http", expected_status: 200,
  check_interval_seconds: 60, is_active: true, created: T0, updated: T0,
};

describe("monitored-sites conformance vectors", () => {
  it("hub-domain-monitored-sites-001 site mapper renames site_group_id to groupId", () => {
    const s = toSite({ ...siteRow, updated: T0 + 60 });
    expect(s.groupId).toBe("g1");
    expect(s.createdAt).toBe(new Date(T0 * 1000).toISOString());
    expect(s.updatedAt).toBe(new Date((T0 + 60) * 1000).toISOString());
  });

  it("hub-domain-monitored-sites-002 group mapper carries retentionDays", () => {
    expect(toGroup(groupRow).retentionDays).toBe(30);
  });

  it("hub-domain-monitored-sites-003 endpoint mapper preserves the check fields", () => {
    const e = toEndpoint(endpointRow);
    expect(e.siteId).toBe("s1");
    expect(e.expectedStatus).toBe(200);
    expect(e.checkIntervalSeconds).toBe(60);
    expect(e.isActive).toBe(true);
  });

  it("hub-domain-monitored-sites-004 group mapper copies id, slug, name and timestamps", () => {
    const g = toGroup(groupRow);
    expect(g).toEqual({
      id: "g1", slug: "grp", name: "Grp", retentionDays: 30,
      createdAt: new Date(T0 * 1000).toISOString(), updatedAt: new Date(T0 * 1000).toISOString(),
    });
  });

  it("hub-domain-monitored-sites-005 list-groups requests the workspace-scoped collection", async () => {
    await listGroups({ workspace: "acme" });
    expect(pathAt(0)).toBe("/api/v1/monitoring/site_groups");
    expect(paramsAt(0).get("workspace")).toBe("acme");
    expect(initAt(0).method ?? "GET").toBe("GET");
  });

  it("hub-domain-monitored-sites-006 list-groups sorts by name", async () => {
    respondWith(v1List([{ ...groupRow, id: "z", name: "Zebra" }, { ...groupRow, id: "a", name: "Apple" }]));
    expect((await listGroups()).map((g) => g.name)).toEqual(["Apple", "Zebra"]);
  });

  it("hub-domain-monitored-sites-007 create-group omits an absent retentionDays", async () => {
    respondWith(groupRow);
    await createGroup({ name: "Grp", slug: "grp" });
    expect(pathAt(0)).toBe("/api/v1/monitoring/site_groups");
    expect(initAt(0).method).toBe("POST");
    expect(bodyAt(0)).toEqual({ name: "Grp", slug: "grp" });
    expect("retention_days" in bodyAt(0)).toBe(false);
  });

  it("hub-domain-monitored-sites-008 update-group sends only the changed field", async () => {
    respondWith(groupRow);
    await updateGroup("g1", { retentionDays: 14 });
    expect(pathAt(0)).toBe("/api/v1/monitoring/site_groups/g1");
    expect(initAt(0).method).toBe("POST");
    expect(bodyAt(0)).toEqual({ retention_days: 14 });
  });

  it("hub-domain-monitored-sites-009 delete-group issues one DELETE and resolves to nothing", async () => {
    respondWith({ id: "g1", object: "site_group", deleted: true });
    await expect(deleteGroup("g1")).resolves.toBeUndefined();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(pathAt(0)).toBe("/api/v1/monitoring/site_groups/g1");
    expect(initAt(0).method).toBe("DELETE");
  });

  it("hub-domain-monitored-sites-010 list-sites issues exactly one request", async () => {
    await listSites({ workspace: "acme" });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(pathAt(0)).toBe("/api/v1/monitoring/sites");
    expect(paramsAt(0).get("workspace")).toBe("acme");
  });

  it("hub-domain-monitored-sites-011 create-site renames groupId to site_group_id", async () => {
    respondWith(siteRow);
    await createSite({ name: "Site", slug: "site", groupId: "g1" });
    expect(pathAt(0)).toBe("/api/v1/monitoring/sites");
    expect(initAt(0).method).toBe("POST");
    expect(bodyAt(0)).toEqual({ name: "Site", slug: "site", site_group_id: "g1" });
  });

  it("hub-domain-monitored-sites-012 update-site sends only the changed field", async () => {
    respondWith(siteRow);
    await updateSite("s1", { groupId: "g2" });
    expect(pathAt(0)).toBe("/api/v1/monitoring/sites/s1");
    expect(initAt(0).method).toBe("POST");
    expect(bodyAt(0)).toEqual({ site_group_id: "g2" });
  });

  it("hub-domain-monitored-sites-013 delete-site issues one DELETE and resolves to nothing", async () => {
    respondWith({ id: "s1", object: "site", deleted: true });
    await expect(deleteSite("s1")).resolves.toBeUndefined();
    expect(pathAt(0)).toBe("/api/v1/monitoring/sites/s1");
    expect(initAt(0).method).toBe("DELETE");
  });

  it.skip("hub-domain-monitored-sites-014 create-site body requires groupId (compile-time only: vitest does not type-check, and the source has no runtime guard)", () => {});

  it("hub-domain-monitored-sites-015 list-endpoints sends the workspace and no siteId filter", async () => {
    await listEndpoints("s1", { workspace: "acme" });
    expect(pathAt(0)).toBe("/api/v1/monitoring/endpoints");
    expect(paramsAt(0).get("workspace")).toBe("acme");
    expect(paramsAt(0).has("siteId")).toBe(false);
    expect(paramsAt(0).has("site_id")).toBe(false);
  });

  it("hub-domain-monitored-sites-016 list-endpoints filters to the site client-side", async () => {
    respondWith(v1List([{ ...endpointRow, id: "e2", site_id: "other" }, endpointRow]));
    const rows = await listEndpoints("s1");
    expect(rows.map((e) => e.id)).toEqual(["e1"]);
    respondWith(v1List([{ ...endpointRow, site_id: "other" }]));
    expect(await listEndpoints("s1")).toEqual([]);
  });

  it("hub-domain-monitored-sites-017 list-endpoints sorts by url", async () => {
    respondWith(v1List([{ ...endpointRow, id: "z", url: "https://z" }, { ...endpointRow, id: "a", url: "https://a" }]));
    expect((await listEndpoints("s1")).map((e) => e.url)).toEqual(["https://a", "https://z"]);
  });

  it("hub-domain-monitored-sites-018 create-endpoint sends the site id and only the given fields", async () => {
    respondWith(endpointRow);
    await createEndpoint("s1", { url: "https://x", kind: "http" });
    expect(pathAt(0)).toBe("/api/v1/monitoring/endpoints");
    expect(initAt(0).method).toBe("POST");
    expect(bodyAt(0)).toEqual({ site_id: "s1", url: "https://x", kind: "http" });
  });

  it("hub-domain-monitored-sites-019 update-endpoint never sends a site_id", async () => {
    respondWith(endpointRow);
    await updateEndpoint("e1", { isActive: false, siteId: "s9" } as never);
    expect(pathAt(0)).toBe("/api/v1/monitoring/endpoints/e1");
    expect(initAt(0).method).toBe("POST");
    expect(bodyAt(0)).toEqual({ is_active: false });
    expect("site_id" in bodyAt(0)).toBe(false);
  });

  it("hub-domain-monitored-sites-020 delete-endpoint issues one DELETE and resolves to nothing", async () => {
    respondWith({ id: "e1", object: "endpoint", deleted: true });
    await expect(deleteEndpoint("e1")).resolves.toBeUndefined();
    expect(pathAt(0)).toBe("/api/v1/monitoring/endpoints/e1");
    expect(initAt(0).method).toBe("DELETE");
  });

  it("hub-domain-monitored-sites-021 create-endpoint passes an unknown kind through verbatim", async () => {
    respondWith(endpointRow);
    await expect(createEndpoint("s1", { url: "https://x", kind: "ssh" })).resolves.toBeDefined();
    expect(bodyAt(0).kind).toBe("ssh");
  });

  it("hub-domain-monitored-sites-022 a 401 refreshes once, retries once, and a second 401 throws", async () => {
    respondOnce({}, 401); // original request
    respondOnce({ token: "NEW" }); // token refresh
    respondOnce({}, 401); // the retry
    await expect(listGroups()).rejects.toMatchObject({ status: 401 });
    expect(fetchMock).toHaveBeenCalledTimes(3);
    const retryHeaders = initAt(2).headers as Record<string, string>;
    expect(retryHeaders.Authorization).toBe("Bearer NEW");
  });

  it("hub-domain-monitored-sites-023 a 409 surfaces the backend's status, code and message", async () => {
    respondWith({ error: { message: "slug already exists", code: "duplicate_slug" } }, 409);
    await expect(createGroup({ name: "Grp", slug: "grp" })).rejects.toMatchObject({
      status: 409,
      code: "duplicate_slug",
      message: "slug already exists",
    });
  });

  it("hub-domain-monitored-sites-024 list-groups does not cache", async () => {
    await listGroups({ workspace: "acme" });
    await listGroups({ workspace: "acme" });
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});
