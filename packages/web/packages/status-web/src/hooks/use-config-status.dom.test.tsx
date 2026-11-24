// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, waitFor, act } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement } from "react";
// @ts-expect-error vite raw import; read as text to check the directive
import source from "./use-config-status.ts?raw";

// The five reads behind the config model. Mocked at the module boundary so the test
// exercises the REAL query wiring (keys, enabled, Promise.all shape) and only the
// network is faked.
const listGroups = vi.fn();
const listSites = vi.fn();
const listIntegrations = vi.fn();
const listAllEndpoints = vi.fn();
vi.mock("../api/monitored-sites", () => ({
  listGroups: (...a: unknown[]) => listGroups(...a),
  listSites: (...a: unknown[]) => listSites(...a),
  listIntegrations: (...a: unknown[]) => listIntegrations(...a),
  listAllEndpoints: (...a: unknown[]) => listAllEndpoints(...a),
}));
const fetchUnconfigured = vi.fn();
vi.mock("./use-deploy-projects", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./use-deploy-projects")>();
  return { ...actual, fetchUnconfigured: (...a: unknown[]) => fetchUnconfigured(...a) };
});

import {
  useConfigStatus,
  invalidateConfigQueries,
  CONFIGURE_DATA_KEY,
  CONFIGURE_CLASSIFICATION_KEY,
  type UseConfigStatus,
} from "./use-config-status";

const endpoint = (o: Record<string, unknown> = {}): Record<string, unknown> => ({
  id: "e1", siteId: "s1", url: "https://x.test", kind: "http", environment: null, platform: null,
  deployProject: null, ignoreProjectWarning: false, expectedStatus: 200, expectBody: null,
  dnsCheckA: true, dnsCheckAaaa: true, dnsCheckCname: true, checkIntervalSeconds: 60, isActive: true, ...o,
});
const unconfigured = (o: Record<string, unknown> = {}): Record<string, unknown> => ({
  pending: [], addable: [], noDomain: [], unconfiguredSites: [], ...o,
});

function harness(opts?: { enabled?: boolean }) {
  const out: { current: UseConfigStatus | null } = { current: null };
  function Probe(): ReactElement | null {
    out.current = useConfigStatus(opts?.enabled === undefined ? undefined : { enabled: opts.enabled });
    return null;
  }
  // retry:0 so a rejected leg settles in one tick, like the app's `retry: 1` eventually does.
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <Probe />
    </QueryClientProvider>,
  );
  return { out, client };
}

const flush = async (): Promise<void> => {
  await act(async () => {
    await new Promise((r) => setTimeout(r, 20));
  });
};

describe("useConfigStatus", () => {
  beforeEach(() => {
    for (const m of [listGroups, listSites, listIntegrations, listAllEndpoints, fetchUnconfigured]) m.mockReset();
    listGroups.mockResolvedValue([{ id: "g1", slug: "g", name: "G", retentionDays: 30 }]);
    listSites.mockResolvedValue([{ id: "s1", slug: "s", name: "S", groupId: "g1" }]);
    listIntegrations.mockResolvedValue([{ id: "i1", platform: "vercel", label: "Vercel", config: {}, tokenEnvVar: null, isActive: true }]);
    listAllEndpoints.mockResolvedValue([endpoint()]);
    fetchUnconfigured.mockResolvedValue(unconfigured());
    vi.spyOn(console, "error").mockImplementation(() => {});
  });
  afterEach(() => vi.restoreAllMocks());

  it("config-status-001 still serves the rosters when the deploy-project scan fails", async () => {
    // The regression this guards: the provider scan used to be a fifth leg of the SAME
    // Promise.all as the four DB reads, so one flaky platform emptied Settings ▸ Sites and
    // Settings ▸ Platforms while the rows sat readable in SQLite.
    fetchUnconfigured.mockRejectedValue(new Error("deploy-projects/unconfigured 502"));
    const { out } = harness();
    await waitFor(() => expect(out.current!.error).toBeInstanceOf(Error));
    const configure = out.current!.configure!;
    expect(configure.sites).toHaveLength(1);
    expect(configure.endpoints).toHaveLength(1);
    expect(configure.integrations).toHaveLength(1);
    // …and the failure is still REPORTED, so a dead scan is never read as "all clear".
    expect((out.current!.error as Error).message).toContain("502");
  });

  it("config-status-002 reports both halves when everything loads", async () => {
    fetchUnconfigured.mockResolvedValue(unconfigured({ pending: [{ platform: "vercel", projectName: "p" }] }));
    const { out } = harness();
    // Both axes land: the endpoint names no deploy project (1 site) + 1 pending project.
    await waitFor(() => expect(out.current!.status.counts.total).toBe(2));
    expect(out.current!.error).toBeFalsy();
  });

  it("config-status-003 status stays empty while the classification is pending", async () => {
    fetchUnconfigured.mockReturnValue(new Promise(() => {}));
    const { out } = harness();
    await waitFor(() => expect(out.current!.configure).toBeDefined());
    expect(out.current!.status.counts.total).toBe(0);
    expect(out.current!.status).toEqual({
      unconfiguredSites: [], unmonitoredProjects: [], addableProjects: [], noDomainProjects: 0,
      unmonitoredByPlatform: new Map(), counts: { sites: 0, projects: 0, total: 0 },
    });
    expect(out.current!.isLoading).toBe(false);
  });

  it("config-status-004 a paused endpoint is not an unconfigured site", async () => {
    listAllEndpoints.mockResolvedValue([endpoint({ isActive: false })]);
    const { out } = harness();
    await waitFor(() => expect(out.current!.configure).toBeDefined());
    await waitFor(() => expect(fetchUnconfigured).toHaveBeenCalled());
    await flush();
    expect(out.current!.status.unconfiguredSites).toEqual([]);
    expect(out.current!.status.counts.sites).toBe(0);
  });

  it("config-status-005 an endpoint with isActive absent still counts as unconfigured", async () => {
    const e = endpoint();
    delete e.isActive;
    listAllEndpoints.mockResolvedValue([e]);
    const { out } = harness();
    await waitFor(() => expect(out.current!.status.counts.sites).toBe(1));
    expect(out.current!.status.unconfiguredSites).toEqual([e]);
  });

  it("config-status-006 health, dns and custom endpoints are never unconfigured", async () => {
    listAllEndpoints.mockResolvedValue([
      endpoint({ id: "h", kind: "health" }),
      endpoint({ id: "d", kind: "dns" }),
      endpoint({ id: "c", kind: "custom" }),
    ]);
    const { out } = harness();
    await waitFor(() => expect(out.current!.configure?.endpoints).toHaveLength(3));
    await waitFor(() => expect(fetchUnconfigured).toHaveBeenCalled());
    await flush();
    expect(out.current!.status.unconfiguredSites).toEqual([]);
  });

  it("config-status-007 a wired http endpoint is not unconfigured", async () => {
    // A second, genuinely unconfigured endpoint proves the status was assembled.
    listAllEndpoints.mockResolvedValue([
      endpoint({ id: "wired", platform: "vercel", deployProject: "web" }),
      endpoint({ id: "bare" }),
    ]);
    const { out } = harness();
    await waitFor(() => expect(out.current!.status.counts.sites).toBe(1));
    expect(out.current!.status.unconfiguredSites.map((e: { id?: unknown }) => e.id)).toEqual(["bare"]);
  });

  it("config-status-008 tallies pending projects by canonical platform", async () => {
    fetchUnconfigured.mockResolvedValue(unconfigured({
      pending: [
        { platform: "cloudflare-pages", projectName: "a" },
        { platform: "cloudflare", projectName: "b" },
        { platform: "vercel", projectName: "c" },
        { platform: null, projectName: "d" },
      ],
    }));
    const { out } = harness();
    await waitFor(() => expect(out.current!.status.counts.projects).toBe(4));
    expect(Object.fromEntries(out.current!.status.unmonitoredByPlatform)).toEqual({ cloudflare: 2, vercel: 1, "": 1 });
  });

  it("config-status-009 takes noDomain count and addable list from the server", async () => {
    const addable = [{ platform: "vercel", projectName: "x" }, { platform: "vercel", projectName: "y" }];
    fetchUnconfigured.mockResolvedValue(unconfigured({
      addable,
      noDomain: [{ id: 1 }, { id: 2 }, { id: 3 }],
    }));
    const { out } = harness();
    await waitFor(() => expect(out.current!.status.noDomainProjects).toBe(3));
    expect(out.current!.status.addableProjects).toEqual(addable);
  });

  it("config-status-010 reports the roster error first when both fail", async () => {
    listGroups.mockRejectedValue(new Error("A"));
    fetchUnconfigured.mockRejectedValue(new Error("B"));
    const { out } = harness();
    await waitFor(() => expect(out.current!.error).toBeInstanceOf(Error));
    await waitFor(() => expect(fetchUnconfigured).toHaveBeenCalled());
    await flush();
    expect((out.current!.error as Error).message).toBe("A");
    expect(out.current!.configure).toBeUndefined();
    expect(out.current!.status.counts.total).toBe(0);
    expect(out.current!.status.unconfiguredSites).toEqual([]);
  });

  it("config-status-011 one failed roster read leaves the whole roster unavailable", async () => {
    listIntegrations.mockRejectedValue(new Error("integrations down"));
    const { out } = harness();
    await waitFor(() => expect(out.current!.error).toBeInstanceOf(Error));
    expect((out.current!.error as Error).message).toBe("integrations down");
    expect(out.current!.configure).toBeUndefined();
  });

  it("config-status-012 invalidateConfigQueries invalidates both keys, refetches observed ones, resolves void", async () => {
    // Observed: both keys refetch.
    const { out, client } = harness();
    await waitFor(() => expect(out.current!.status.counts.total).toBe(1));
    expect(listGroups).toHaveBeenCalledTimes(1);
    expect(fetchUnconfigured).toHaveBeenCalledTimes(1);
    let result: unknown = "unset";
    await act(async () => {
      result = await invalidateConfigQueries(client);
    });
    expect(result).toBeUndefined();
    expect(listGroups).toHaveBeenCalledTimes(2);
    expect(fetchUnconfigured).toHaveBeenCalledTimes(2);

    // Unobserved: both keys are simply marked invalid.
    const idle = new QueryClient();
    idle.setQueryData([...CONFIGURE_DATA_KEY], {});
    idle.setQueryData([...CONFIGURE_CLASSIFICATION_KEY], {});
    await invalidateConfigQueries(idle);
    expect(idle.getQueryState([...CONFIGURE_DATA_KEY])?.isInvalidated).toBe(true);
    expect(idle.getQueryState([...CONFIGURE_CLASSIFICATION_KEY])?.isInvalidated).toBe(true);
  });

  it("config-status-013 enabled:false fetches nothing and leaves the status empty", async () => {
    const { out } = harness({ enabled: false });
    await flush();
    expect(listGroups).not.toHaveBeenCalled();
    expect(listSites).not.toHaveBeenCalled();
    expect(listIntegrations).not.toHaveBeenCalled();
    expect(listAllEndpoints).not.toHaveBeenCalled();
    expect(fetchUnconfigured).not.toHaveBeenCalled();
    expect(out.current!.status.counts).toEqual({ sites: 0, projects: 0, total: 0 });
    expect(out.current!.status.unconfiguredSites).toEqual([]);
    expect(out.current!.configure).toBeUndefined();
  });

  it("config-status-014 refetch() re-runs all five reads and resolves with both results", async () => {
    const { out } = harness();
    await waitFor(() => expect(out.current!.status.counts.total).toBe(1));
    let results: unknown;
    await act(async () => {
      results = await out.current!.refetch();
    });
    for (const m of [listGroups, listSites, listIntegrations, listAllEndpoints, fetchUnconfigured]) {
      expect(m).toHaveBeenCalledTimes(2);
    }
    expect(Array.isArray(results)).toBe(true);
    expect(results as unknown[]).toHaveLength(2);
  });

  it("config-status-015 the classification read takes no options and hits the non-fresh path", async () => {
    const { out } = harness();
    await waitFor(() => expect(out.current!.status.counts.total).toBe(1));
    expect(fetchUnconfigured).toHaveBeenCalledTimes(1);
    expect(fetchUnconfigured.mock.calls[0]).toHaveLength(1); // (api) only: no { fresh }
    // The real fetchUnconfigured, given no options, requests the plain path.
    const actual = await vi.importActual<typeof import("./use-deploy-projects")>("./use-deploy-projects");
    const api = { fetch: vi.fn(async (_path: string, _init?: RequestInit) => new Response(JSON.stringify(unconfigured()), { status: 200 })) };
    await actual.fetchUnconfigured(api as never);
    expect(api.fetch.mock.calls[0]![0]).toBe("/deploy-projects/unconfigured");
    expect(String(api.fetch.mock.calls[0]![0])).not.toContain("fresh");
  });

  it("config-status-016 exports the two query keys", () => {
    expect(CONFIGURE_DATA_KEY).toEqual(["configure-data"]);
    expect(CONFIGURE_CLASSIFICATION_KEY).toEqual(["configure-classification"]);
  });

  it("config-status-017 the module is marked client-only", () => {
    expect((source as string).trimStart().startsWith('"use client"')).toBe(true);
  });
});
