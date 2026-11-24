// @vitest-environment jsdom
import { describe, it, expect, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createElement, type ReactNode } from "react";
import type { StatusApiClient } from "../api/client";

// The latch (`nextFetchIsFresh`) is module state, so each test loads a fresh copy of every module
// that shares React Query's context.
async function load() {
  vi.resetModules();
  const rq = await import("@tanstack/react-query");
  const rtl = await import("@testing-library/react");
  const dp = await import("./use-deploy-projects");
  const api = await import("../api/client");
  return { rq, rtl, dp, api };
}

type Stub = ReturnType<typeof vi.fn>;
function clientWith(fetchStub: Stub): StatusApiClient {
  return { url: (p: string) => p, fetch: fetchStub as never, json: vi.fn() as never, eventSource: vi.fn() as never };
}
const ok = (body: unknown) => ({ ok: true, status: 200, json: async () => body });
const bad = (status: number) => ({ ok: false, status, json: async () => ({}) });

async function mount(fetchStub: Stub) {
  const m = await load();
  const queryClient = new m.rq.QueryClient({ defaultOptions: { queries: { retry: false } } });
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(
      m.rq.QueryClientProvider,
      { client: queryClient },
      createElement(m.api.StatusApiProvider, { client: clientWith(fetchStub) }, children),
    );
  return { ...m, queryClient, wrapper };
}

describe("fetchDeployProjects / fetchUnconfigured", () => {
  it("deploy-projects-001 requests /deploy-projects with no-store", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => ok({ projects: [] }));
    await dp.fetchDeployProjects(clientWith(f));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f).toHaveBeenCalledWith("/deploy-projects", { cache: "no-store" });
  });
  it("deploy-projects-002 appends ?fresh=1 when fresh", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => ok({ projects: [] }));
    await dp.fetchDeployProjects(clientWith(f), { fresh: true });
    expect(f).toHaveBeenCalledWith("/deploy-projects?fresh=1", { cache: "no-store" });
  });
  it("deploy-projects-003 resolves to the response body", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => ok({ projects: [], verifiedPlatforms: ["vercel"] }));
    await expect(dp.fetchDeployProjects(clientWith(f))).resolves.toEqual({ projects: [], verifiedPlatforms: ["vercel"] });
  });
  it("deploy-projects-004 fails with the status on a non-ok response", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => bad(502));
    await expect(dp.fetchDeployProjects(clientWith(f))).rejects.toThrow("deploy-projects 502");
  });
  it("deploy-projects-005 requests /deploy-projects/unconfigured with no-store", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => ok({}));
    await dp.fetchUnconfigured(clientWith(f));
    expect(f).toHaveBeenCalledWith("/deploy-projects/unconfigured", { cache: "no-store" });
  });
  it("deploy-projects-006 appends ?fresh=1 to the unconfigured path", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => ok({}));
    await dp.fetchUnconfigured(clientWith(f), { fresh: true });
    expect(f).toHaveBeenCalledWith("/deploy-projects/unconfigured?fresh=1", { cache: "no-store" });
  });
  it("deploy-projects-007 fails with the status on a non-ok unconfigured response", async () => {
    const { dp } = await load();
    const f = vi.fn(async () => bad(502));
    await expect(dp.fetchUnconfigured(clientWith(f))).rejects.toThrow("deploy-projects/unconfigured 502");
  });
  it("deploy-projects-008 resolves to the unconfigured body", async () => {
    const { dp } = await load();
    const body = { pending: [{ platform: "vercel", projectName: "p" }], addable: [], noDomain: [], unconfiguredSites: [] };
    const f = vi.fn(async () => ok(body));
    await expect(dp.fetchUnconfigured(clientWith(f))).resolves.toEqual(body);
  });
});

describe("useDeployProjects", () => {
  it("deploy-projects-009 first request of a process is fresh", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f.mock.calls[0][0]).toBe("/deploy-projects?fresh=1");
  });
  it("deploy-projects-010 latch disarms after a success", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, queryClient, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.isSuccess).toBe(true));
    await rtl.act(() => queryClient.invalidateQueries({ queryKey: ["deploy-projects"] }));
    await rtl.waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(f.mock.calls[1][0]).toBe("/deploy-projects");
  });
  it("deploy-projects-011 latch stays armed after a failure", async () => {
    const f = vi.fn(async () => bad(500));
    const { rtl, dp, queryClient, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.status).toBe("error"));
    await rtl.act(async () => {
      await queryClient.refetchQueries({ queryKey: ["deploy-projects"] });
    });
    expect(f).toHaveBeenCalledTimes(2);
    expect(f.mock.calls[0][0]).toBe("/deploy-projects?fresh=1");
    expect(f.mock.calls[1][0]).toBe("/deploy-projects?fresh=1");
  });
  it("deploy-projects-012 arming makes the next fetch fresh", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, queryClient, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.isSuccess).toBe(true));
    dp.armFreshDeployProjectsFetch();
    await rtl.act(() => queryClient.invalidateQueries({ queryKey: ["deploy-projects"] }));
    await rtl.waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(f.mock.calls[1][0]).toBe("/deploy-projects?fresh=1");
  });
  it("deploy-projects-013 enabled:false never calls the transport", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects({ enabled: false }), { wrapper });
    await new Promise((r) => setTimeout(r, 30));
    expect(f).not.toHaveBeenCalled();
    expect(result.current.fetchStatus).toBe("idle");
  });
  it("deploy-projects-014 serves cached data within the 60 s stale time", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, wrapper } = await mount(f);
    const first = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(first.result.current.isSuccess).toBe(true));
    const realNow = Date.now();
    const spy = vi.spyOn(Date, "now").mockReturnValue(realNow + 30_000);
    const second = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await new Promise((r) => setTimeout(r, 30));
    spy.mockRestore();
    expect(f).toHaveBeenCalledTimes(1);
    expect(second.result.current.data).toEqual({ projects: [] });
  });
  it("deploy-projects-015 stores state under the deploy-projects key", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, queryClient, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(queryClient.getQueryState(["deploy-projects"])).toBeDefined();
  });
  it("deploy-projects-016 surfaces a non-ok status as the query error", async () => {
    const f = vi.fn(async () => bad(503));
    const { rtl, dp, wrapper } = await mount(f);
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.status).toBe("error"));
    expect((result.current.error as Error).message).toBe("deploy-projects 503");
  });
  it("deploy-projects-017 the unconfigured read does not touch the latch", async () => {
    const f = vi.fn(async (path: string) => (path.startsWith("/deploy-projects/unconfigured") ? ok({}) : ok({ projects: [] })));
    const { rtl, dp, wrapper } = await mount(f);
    await dp.fetchUnconfigured(clientWith(f));
    expect(f.mock.calls[0][0]).toBe("/deploy-projects/unconfigured");
    const { result } = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f.mock.calls[1][0]).toBe("/deploy-projects?fresh=1");
  });
  it("deploy-projects-018 concurrent readers share one request", async () => {
    const f = vi.fn(async () => ok({ projects: [] }));
    const { rtl, dp, wrapper } = await mount(f);
    const a = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    const b = rtl.renderHook(() => dp.useDeployProjects(), { wrapper });
    await rtl.waitFor(() => expect(a.result.current.isSuccess && b.result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
  });
  it("deploy-projects-019 the module is marked client-only", () => {
    const src = readFileSync(resolve(__dirname, "use-deploy-projects.ts"), "utf8");
    expect(src.split("\n")[0]).toBe('"use client";');
  });
});
