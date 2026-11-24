import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { StatusConfig } from "../src/config/port";
import type { Storage } from "../src/storage/ports";
import { createDashboardSet } from "../src/telemetry/dashboard/dashboard-set";
import { rangeWindow } from "../src/telemetry/dashboard/ranges";

// The set's own composition, with every provider loader and the views replaced by spies: the
// sectioned cache has its own tests, the section modules theirs. A views spy that returns a fresh
// object per call turns "same views object" into "views were not recomputed".
const m = vi.hoisted(() => {
  const fn = () => vi.fn<(...args: any[]) => any>();
  return {
    loadTraffic: fn(),
    loadDimensions: fn(),
    loadPaths: fn(),
    loadVitals: fn(),
    loadSiteHealth: fn(),
    loadSiteErrorDetail: fn(),
    loadVercelTraffic: fn(),
    loadErrorIssues: fn(),
    resolvedCounter: fn(),
    analyticsViews: fn(),
    errorsViews: fn(),
  };
});

vi.mock("../src/telemetry/dashboard/posthog-sections", () => ({
  loadTraffic: (...a: unknown[]) => m.loadTraffic(...a),
  loadDimensions: (...a: unknown[]) => m.loadDimensions(...a),
  loadPaths: (...a: unknown[]) => m.loadPaths(...a),
  loadVitals: (...a: unknown[]) => m.loadVitals(...a),
  loadSiteHealth: (...a: unknown[]) => m.loadSiteHealth(...a),
  loadSiteErrorDetail: (...a: unknown[]) => m.loadSiteErrorDetail(...a),
}));
vi.mock("../src/telemetry/dashboard/vercel-section", () => ({
  loadVercelTraffic: (...a: unknown[]) => m.loadVercelTraffic(...a),
}));
vi.mock("../src/telemetry/dashboard/errors-sections", () => ({
  loadErrorIssues: (...a: unknown[]) => m.loadErrorIssues(...a),
  resolvedCounter: (...a: unknown[]) => m.resolvedCounter(...a),
}));
vi.mock("../src/telemetry/dashboard/views", () => ({
  analyticsViews: (...a: unknown[]) => m.analyticsViews(...a),
  errorsViews: (...a: unknown[]) => m.errorsViews(...a),
}));

const NOW = Date.parse("2026-11-04T15:30:20.000Z");
const EMPTY = { data: null, error: null, updatedAt: null };
const PH = { POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" };
const GT = { GLITCHTIP_URL: "https://gt", GLITCHTIP_API_TOKEN: "t", GLITCHTIP_ORG: "o" };
const VC = { VERCEL_API_TOKEN: "v" };

const never = () => new Promise<never>(() => {});
const flush = () => vi.advanceTimersByTimeAsync(0);
const loaderSpies = [
  m.loadTraffic,
  m.loadDimensions,
  m.loadPaths,
  m.loadVitals,
  m.loadSiteHealth,
  m.loadSiteErrorDetail,
  m.loadVercelTraffic,
  m.loadErrorIssues,
];

function build(creds: Record<string, string>, readAtMs = NOW - 5000) {
  const config = { credentials: { ...creds }, glitchtipProjects: null } as unknown as StatusConfig;
  const store = {
    readAtMs,
    load: vi.fn(async () => []),
    lastRead: vi.fn(async () => ({ readAtMs: store.readAtMs, complete: true })),
  };
  const storage = { telemetry: { runtimeErrors: store } } as unknown as Storage;
  return { config, store, set: createDashboardSet(config, storage) };
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(NOW);
  for (const spy of Object.values(m)) spy.mockReset();
  for (const spy of loaderSpies) spy.mockImplementation(async () => ({}));
  m.resolvedCounter.mockImplementation(() => async () => 3);
  m.analyticsViews.mockImplementation(() => ({}));
  m.errorsViews.mockImplementation(() => ({}));
});

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe("dashboard set", () => {
  it("dashboard-set-001 analytics with no provider is all empty and not refreshing", () => {
    const { set } = build({});
    const a = set.analytics("7d");
    expect(a.configured).toEqual({ posthog: false, vercel: false });
    expect(Object.keys(a.sections).sort()).toEqual(["dimensions", "health", "paths", "traffic", "vercel", "vitals"]);
    for (const section of Object.values(a.sections)) expect(section).toEqual(EMPTY);
    expect(a.refreshing).toBe(false);
    for (const spy of loaderSpies) expect(spy).not.toHaveBeenCalled();
  });

  it("dashboard-set-002 errors with no provider is all empty and does not fail", async () => {
    const { set } = build({});
    const e = await set.errors(NOW);
    expect(e.sections).toEqual({ issues: EMPTY, sites: EMPTY, detail: EMPTY, runtime: EMPTY });
  });

  it("dashboard-set-003 errors reads the runtime report in the request and dates it by readAt", async () => {
    const readAtMs = NOW - 5000;
    const { set, store } = build(VC, readAtMs);
    const e = await set.errors(NOW);
    expect(store.load).toHaveBeenCalledTimes(1);
    expect(e.sections.runtime.error).toBeNull();
    expect(e.sections.runtime.data).toMatchObject({ readAt: new Date(readAtMs).toISOString(), total: 0 });
    expect(e.sections.runtime.updatedAt).toBe(new Date(readAtMs).toISOString());
  });

  it("dashboard-set-004 a throwing runtime read becomes the section's error and the rest is unaffected", async () => {
    const { set, store } = build(VC);
    store.load.mockRejectedValue(new Error("boom"));
    const e = await set.errors(NOW);
    expect(e.sections.runtime).toEqual({ data: null, error: "boom", updatedAt: null });
    expect(e.sections.issues).toEqual(EMPTY);
    expect(e.sections.sites).toEqual(EMPTY);
    expect(e.sections.detail).toEqual(EMPTY);
  });

  it("dashboard-set-005 analytics reports its range and an ISO generatedAt", () => {
    const { set } = build({});
    const a = set.analytics("7d");
    expect(a.range).toBe("7d");
    expect(a.generatedAt).toBe(new Date(NOW).toISOString());
  });

  it("dashboard-set-006 two reads with nothing published share one views object", () => {
    m.loadTraffic.mockImplementation(never);
    m.loadVercelTraffic.mockImplementation(never);
    const { set } = build({ ...PH, ...VC });
    const first = set.analytics("24h");
    const second = set.analytics("24h");
    expect(second.views).toBe(first.views);
    expect(m.analyticsViews).toHaveBeenCalledTimes(1);
  });

  it("dashboard-set-007 each range keeps its own views memo", () => {
    m.loadTraffic.mockImplementation(never);
    m.loadVercelTraffic.mockImplementation(never);
    const { set } = build({ ...PH, ...VC });
    const day = set.analytics("24h").views;
    const week = set.analytics("7d").views;
    expect(week).not.toBe(day);
    expect(set.analytics("24h").views).toBe(day);
    expect(set.analytics("7d").views).toBe(week);
    expect(m.analyticsViews).toHaveBeenCalledTimes(2);
  });

  it("dashboard-set-008 settleAnalytics before any read resolves true and starts nothing", async () => {
    const { set } = build({ ...PH, ...VC });
    await expect(set.settleAnalytics("24h", 1000)).resolves.toBe(true);
    for (const spy of loaderSpies) expect(spy).not.toHaveBeenCalled();
  });

  it("dashboard-set-009 settleAnalytics resolves false after timeoutMs while the refresh keeps running", async () => {
    m.loadTraffic.mockImplementation(never);
    const { set } = build(PH);
    set.analytics("24h");
    let result: boolean | undefined;
    void set.settleAnalytics("24h", 1000).then((r) => (result = r));
    await vi.advanceTimersByTimeAsync(999);
    expect(result).toBeUndefined();
    await vi.advanceTimersByTimeAsync(1);
    expect(result).toBe(false);
    expect(set.analytics("24h").refreshing).toBe(true);
  });

  it("dashboard-set-010 a Vercel result with failures is data without an error, retried after 60 seconds", async () => {
    m.loadVercelTraffic.mockImplementation(async () => ({ failed: 1, incomplete: 0 }));
    const { set } = build(VC);
    set.analytics("24h");
    await flush();
    const shown = set.analytics("24h").sections.vercel;
    expect(shown.data).toEqual({ failed: 1, incomplete: 0 });
    expect(shown.error).toBeNull();
    expect(m.loadVercelTraffic).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(59_000);
    set.analytics("24h");
    await flush();
    expect(m.loadVercelTraffic).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(1000);
    set.analytics("24h");
    await flush();
    expect(m.loadVercelTraffic).toHaveBeenCalledTimes(2);
  });

  it("dashboard-set-011 errors says which source is refreshing", async () => {
    m.loadErrorIssues.mockImplementation(never);
    const { set } = build(GT);
    const e = await set.errors(NOW);
    expect(e.refreshing).toBe(true);
    expect(e.refreshingSources).toEqual({ glitchtip: true, posthog: false });
  });

  it("dashboard-set-012 construction runs no loader and makes no network call", () => {
    const fetch = vi.fn();
    vi.stubGlobal("fetch", fetch);
    build({ ...PH, ...GT, ...VC });
    for (const spy of loaderSpies) expect(spy).not.toHaveBeenCalled();
    expect(fetch).not.toHaveBeenCalled();
  });

  it("dashboard-set-013 analytics never waits on a provider", () => {
    m.loadTraffic.mockImplementation(never);
    const { set } = build(PH);
    const a = set.analytics("24h");
    expect(a).not.toBeInstanceOf(Promise);
    expect(a.refreshing).toBe(true);
    for (const section of Object.values(a.sections)) expect(section).toEqual(EMPTY);
  });

  it("dashboard-set-014 a refreshing Vercel cache makes analytics refreshing while PostHog is idle", async () => {
    m.loadVercelTraffic.mockImplementation(never);
    const { set } = build({ ...PH, ...VC });
    set.analytics("7d");
    await flush();
    const a = set.analytics("7d");
    expect(m.loadTraffic).toHaveBeenCalledTimes(1);
    expect(a.refreshing).toBe(true);
  });

  it("dashboard-set-015 a never-resolving PostHog does not hold back Vercel", async () => {
    m.loadTraffic.mockImplementation(never);
    m.loadVercelTraffic.mockImplementation(async () => ({ failed: 0, incomplete: 0, marker: "v" }));
    const { set } = build({ ...PH, ...VC });
    set.analytics("24h");
    await flush();
    const a = set.analytics("24h");
    expect(a.sections.vercel.data).toEqual({ failed: 0, incomplete: 0, marker: "v" });
    expect(a.sections.traffic).toEqual(EMPTY);
    expect(a.sections.health).toEqual(EMPTY);
  });

  it("dashboard-set-016 GlitchTip is good for 60 seconds, the PostHog caches for 10 minutes", async () => {
    const { set } = build({ ...GT, ...PH });
    await set.errors(NOW);
    await flush();
    expect(m.loadErrorIssues).toHaveBeenCalledTimes(1);
    expect(m.loadSiteHealth).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(59_000);
    await set.errors(NOW);
    await flush();
    expect(m.loadErrorIssues).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(2000);
    await set.errors(NOW);
    await flush();
    expect(m.loadErrorIssues).toHaveBeenCalledTimes(2);
    expect(m.loadSiteHealth).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(10 * 60_000);
    await set.errors(NOW);
    await flush();
    expect(m.loadSiteHealth).toHaveBeenCalledTimes(2);
  });

  it("dashboard-set-017 the sites refresh always uses the 30d window from the current time", async () => {
    const { set } = build(PH);
    set.analytics("24h");
    await flush();
    await vi.advanceTimersByTimeAsync(3 * 3_600_000);
    await set.errors(NOW);
    await flush();
    const calls = m.loadSiteHealth.mock.calls;
    expect(calls).toHaveLength(2);
    expect(calls[0]![1]).toEqual(rangeWindow("24h", NOW));
    expect(calls[1]![1]).toEqual(rangeWindow("30d", Date.now()));
    expect(m.loadSiteErrorDetail.mock.calls[0]![1]).toEqual(rangeWindow("30d", Date.now()));
  });

  it("dashboard-set-018 configured is decided on each call", () => {
    m.loadTraffic.mockImplementation(never);
    const { set, config } = build(PH);
    const on = set.analytics("24h");
    expect(on.configured.posthog).toBe(true);
    expect(on.refreshing).toBe(true);
    (config as { credentials: unknown }).credentials = {};
    const off = set.analytics("24h");
    expect(off.configured.posthog).toBe(false);
    expect(off.refreshing).toBe(false);
    expect(off.sections.traffic).toEqual(EMPTY);
    expect(m.loadTraffic).toHaveBeenCalledTimes(1);
  });

  it("dashboard-set-019 a changing runtime section does not change the errors views", async () => {
    m.loadSiteHealth.mockImplementation(never);
    const { set, store } = build({ ...PH, ...VC }, NOW - 5000);
    const first = await set.errors(NOW);
    store.readAtMs = NOW - 1000;
    const second = await set.errors(NOW);
    expect(second.sections.runtime.updatedAt).not.toBe(first.sections.runtime.updatedAt);
    expect(second.views).toBe(first.views);
    expect(m.errorsViews).toHaveBeenCalledTimes(1);
  });

  it("dashboard-set-020 settleErrors resolves true once both refreshes settle", async () => {
    let finishIssues!: () => void;
    let finishSites!: () => void;
    m.loadErrorIssues.mockImplementation(() => new Promise<object>((r) => (finishIssues = () => r({}))));
    m.loadSiteHealth.mockImplementation(() => new Promise<object>((r) => (finishSites = () => r({}))));
    const { set } = build({ ...GT, ...PH });
    await set.errors(NOW);
    await flush();
    let result: boolean | undefined;
    void set.settleErrors(5000).then((r) => (result = r));
    await vi.advanceTimersByTimeAsync(100);
    expect(result).toBeUndefined();
    finishIssues();
    finishSites();
    await vi.advanceTimersByTimeAsync(100);
    expect(result).toBe(true);
  });

  it("dashboard-set-021 every GlitchTip refresh shares one resolved counter", async () => {
    const counter = vi.fn(async () => 3);
    m.resolvedCounter.mockImplementation(() => counter);
    const { set } = build(GT);
    await set.errors(NOW);
    await flush();
    await vi.advanceTimersByTimeAsync(61_000);
    await set.errors(NOW);
    await flush();
    expect(m.loadErrorIssues).toHaveBeenCalledTimes(2);
    expect(m.resolvedCounter).toHaveBeenCalledTimes(1);
    expect(m.loadErrorIssues.mock.calls[0]![2]).toBe(counter);
    expect(m.loadErrorIssues.mock.calls[1]![2]).toBe(counter);
  });
});
