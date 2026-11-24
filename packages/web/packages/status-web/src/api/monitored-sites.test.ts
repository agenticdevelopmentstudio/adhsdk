// Runtime unit tests for status's monitoring-config mappers. The important case is
// `toEndpoint`: the backend has no `environment` column, so the mapper must default
// the frontend-only field to null rather than leak `undefined` into the view.
import { describe, expect, it, vi } from "vitest";
import { createStatusApiClient } from "./client";
import { toGroup, toSite, toEndpoint, updateSite, ignoreProjects, unignoreProject } from "./monitored-sites";

const as = <F extends (arg: never) => unknown>(o: Record<string, unknown>): Parameters<F>[0] =>
  o as unknown as Parameters<F>[0];

describe("status monitored-sites mappers", () => {
  it("status-web-api-007 toGroup passes group fields through", () => {
    const g = toGroup(as<typeof toGroup>({ id: "g", slug: "s", name: "N", retentionDays: 14 }));
    expect(g).toEqual({ id: "g", slug: "s", name: "N", retentionDays: 14 });
  });

  it("status-web-api-008 toSite renames siteGroupId→groupId", () => {
    const s = toSite(as<typeof toSite>({ id: "s1", slug: "site", name: "Site", siteGroupId: "g1" }));
    expect(s.groupId).toBe("g1");
  });

  it("status-web-api-009 toEndpoint defaults the missing-from-backend `environment` to null", () => {
    // The backend never returns `environment` (no such column).
    const e = toEndpoint(
      as<typeof toEndpoint>({ id: "e", siteId: "s", url: "https://x", kind: "http", expectedStatus: 200, checkIntervalSeconds: 60, isActive: true }),
    );
    expect(e.environment).toBeNull();
  });

  it("toEndpoint keeps an explicitly-provided environment", () => {
    const e = toEndpoint(
      as<typeof toEndpoint>({ id: "e", siteId: "s", url: "https://x", kind: "http", environment: "production", expectedStatus: 200, checkIntervalSeconds: 60, isActive: true }),
    );
    expect(e.environment).toBe("production");
  });

  it("status-web-api-010 toEndpoint defaults DNS record checks to on when the backend omits them", () => {
    // A row created before the dns_check_* columns existed reads them as undefined;
    // the view must default each to true (the historic "resolve via any record" behavior).
    const e = toEndpoint(
      as<typeof toEndpoint>({ id: "e", siteId: "s", url: "https://x", kind: "http", expectedStatus: 200, checkIntervalSeconds: 60, isActive: true }),
    );
    expect(e.dnsCheckA).toBe(true);
    expect(e.dnsCheckAaaa).toBe(true);
    expect(e.dnsCheckCname).toBe(true);
  });

  it("status-web-api-011 toEndpoint preserves an explicit `false` DNS check (no `?? true` clobber)", () => {
    const e = toEndpoint(
      as<typeof toEndpoint>({ id: "e", siteId: "s", url: "https://x", kind: "http", dnsCheckCname: false, expectedStatus: 200, checkIntervalSeconds: 60, isActive: true }),
    );
    expect(e.dnsCheckCname).toBe(false);
    expect(e.dnsCheckA).toBe(true);
  });
});

const okJson = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), { status });

describe("status monitored-sites client calls", () => {
  it("status-web-api-003 updateSite rejects with method, url, status and the backend's error detail", async () => {
    const fetchMock = vi.fn(async () => okJson({ error: "not found" }, 404));
    const api = createStatusApiClient({ fetch: fetchMock as unknown as typeof fetch });
    await expect(updateSite(api, "x", { name: "N" })).rejects.toThrow("PATCH /api/config/sites/x → 404 — not found");
    expect(fetchMock).toHaveBeenCalledWith("/api/config/sites/x", expect.objectContaining({ method: "PATCH" }));
  });

  it("status-web-api-014 ignoreProjects issues one POST per project, concurrently", async () => {
    const resolvers: Array<() => void> = [];
    const fetchMock = vi.fn(
      () => new Promise<Response>((resolve) => resolvers.push(() => resolve(new Response(null, { status: 204 })))),
    );
    const api = createStatusApiClient({ fetch: fetchMock as unknown as typeof fetch });
    const done = ignoreProjects(api, [
      { platform: "vercel", projectName: "a" },
      { platform: "railway", projectName: "b" },
    ]);
    // Both requests are in flight before either has resolved: concurrent, not sequential.
    expect(fetchMock).toHaveBeenCalledTimes(2);
    for (const call of fetchMock.mock.calls as unknown as Array<[string, RequestInit]>) {
      expect(call[0]).toBe("/api/config/ignored-projects");
      expect(call[1].method).toBe("POST");
    }
    resolvers.forEach((r) => r());
    await expect(done).resolves.toBeUndefined();
  });

  it("status-web-api-015 unignoreProject DELETEs the URL-encoded platform|project id", async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 204 }));
    const api = createStatusApiClient({ fetch: fetchMock as unknown as typeof fetch });
    await unignoreProject(api, "vercel", "my/app");
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/config/ignored-projects/vercel%7Cmy%2Fapp",
      expect.objectContaining({ method: "DELETE" }),
    );
  });
});
