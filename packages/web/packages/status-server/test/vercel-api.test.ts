import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { _resetProviderCooldowns, noteRateLimited, rateLimitedUntil } from "@adh-sdk/deploy-platform/cooldown";
import {
  VERCEL_API,
  VercelHttpError,
  VercelRateLimited,
  isNonProductionHost,
  isProductionProject,
  listProjects,
  productionDomain,
  vercelGet,
  vercelRequest,
  type ListedProject,
} from "../src/telemetry/vercel-api";

// One test per row of the recipe's conformance-test-vectors.md (status/service/telemetry/vercel-api).

const ENV = { VERCEL_API_TOKEN: "tok", VERCEL_TEAM_ID: "team_1" };

interface Seen {
  url: URL;
  init: { method: string; headers: Record<string, string>; body?: string; signal: AbortSignal };
}

type Answer = { status?: number; body?: unknown; text?: string; headers?: Record<string, string> };

/** Stub `fetch` with a sequence of answers, the last repeating. Returns every request seen. */
function stubFetch(answers: Answer[]): Seen[] {
  const seen: Seen[] = [];
  vi.stubGlobal("fetch", async (url: URL, init: Seen["init"]): Promise<Response> => {
    const a = answers[Math.min(seen.length, answers.length - 1)]!;
    seen.push({ url, init });
    const status = a.status ?? 200;
    return new Response(a.text ?? JSON.stringify(a.body ?? {}), { status, headers: a.headers });
  });
  return seen;
}

/** A `fetch` that never answers; it rejects with the signal's reason when the signal aborts. */
function stubHangingFetch(): void {
  vi.stubGlobal(
    "fetch",
    (_url: URL, init: Seen["init"]) =>
      new Promise<Response>((_resolve, reject) => {
        init.signal.addEventListener("abort", () => reject(init.signal.reason));
      }),
  );
}

const proj = (over: Partial<ListedProject> = {}): ListedProject => ({ id: "p", name: "x", ...over });

beforeEach(() => {
  _resetProviderCooldowns();
});

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  _resetProviderCooldowns();
});

describe("vercel-api conformance vectors", () => {
  it("vercel-api-001 productionDomain is the first alias that is not a vercel.app one", () => {
    expect(productionDomain(proj({ targets: { production: { alias: ["x.vercel.app", "x.com"] } } }))).toBe("x.com");
    expect(productionDomain(proj({ targets: { production: { alias: ["x.vercel.app"] } } }))).toBeNull();
  });

  it("vercel-api-002 a project is production unless its name ends in staging or testing", () => {
    expect(
      ["site-production", "site-staging", "site-testing", "testing-production"].map((name) => isProductionProject(proj({ name }))),
    ).toEqual([true, false, false, true]);
  });

  it("vercel-api-003 a staging host makes the project non-production", () => {
    expect(isProductionProject(proj({ name: "x", targets: { production: { alias: ["staging.x.com"] } } }))).toBe(false);
  });

  it("vercel-api-004 a 429 fails the read, records the cooldown, and later reads ask nothing", async () => {
    const seen = stubFetch([{ status: 429 }]);
    await expect(listProjects(ENV)).rejects.toBeInstanceOf(VercelRateLimited);
    expect(rateLimitedUntil("vercel")).not.toBeNull();
    expect(seen).toHaveLength(1);
    await expect(listProjects(ENV)).rejects.toBeInstanceOf(VercelRateLimited);
    expect(seen).toHaveLength(1);
  });

  it("vercel-api-005 the caller's deadline aborts a read that never answers", async () => {
    stubHangingFetch();
    const started = Date.now();
    await expect(listProjects(ENV, AbortSignal.timeout(50))).rejects.toBeDefined();
    expect(Date.now() - started).toBeLessThan(5_000);
  });

  it("vercel-api-006 a non-429 error status fails the read", async () => {
    stubFetch([{ status: 503, text: "down" }]);
    await expect(listProjects(ENV)).rejects.toMatchObject({ status: 503 });
  });

  it("vercel-api-007 listProjects continues with until and returns every page", async () => {
    const seen = stubFetch([
      { body: { projects: [{ id: "a" }], pagination: { next: 1700 } } },
      { body: { projects: [{ id: "b" }], pagination: { next: null } } },
    ]);
    const out = await listProjects(ENV);
    expect(seen).toHaveLength(2);
    expect(seen[0]!.url.searchParams.get("until")).toBeNull();
    expect(seen[1]!.url.searchParams.get("until")).toBe("1700");
    expect(seen[0]!.url.searchParams.get("limit")).toBe("100");
    expect(out.map((p) => p.id)).toEqual(["a", "b"]);
  });

  it("vercel-api-008 listProjects stops at 20 pages without an error", async () => {
    const seen = stubFetch([{ body: { projects: [{ id: "a" }], pagination: { next: 5 } } }]);
    const out = await listProjects(ENV);
    expect(seen).toHaveLength(20);
    expect(out).toHaveLength(20);
  });

  it("vercel-api-009 a json body makes a POST with a content type", async () => {
    const seen = stubFetch([{}]);
    await vercelRequest(ENV, "/v1/x", {}, undefined, { json: { a: 1 } });
    expect(seen[0]!.init.method).toBe("POST");
    expect(seen[0]!.init.body).toBe('{"a":1}');
    expect(seen[0]!.init.headers["Content-Type"]).toBe("application/json");
  });

  it("vercel-api-010 the team id and params become query parameters", async () => {
    const seen = stubFetch([{}]);
    await vercelRequest(ENV, "/v1/x", { limit: "5" });
    expect(seen[0]!.url.searchParams.get("teamId")).toBe("team_1");
    expect(seen[0]!.url.searchParams.get("limit")).toBe("5");
    expect(seen[0]!.url.origin).toBe(VERCEL_API);
    expect(seen[0]!.init.method).toBe("GET");
    expect(seen[0]!.init.body).toBeUndefined();
    expect(seen[0]!.init.headers.Authorization).toBe("Bearer tok");
  });

  it("vercel-api-011 an error status throws VercelHttpError with path, status and body", async () => {
    stubFetch([{ status: 500, text: "oops" }]);
    const err = await vercelRequest(ENV, "/v1/x", {}).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(VercelHttpError);
    expect(err).toMatchObject({ path: "/v1/x", status: 500, body: "oops", message: "Vercel /v1/x HTTP 500" });
  });

  it("vercel-api-012 isNonProductionHost matches staging and testing hosts in any case", () => {
    expect(isNonProductionHost("STAGING.x.com")).toBe(true);
    expect(isNonProductionHost("x.com")).toBe(false);
    expect(isNonProductionHost(null)).toBe(false);
  });

  it("vercel-api-013 the name test ignores case", () => {
    expect(isProductionProject(proj({ name: "Site-STAGING" }))).toBe(false);
  });

  it("vercel-api-014 vercelGet rejects on a body that is not JSON", async () => {
    stubFetch([{ text: "not json" }]);
    await expect(vercelGet(ENV, "/v1/x", {})).rejects.toBeDefined();
  });

  it("vercel-api-015 every call is bounded by AbortSignal.timeout(20,000), with or without a caller signal", async () => {
    // Vitest's fake timers do not drive AbortSignal.timeout, so the timeout signal is replaced
    // by one the test aborts itself, and the delay the source asked for is read from the spy.
    for (const withCaller of [false, true]) {
      stubHangingFetch();
      const timeout = new AbortController();
      const spy = vi.spyOn(AbortSignal, "timeout").mockReturnValue(timeout.signal);
      const caller = withCaller ? new AbortController().signal : undefined;
      let rejected: unknown;
      const pending = vercelRequest(ENV, "/v1/x", {}, caller).catch((e: unknown) => {
        rejected = e;
      });
      await Promise.resolve();
      expect(spy).toHaveBeenCalledWith(20_000);
      expect(rejected).toBeUndefined();
      timeout.abort(new DOMException("timed out", "TimeoutError"));
      await pending;
      expect((rejected as { name?: string }).name).toBe("TimeoutError");
      spy.mockRestore();
    }
  });

  it("vercel-api-016 a caller header replaces the one built from env", async () => {
    const seen = stubFetch([{}]);
    await vercelRequest(ENV, "/v1/x", {}, undefined, { headers: { Authorization: "Bearer other" } });
    expect(seen[0]!.init.headers.Authorization).toBe("Bearer other");
  });

  it("vercel-api-017 a teamId in params replaces the env one", async () => {
    const seen = stubFetch([{}]);
    await vercelRequest(ENV, "/v1/x", { teamId: "team_2" });
    expect(seen[0]!.url.searchParams.getAll("teamId")).toEqual(["team_2"]);
  });

  it("vercel-api-018 an active cooldown throws VercelRateLimited without calling fetch", async () => {
    const seen = stubFetch([{}]);
    noteRateLimited("vercel", "60");
    const until = rateLimitedUntil("vercel")!;
    const err = await vercelRequest(ENV, "/v1/x", {}).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(VercelRateLimited);
    expect((err as Error).message).toBe(`Vercel rate limited until ${new Date(until).toISOString()}`);
    expect(seen).toHaveLength(0);
  });

  it("vercel-api-019 an error on a later page rejects the whole listing", async () => {
    stubFetch([{ body: { projects: [{ id: "a" }], pagination: { next: 9 } } }, { status: 500, text: "x" }]);
    await expect(listProjects(ENV)).rejects.toBeInstanceOf(VercelHttpError);
  });
});
