import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { _resetProviderCooldowns, rateLimitedUntil } from "@adh-sdk/deploy-platform/cooldown";
import {
  advanceCursor,
  groupIdentity,
  groupRuntimeEntries,
  loadRuntimeErrorsReport,
  normalizePath,
  readJsonLines,
  runtimeErrorsReport,
  RUNTIME_ERROR_REPORT_CAP,
  toRuntimeEntry,
  unseenEntries,
  worseLevel,
} from "../src/telemetry/runtime-errors";
import { vercelRuntimeFetcher } from "../src/telemetry/fetchers/vercel-runtime";
import { collectTelemetry } from "../src/telemetry/server";
import type { Fetcher } from "../src/telemetry/ports";
import type { RuntimeErrorGroup, RuntimeLogEntry } from "../src/telemetry/types";
import { createLibsqlStorage } from "../src/libsql";
import { runIntegrationsCheck, _resetSelfCheckStability } from "../src/monitor/integrations";
import { freshDb } from "./helpers/db";
import { testConfig } from "./helpers/config";

const enc = new TextEncoder();
const NOW = Date.parse("2026-11-06T12:00:00.000Z");
const AT = { project: "site-production", deploymentId: "dpl_1", domain: "site.example.com" };

/** A stream that hands out `chunks` and then, unless `close`, stays open forever. */
function streamOf(chunks: string[], close = true): ReadableStream<Uint8Array> {
  return new ReadableStream<Uint8Array>({
    start(controller) {
      for (const c of chunks) controller.enqueue(enc.encode(c));
      if (close) controller.close();
    },
  });
}

function entry(over: Partial<RuntimeLogEntry> = {}): RuntimeLogEntry {
  return {
    project: "site-production",
    deploymentId: "dpl_1",
    domain: "site.example.com",
    rowId: "r1",
    timestampMs: NOW - 60_000,
    level: "error",
    source: "serverless",
    method: "GET",
    path: "/api/posts/123",
    status: 500,
    message: "boom\nat handler (index.js:1)",
    ...over,
  };
}

function group(over: Partial<RuntimeErrorGroup> = {}): RuntimeErrorGroup {
  return {
    key: "k",
    project: "p",
    deploymentId: "d",
    domain: null,
    source: "serverless",
    method: "GET",
    path: "/",
    status: 500,
    level: "error",
    message: "m",
    count: 1,
    firstSeen: new Date(NOW - 60_000).toISOString(),
    lastSeen: new Date(NOW - 60_000).toISOString(),
    sampleRowId: null,
    ...over,
  };
}

describe("readJsonLines", () => {
  it("joins a line split across chunks, skips non-JSON, and reads the unterminated tail", async () => {
    const seen: unknown[] = [];
    const res = await readJsonLines(
      streamOf(['{"a":1}\n{"b"', ':2}\nnot json\n\n', '{"c":3}']),
      new AbortController().signal,
      (v) => seen.push(v),
    );
    expect(res).toEqual({ aborted: false });
    expect(seen).toEqual([{ a: 1 }, { b: 2 }, { c: 3 }]);
  });

  it("ends a stream that stays open when the budget runs out, dropping the cut tail", async () => {
    const seen: unknown[] = [];
    const res = await readJsonLines(streamOf(['{"a":1}\n{"b":'], false), AbortSignal.timeout(30), (v) =>
      seen.push(v),
    );
    expect(res).toEqual({ aborted: true });
    expect(seen).toEqual([{ a: 1 }]);
  });

  it("returns at once on an already-aborted signal", async () => {
    const ac = new AbortController();
    ac.abort();
    const res = await readJsonLines(streamOf([], false), ac.signal, () => {});
    expect(res).toEqual({ aborted: true });
  });
});

describe("toRuntimeEntry", () => {
  const raw = { rowId: "r1", timestampInMs: NOW, source: "serverless", message: "m" };

  it("keeps error and fatal lines, and any 5xx", () => {
    expect(toRuntimeEntry({ ...raw, level: "error" }, AT)?.level).toBe("error");
    expect(toRuntimeEntry({ ...raw, level: "fatal" }, AT)?.level).toBe("fatal");
    expect(toRuntimeEntry({ ...raw, level: "info", responseStatusCode: 502 }, AT)?.status).toBe(502);
  });

  it("drops info/warning lines below 500, and lines it could not count once", () => {
    expect(toRuntimeEntry({ ...raw, level: "warning", responseStatusCode: 404 }, AT)).toBeNull();
    expect(toRuntimeEntry({ ...raw, level: "info" }, AT)).toBeNull();
    expect(toRuntimeEntry({ ...raw, level: "error", rowId: undefined }, AT)).toBeNull();
    expect(toRuntimeEntry({ ...raw, level: "error", timestampInMs: "x" }, AT)).toBeNull();
  });

  it("strips the query and fragment, and reads status 0 as none", () => {
    const e = toRuntimeEntry(
      { ...raw, level: "error", requestPath: "/a/b?token=x#frag", requestMethod: "POST", responseStatusCode: 0 },
      AT,
    )!;
    expect(e).toMatchObject({ path: "/a/b", method: "POST", status: null, domain: "site.example.com" });
    expect(toRuntimeEntry({ ...raw, level: "error", requestPath: "?q=1" }, AT)?.path).toBe("/");
    expect(toRuntimeEntry({ ...raw, level: "error", domain: "other.example.com" }, AT)?.domain).toBe(
      "other.example.com",
    );
  });
});

describe("grouping", () => {
  it("reads id-like segments as :id and leaves words alone", () => {
    expect(normalizePath("/posts/123/edit")).toBe("/posts/:id/edit");
    expect(normalizePath("/u/3f2504e0-4f89-11d3-9a0c-0305e82c3301")).toBe("/u/:id");
    expect(normalizePath("/blob/deadbeef1234abcd")).toBe("/blob/:id");
    expect(normalizePath("/s/V1StGXR8Z5jdHi6BmyT2x")).toBe("/s/:id");
    expect(normalizePath("/about/facebook-account")).toBe("/about/facebook-account");
    expect(normalizePath("/")).toBe("/");
    expect(normalizePath(null)).toBeNull();
  });

  it("keys on the normalized path and the first message line, stably", () => {
    const a = groupIdentity(entry({ path: "/api/posts/1", message: "boom\nstack a" }));
    const b = groupIdentity(entry({ path: "/api/posts/2", message: "boom\nstack b", rowId: "r2" }));
    expect(a.key).toBe(b.key);
    expect(a.key).toMatch(/^[0-9a-f]{32}$/);
    expect(a).toMatchObject({ path: "/api/posts/:id", message: "boom" });
    expect(groupIdentity(entry({ status: 502 })).key).not.toBe(a.key);
    expect(groupIdentity(entry({ message: "x".repeat(300) })).message).toHaveLength(200);
  });

  it("folds a batch: counts, worst level, and the newest line's deployment and sample", () => {
    const [g, ...rest] = groupRuntimeEntries([
      entry({ rowId: "r1", timestampMs: 1_000, level: "error", deploymentId: "dpl_old" }),
      entry({ rowId: "r2", timestampMs: 3_000, level: "error", deploymentId: "dpl_new" }),
      entry({ rowId: "r3", timestampMs: 2_000, level: "fatal", deploymentId: "dpl_old" }),
    ]);
    expect(rest).toEqual([]);
    expect(g).toMatchObject({
      count: 3,
      level: "fatal",
      firstSeenMs: 1_000,
      lastSeenMs: 3_000,
      deploymentId: "dpl_new",
      sampleRowId: "r2",
    });
    expect(worseLevel("error", "mystery")).toBe("error");
  });
});

describe("the per-deployment high-water mark", () => {
  it("counts a re-read once, including lines that share the edge millisecond", () => {
    const first = [entry({ rowId: "a", timestampMs: 10 }), entry({ rowId: "b", timestampMs: 20 })];
    const cursor = advanceCursor(undefined, unseenEntries(first, undefined));
    expect(cursor).toEqual({ lastTimestampMs: 20, lastRowIds: ["b"] });

    const again = [...first, entry({ rowId: "c", timestampMs: 20 }), entry({ rowId: "d", timestampMs: 30 })];
    const unseen = unseenEntries(again, cursor);
    expect(unseen.map((e) => e.rowId)).toEqual(["c", "d"]);
    expect(advanceCursor(cursor, unseen)).toEqual({ lastTimestampMs: 30, lastRowIds: ["d"] });
    expect(advanceCursor(cursor, [])).toEqual(cursor);
    expect(advanceCursor(undefined, [])).toBeUndefined();
  });

  it("counts a rowId repeated inside one batch once", () => {
    expect(unseenEntries([entry({ rowId: "a" }), entry({ rowId: "a" })], undefined)).toHaveLength(1);
  });
});

describe("runtimeErrorsReport", () => {
  it("keeps the last 24h, worst level first, then most frequent, and caps the list", () => {
    const old = group({ key: "old", lastSeen: new Date(NOW - 25 * 3_600_000).toISOString() });
    const fatal = group({ key: "fatal", level: "fatal", count: 1 });
    const many = group({ key: "many", count: 9 });
    const few = group({ key: "few", count: 2 });
    const r = runtimeErrorsReport([old, few, many, fatal], NOW);
    expect(r).toMatchObject({ generatedAt: new Date(NOW).toISOString(), window: "24h", total: 3 });
    expect(r.groups.map((g) => g.key)).toEqual(["fatal", "many", "few"]);

    const lots = Array.from({ length: RUNTIME_ERROR_REPORT_CAP + 5 }, (_, i) => group({ key: `g${i}` }));
    const capped = runtimeErrorsReport(lots, NOW);
    expect(capped.total).toBe(RUNTIME_ERROR_REPORT_CAP + 5);
    expect(capped.groups).toHaveLength(RUNTIME_ERROR_REPORT_CAP);
  });
});

describe("the runtime-errors store", () => {
  // Whole seconds: the timestamp columns store seconds.
  const t = (minutesAgo: number) => NOW - minutesAgo * 60_000;

  it("upserts on the group key, merges the worst level, and a re-read adds nothing", async () => {
    const store = createLibsqlStorage(await freshDb()).telemetry.runtimeErrors;
    const batch = [
      entry({ rowId: "a", timestampMs: t(30), path: "/api/posts/1" }),
      entry({ rowId: "b", timestampMs: t(20), path: "/api/posts/2" }),
    ];
    await store.save(batch, { nowMs: NOW });
    await store.save(batch, { nowMs: NOW });
    let [g, ...rest] = await store.load();
    expect(rest).toEqual([]);
    expect(g).toMatchObject({
      project: "site-production",
      path: "/api/posts/:id",
      message: "boom",
      level: "error",
      count: 2,
      firstSeen: new Date(t(30)).toISOString(),
      lastSeen: new Date(t(20)).toISOString(),
      sampleRowId: "b",
    });

    // A later read of a NEW deployment adds to the same group and moves its sample.
    await store.save([entry({ rowId: "c", timestampMs: t(10), level: "fatal", deploymentId: "dpl_2" })], {
      nowMs: NOW,
    });
    // An older, lower-level line on the first deployment does not lower the level or the sample.
    await store.save([...batch, entry({ rowId: "z", timestampMs: t(15), level: "error" })], { nowMs: NOW });
    [g] = await store.load();
    expect(g).toMatchObject({
      count: 4,
      level: "fatal",
      deploymentId: "dpl_2",
      sampleRowId: "c",
      firstSeen: new Date(t(30)).toISOString(),
      lastSeen: new Date(t(10)).toISOString(),
    });
  });

  it("prunes groups past the 7-day retention, ignores stale lines, and filters by sinceMs", async () => {
    const store = createLibsqlStorage(await freshDb()).telemetry.runtimeErrors;
    const day = 24 * 60;
    await store.save([entry({ rowId: "a", timestampMs: t(6 * day), message: "aging" })], { nowMs: NOW });
    await store.save([entry({ rowId: "b", timestampMs: t(8 * day), message: "too old" })], { nowMs: NOW });
    expect((await store.load()).map((g) => g.message)).toEqual(["aging"]);

    await store.save([entry({ rowId: "c", timestampMs: t(5), message: "fresh" })], { nowMs: NOW + 2 * day * 60_000 });
    expect((await store.load()).map((g) => g.message)).toEqual(["fresh"]);
    expect(await store.load({ sinceMs: NOW })).toEqual([]);

    const report = await loadRuntimeErrorsReport(store, NOW);
    expect(report.total).toBe(1);
    expect(report.groups[0]?.message).toBe("fresh");
  });
});

// --- the fetcher, against a fake Vercel -----------------------------------------------------

const ENV = { VERCEL_API_TOKEN: "tok", VERCEL_TEAM_ID: "team_1" };

interface FakeVercel {
  projects: unknown[];
  deployments?: Record<string, string | undefined>;
  logs: Record<string, { lines: unknown[]; open?: boolean } | number>;
}

function fakeVercel(v: FakeVercel) {
  const calls: string[] = [];
  const fetch = vi.fn(async (input: URL | string) => {
    const url = new URL(String(input));
    calls.push(url.pathname);
    if (url.pathname === "/v9/projects") return Response.json({ projects: v.projects, pagination: { next: null } });
    if (url.pathname === "/v6/deployments") {
      const uid = v.deployments?.[url.searchParams.get("projectId") ?? ""];
      return Response.json({ deployments: uid ? [{ uid }] : [] });
    }
    const m = /^\/v1\/projects\/([^/]+)\/deployments\/([^/]+)\/runtime-logs$/.exec(url.pathname);
    if (m) {
      const answer = v.logs[m[2]!];
      if (answer === undefined) return new Response("not found", { status: 404 });
      if (typeof answer === "number") return new Response("", { status: answer, headers: { "retry-after": "60" } });
      const body = answer.lines.map((l) => JSON.stringify(l) + "\n");
      return new Response(streamOf(body, !answer.open), { status: 200 });
    }
    return new Response("unexpected", { status: 500 });
  });
  vi.stubGlobal("fetch", fetch);
  return { fetch, calls };
}

const project = (id: string, name: string, production?: string) => ({
  id,
  name,
  targets: { production: { id: production ?? null, alias: [`${name}.example.com`] } },
});
const line = (rowId: string, over: Record<string, unknown> = {}) => ({
  rowId,
  timestampInMs: NOW - 1_000,
  level: "error",
  source: "serverless",
  requestMethod: "GET",
  requestPath: "/api/x",
  responseStatusCode: 500,
  message: "boom",
  ...over,
});

describe("vercelRuntimeFetcher", () => {
  beforeEach(() => _resetProviderCooldowns());
  afterEach(() => {
    vi.unstubAllGlobals();
    _resetProviderCooldowns();
  });

  it("asks nothing without a token", async () => {
    const { fetch } = fakeVercel({ projects: [], logs: {} });
    expect(await vercelRuntimeFetcher({}).fetch()).toEqual({ ok: true, items: [] });
    expect(fetch).not.toHaveBeenCalled();
  });

  it("reads each production project's current deployment and keeps only errors and 5xx", async () => {
    const { calls } = fakeVercel({
      projects: [project("p1", "a-production", "dpl_a"), project("p2", "b-production"), project("p3", "a-staging", "dpl_s")],
      deployments: { p2: "dpl_b" },
      logs: {
        dpl_a: { lines: [line("1"), line("2", { level: "info", responseStatusCode: 200 })] },
        dpl_b: { lines: [line("3", { level: "info", responseStatusCode: 503 })], open: true },
      },
    });
    const res = await vercelRuntimeFetcher(ENV, { deploymentBudgetMs: 50 }).fetch();
    expect(res.ok).toBe(true);
    expect(res.complete).toBe(true);
    expect(res.items.map((e) => [e.project, e.deploymentId, e.rowId, e.status])).toEqual([
      ["a-production", "dpl_a", "1", 500],
      ["b-production", "dpl_b", "3", 503],
    ]);
    expect(res.items[0]?.domain).toBe("a-production.example.com");
    // The staging project is never read.
    expect(calls.some((p) => p.includes("dpl_s"))).toBe(false);
  });

  it("stays ok with one project failing, and is not complete", async () => {
    const errors = vi.spyOn(console, "error").mockImplementation(() => {});
    fakeVercel({
      projects: [project("p1", "a-production", "dpl_a"), project("p2", "b-production", "dpl_b")],
      logs: { dpl_a: { lines: [line("1")] }, dpl_b: 500 },
    });
    const res = await vercelRuntimeFetcher(ENV).fetch();
    expect(res).toMatchObject({ ok: true, complete: false });
    expect(res.items).toHaveLength(1);
    errors.mockRestore();
  });

  it("fails when every project fails", async () => {
    const errors = vi.spyOn(console, "error").mockImplementation(() => {});
    fakeVercel({ projects: [project("p1", "a-production", "dpl_a")], logs: { dpl_a: 500 } });
    expect(await vercelRuntimeFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    errors.mockRestore();
  });

  it("fails on a 429, records the shared cooldown, and then asks nothing while it lasts", async () => {
    const errors = vi.spyOn(console, "error").mockImplementation(() => {});
    const { fetch } = fakeVercel({ projects: [project("p1", "a-production", "dpl_a")], logs: { dpl_a: 429 } });
    expect(await vercelRuntimeFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    expect(rateLimitedUntil("vercel")).not.toBeNull();

    fetch.mockClear();
    expect(await vercelRuntimeFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    expect(fetch).not.toHaveBeenCalled();
    errors.mockRestore();
  });

  it("ends at the overall budget without failing", async () => {
    fakeVercel({
      projects: [project("p1", "a-production", "dpl_a")],
      logs: { dpl_a: { lines: [line("1")], open: true } },
    });
    const started = Date.now();
    const res = await vercelRuntimeFetcher(ENV, { deploymentBudgetMs: 10_000, overallBudgetMs: 50 }).fetch();
    expect(Date.now() - started).toBeLessThan(5_000);
    expect(res).toMatchObject({ ok: true, complete: true });
    expect(res.items.map((e) => e.rowId)).toEqual(["1"]);
  });
});

// --- collectTelemetry + the integrations check ----------------------------------------------

describe("Vercel runtime logs in the cycle and the self-check", () => {
  const saved: Record<string, string | undefined> = {};
  const KEYS = [
    "VERCEL_API_TOKEN",
    "VERCEL_TEAM_ID",
    "GLITCHTIP_URL",
    "GLITCHTIP_API_TOKEN",
    "GLITCHTIP_ORG",
    "POSTHOG_HOST",
    "POSTHOG_API_KEY",
    "POSTHOG_PROJECT_ID",
    "CLOUDFLARE_API_TOKEN",
    "CLOUDFLARE_ACCOUNT_ID",
    "RAILWAY_API_TOKEN",
  ];
  beforeEach(() => {
    for (const k of KEYS) {
      saved[k] = process.env[k];
      delete process.env[k];
    }
    _resetSelfCheckStability();
    _resetProviderCooldowns();
    // The Vercel deploy probe in the self-check: answer it, never the network.
    vi.stubGlobal("fetch", vi.fn(async () => Response.json({ projects: [] })));
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    for (const k of KEYS) {
      if (saved[k] === undefined) delete process.env[k];
      else process.env[k] = saved[k];
    }
  });

  const fixed = (result: Awaited<ReturnType<Fetcher<RuntimeLogEntry>["fetch"]>>): Fetcher<RuntimeLogEntry> => ({
    fetch: async () => result,
  });
  const runtimeCheck = async (storage: ReturnType<typeof createLibsqlStorage>) =>
    (await runIntegrationsCheck(storage, testConfig())).checks.find((c) => c.id === "vercel-runtime");

  it("is a missing-env warning without a token, and records the feature as off", async () => {
    const storage = createLibsqlStorage(await freshDb());
    const fetcher = vi.fn(async () => ({ ok: true as const, items: [] }));
    await collectTelemetry(storage, testConfig(), { runtimeErrors: { fetch: fetcher } });
    expect(fetcher).not.toHaveBeenCalled();
    const fact = (await storage.board.readPlatformFacts()).find((p) => p.source === "vercel-runtime");
    expect(fact).toMatchObject({ configured: false });
    expect(await runtimeCheck(storage)).toMatchObject({ configured: false, state: "warn" });
  });

  it("is pending before the first read, ok after one, and red after two failed reads in a row", async () => {
    process.env.VERCEL_API_TOKEN = "tok";
    const storage = createLibsqlStorage(await freshDb());
    expect(await runtimeCheck(storage)).toMatchObject({ state: "warn", detail: "first runtime-log read pending" });

    const now = Date.now();
    await collectTelemetry(storage, testConfig(), {
      runtimeErrors: fixed({ ok: true, items: [entry({ timestampMs: now - 60_000 })], complete: true }),
    });
    const ok = await runtimeCheck(storage);
    expect(ok).toMatchObject({ configured: true, ok: true, state: "ok" });
    expect(ok?.detail).toMatch(/1 runtime error group in the last 24h$/);

    const failing = fixed({ ok: false, items: [] });
    await collectTelemetry(storage, testConfig(), { runtimeErrors: failing });
    expect(await runtimeCheck(storage)).toMatchObject({ state: "warn", ok: false });
    await collectTelemetry(storage, testConfig(), { runtimeErrors: failing });
    const red = await runtimeCheck(storage);
    expect(red).toMatchObject({ state: "error", ok: false });
    expect(red?.detail).toMatch(/\(2 in a row\)$/);
    // The groups read before the outage are kept.
    expect(await storage.telemetry.runtimeErrors.load()).toHaveLength(1);
  });

  it("survives a fetcher that throws", async () => {
    process.env.VERCEL_API_TOKEN = "tok";
    const errors = vi.spyOn(console, "error").mockImplementation(() => {});
    const storage = createLibsqlStorage(await freshDb());
    await collectTelemetry(storage, testConfig(), {
      runtimeErrors: {
        fetch: async () => {
          throw new Error("kaboom");
        },
      },
    });
    const fact = (await storage.board.readPlatformFacts()).find((p) => p.source === "vercel-runtime");
    expect(fact).toMatchObject({ configured: true, ok: false });
    errors.mockRestore();
  });
});
