import { describe, it, expect } from "vitest";
import {
  deployUnconfirmed,
  effectiveDeployStatus,
  liveFreshness,
  selectStaleMonitors,
  snapshotFreshness,
  snapshotStaleMs,
  staleMonitorsView,
  SNAPSHOT_STALE_FLOOR_MS,
  STALE_MONITOR_MS,
  UNCONFIRMED_AFTER_MS,
  unconfirmedWindowMs,
} from "../src/monitor/live-view";
import type { LiveServiceDTO } from "../src/monitor/live-types";
import type { DeploymentDTO } from "../src/monitor/types";

// Ported from status-web's snapshot-staleness / stale-monitors / row-model tests when the
// rules moved here: the dashboard now reads these verdicts off `/live` instead of judging.

const GEN = "2024-06-01T12:00:00.000Z";
const gen = Date.parse(GEN);
const lag = (ms: number): string => new Date(gen - ms).toISOString();

describe("snapshotStaleMs", () => {
  it("floors at 5min when interval is small/absent", () => {
    expect(snapshotStaleMs(undefined)).toBe(SNAPSHOT_STALE_FLOOR_MS);
    expect(snapshotStaleMs(null)).toBe(SNAPSHOT_STALE_FLOOR_MS);
    expect(snapshotStaleMs(60_000)).toBe(SNAPSHOT_STALE_FLOOR_MS);
  });
  it("scales to 5x the interval once past the floor", () => {
    expect(snapshotStaleMs(120_000)).toBe(600_000);
  });
});

describe("snapshotFreshness", () => {
  it("is fresh when there is no probe yet, or no read clock", () => {
    expect(snapshotFreshness(null, GEN, 60_000)).toBe("fresh");
    expect(snapshotFreshness(undefined, GEN)).toBe("fresh");
    expect(snapshotFreshness(lag(10 * 60_000), null)).toBe("fresh");
  });
  it("is fresh within the window, stale past it, very-stale past 3x", () => {
    expect(snapshotFreshness(lag(4 * 60_000), GEN, 60_000)).toBe("fresh");
    expect(snapshotFreshness(lag(6 * 60_000), GEN, 60_000)).toBe("stale");
    expect(snapshotFreshness(lag(16 * 60_000), GEN, 60_000)).toBe("very-stale");
  });
  it("scales the window with the probe interval", () => {
    expect(snapshotFreshness(lag(6 * 60_000), GEN, 120_000)).toBe("fresh");
    expect(snapshotFreshness(lag(11 * 60_000), GEN, 120_000)).toBe("stale");
  });
  it("is NaN-safe and ignores a negative lag", () => {
    expect(snapshotFreshness("not-a-date", GEN, 60_000)).toBe("fresh");
    expect(snapshotFreshness(lag(20 * 60_000), "not-a-date", 60_000)).toBe("fresh");
    expect(snapshotFreshness(new Date(gen + 30_000).toISOString(), GEN, 60_000)).toBe("fresh");
  });
  it("liveFreshness echoes the data clock it judged", () => {
    expect(liveFreshness(lag(6 * 60_000), GEN, 60_000)).toEqual({ state: "stale", asOf: lag(6 * 60_000) });
    expect(liveFreshness(null, GEN, 60_000)).toEqual({ state: "fresh", asOf: null });
  });
});

function deploy(over: Partial<DeploymentDTO>): DeploymentDTO {
  return {
    id: "d1",
    platform: "vercel",
    projectName: "p",
    providerProjectId: null,
    status: "building",
    buildPhase: "building",
    deployPhase: "none",
    environment: "production",
    tier: "production",
    commitHash: null,
    commitMessage: null,
    branch: null,
    commitRepo: null,
    url: null,
    errorText: null,
    liveHost: null,
    createdAt: "2026-06-04T17:00:00.000Z",
    phaseConfirmedAt: "2026-06-04T18:00:00.000Z",
    ...over,
  } as DeploymentDTO;
}

describe("unconfirmedWindowMs", () => {
  it("is the floor when the probe is fast or unknown, and 5x the interval when slow", () => {
    expect(unconfirmedWindowMs(undefined)).toBe(UNCONFIRMED_AFTER_MS);
    expect(unconfirmedWindowMs(60_000)).toBe(UNCONFIRMED_AFTER_MS);
    expect(unconfirmedWindowMs(5 * 60_000)).toBe(25 * 60_000);
  });
});

describe("deployUnconfirmed / effectiveDeployStatus", () => {
  const confirmed = "2026-06-04T18:00:00.000Z";
  const confirmedMs = Date.parse(confirmed);

  it("demotes an in-flight deploy whose phase outlived its confirmation", () => {
    const d = deploy({ phaseConfirmedAt: confirmed });
    expect(deployUnconfirmed(d, confirmedMs + UNCONFIRMED_AFTER_MS - 1)).toBe(false);
    expect(deployUnconfirmed(d, confirmedMs + UNCONFIRMED_AFTER_MS + 1)).toBe(true);
    expect(effectiveDeployStatus(d, confirmedMs + UNCONFIRMED_AFTER_MS - 1)).toBe("building");
    expect(effectiveDeployStatus(d, confirmedMs + UNCONFIRMED_AFTER_MS + 1)).toBe("unknown");
  });
  it("demotes a queued deploy the same way", () => {
    expect(effectiveDeployStatus(deploy({ status: "queued" }), confirmedMs + UNCONFIRMED_AFTER_MS + 1)).toBe("unknown");
  });
  it("never demotes a settled deploy, however old", () => {
    const d = deploy({ status: "success", buildPhase: "built", deployPhase: "deployed" });
    expect(deployUnconfirmed(d, confirmedMs + 30 * 86_400_000)).toBe(false);
    expect(effectiveDeployStatus(d, confirmedMs + 30 * 86_400_000)).toBe("success");
  });
  it("fails CLOSED on an unparseable clock, and falls back to createdAt", () => {
    expect(deployUnconfirmed(deploy({ phaseConfirmedAt: "", createdAt: confirmed }), confirmedMs + UNCONFIRMED_AFTER_MS + 1)).toBe(true);
    expect(deployUnconfirmed(deploy({ phaseConfirmedAt: "", createdAt: confirmed }), confirmedMs)).toBe(false);
    expect(deployUnconfirmed(deploy({ phaseConfirmedAt: "", createdAt: "nope" }), confirmedMs)).toBe(true);
  });
  it("honors the cadence-scaled window over the floor", () => {
    const d = deploy({ phaseConfirmedAt: confirmed });
    const slow = 6 * 60_000;
    expect(deployUnconfirmed(d, confirmedMs + UNCONFIRMED_AFTER_MS + 1, slow)).toBe(false);
    expect(deployUnconfirmed(d, confirmedMs + 30 * 60_000 + 1, slow)).toBe(true);
  });
});

const NOW = Date.parse("2026-06-26T00:00:00.000Z");
const daysAgo = (n: number): string => new Date(NOW - n * 86_400_000).toISOString();

function svc(over: Partial<LiveServiceDTO> = {}): LiveServiceDTO {
  return {
    slug: "ep1",
    group: "g",
    name: "Site",
    url: "https://site.example.com",
    environment: "production",
    platform: null,
    deployProject: null,
    status: "down",
    responseTimeMs: null,
    statusCode: null,
    error: "HTTP 500",
    lastCheckedAt: null,
    dnsOk: true,
    downSince: daysAgo(30),
    ...over,
  } as LiveServiceDTO;
}

describe("selectStaleMonitors", () => {
  it("includes a down endpoint past the threshold", () => {
    const res = selectStaleMonitors([svc()], NOW);
    expect(res).toHaveLength(1);
    expect(res[0]).toMatchObject({ slug: "ep1", dnsOk: true, detail: "HTTP 500" });
    expect(res[0]!.ageMs).toBe(30 * 86_400_000);
  });
  it("selects the same rows whether or not the hosts resolve; DNS decides nothing", () => {
    const rows = (dnsOk: boolean): string[] =>
      selectStaleMonitors(
        [
          svc({ slug: "gone", dnsOk, error: "DNS: does not resolve", downSince: daysAgo(90) }),
          svc({ slug: "also-gone", dnsOk, downSince: daysAgo(9) }),
          svc({ slug: "alive", status: "healthy", downSince: null }),
        ],
        NOW,
      ).map((r) => r.slug);
    expect(rows(false)).toEqual(["gone", "also-gone"]);
    expect(rows(true)).toEqual(rows(false));
    expect(selectStaleMonitors([svc({ dnsOk: false })], NOW)[0]!.dnsOk).toBe(false);
  });
  it("excludes short outages, non-down rows, unknown and malformed onsets", () => {
    expect(selectStaleMonitors([svc({ downSince: daysAgo(2) })], NOW)).toEqual([]);
    expect(
      selectStaleMonitors(
        [
          svc({ slug: "h", status: "healthy", downSince: null }),
          svc({ slug: "d", status: "degraded", downSince: daysAgo(40) }),
          svc({ slug: "x", status: "down", downSince: null }),
          svc({ slug: "n", downSince: "not-a-date" }),
        ],
        NOW,
      ),
    ).toEqual([]);
  });
  it("derives the detail from statusCode when there is no error string", () => {
    expect(selectStaleMonitors([svc({ error: null, statusCode: 503 })], NOW)[0]!.detail).toBe("HTTP 503");
  });
  it("sorts longest-down first and uses an inclusive 7-day threshold", () => {
    const res = selectStaleMonitors([svc({ slug: "newer", downSince: daysAgo(8) }), svc({ slug: "older", downSince: daysAgo(90) })], NOW);
    expect(res.map((r) => r.slug)).toEqual(["older", "newer"]);
    expect(STALE_MONITOR_MS).toBe(7 * 24 * 60 * 60 * 1000);
    expect(selectStaleMonitors([svc({ downSince: daysAgo(7) })], NOW)).toHaveLength(1);
    expect(selectStaleMonitors([svc({ downSince: daysAgo(6) })], NOW)).toHaveLength(0);
  });
  it("staleMonitorsView names the threshold in days", () => {
    expect(staleMonitorsView([svc()], NOW)).toMatchObject({ thresholdDays: 7, monitors: [{ slug: "ep1" }] });
  });
});
