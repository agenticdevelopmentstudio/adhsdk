import { beforeEach, describe, expect, it, vi } from "vitest";
import { rangeWindow } from "../src/telemetry/dashboard/ranges";
import {
  loadDimensions,
  loadPaths,
  loadSiteErrorDetail,
  loadSiteHealth,
  loadTraffic,
  loadVitals,
} from "../src/telemetry/dashboard/posthog-sections";
import { hogqlRows } from "../src/telemetry/fetchers/posthog";

// Every loader reaches PostHog through `hogqlRows` alone; stubbing it shows the query and the
// timeout each section asks for, with no transport underneath.
vi.mock("../src/telemetry/fetchers/posthog", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../src/telemetry/fetchers/posthog")>()),
  hogqlRows: vi.fn(),
}));

const ENV = { POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" };
const w = rangeWindow("7d", Date.parse("2026-11-04T15:30:20.000Z"));
const stub = vi.mocked(hogqlRows);

type Loader = (rows: unknown[][]) => Promise<unknown>;
const LOADERS: Record<string, Loader> = {
  traffic: () => loadTraffic(ENV, w),
  dimensions: () => loadDimensions(ENV, w),
  paths: () => loadPaths(ENV, w),
  vitals: () => loadVitals(ENV, w),
  health: () => loadSiteHealth(ENV, w),
  detail: () => loadSiteErrorDetail(ENV, w),
};

beforeEach(() => {
  stub.mockReset();
  stub.mockResolvedValue({ ok: true, rows: [] });
});

const queries = (): string[] => stub.mock.calls.map((c) => c[1]);

describe("PostHog section queries", () => {
  it("posthog-sections-016: no query selects all properties, and every interpolated value is a constant, a UTC time or a closed name", async () => {
    for (const load of Object.values(LOADERS)) await load([]);
    expect(queries().length).toBeGreaterThanOrEqual(Object.keys(LOADERS).length);
    for (const q of queries()) {
      expect(q).not.toMatch(/SELECT\s+properties(?![.\w])/i);
      expect(q).not.toMatch(/undefined|NaN|\[object|\$\{/);
      // Every time literal is the window's own start, in UTC.
      for (const t of q.match(/toDateTime\('[^']*'/g) ?? []) expect(t).toBe("toDateTime('2026-10-29 00:00:00'");
      // Every property read is a named property.
      for (const p of q.match(/properties\.[$\w]+/g) ?? []) {
        expect(p).toMatch(/^properties\.(\$host|\$session_id|\$device_type|\$browser|\$geoip_country_code|\$referring_domain|\$pathname|\$web_vitals_(LCP|INP|CLS|FCP)_value|status|duration_ms|error_name|feature|step|boundary|method|path)$/);
      }
    }
  });

  it("posthog-sections-020: loadPaths labels a blank host and path and keeps the rest", async () => {
    stub.mockResolvedValue({ ok: true, rows: [["", "", 3], ["a.com", "/x", 2]] });
    expect(await loadPaths(ENV, w)).toEqual([
      { host: "(unknown)", path: "/", pageviews: 3 },
      { host: "a.com", path: "/x", pageviews: 2 },
    ]);
  });

  it("posthog-sections-021: vitals and health end LIMIT 200; traffic, dimensions, paths and detail end LIMIT 5000", async () => {
    const limitOf = async (name: string): Promise<string[]> => {
      stub.mockClear();
      await LOADERS[name]!([]);
      return queries().map((q) => q.match(/LIMIT (\d+)$/)?.[1] ?? "none");
    };
    expect(await limitOf("vitals")).toEqual(["200"]);
    expect(await limitOf("health")).toEqual(["200"]);
    expect(await limitOf("traffic")).toEqual(["5000"]);
    expect(await limitOf("dimensions")).toEqual(["5000"]);
    expect(await limitOf("paths")).toEqual(["5000"]);
    expect(await limitOf("detail")).toEqual(["5000", "5000", "5000"]);
  });

  it("posthog-sections-022: every loader makes its calls through hogqlRows with the 45000 ms timeout", async () => {
    for (const load of Object.values(LOADERS)) await load([]);
    expect(stub).toHaveBeenCalled();
    for (const call of stub.mock.calls) {
      expect(call[0]).toBe(ENV);
      expect(call[2]).toBe(45_000);
    }
  });
});
