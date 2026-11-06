import { describe, it, expect } from "vitest";
import {
  BOARD_STALE_MS,
  BOARD_POLL_INTERVAL_MS,
  BOARD_DATA_STALE_CYCLES,
  boardDataStaleMs,
  boardDataFreshness,
  boardFreshness,
  isUnresolvedActivity,
  isRunningActivity,
  isBuildInFlight,
  withAttention,
  deployCounts,
  boardScope,
  inScope,
  parseEnvironments,
} from "../src/board/view";
import { SNAPSHOT_STALE_FLOOR_MS } from "../src/monitor/live-view";
import type { ActivityRow, EndpointFact, Problem, RosterEntry } from "../src/board/types";

// The board's published judgements (`GET /board`'s `freshness`, `deployCounts`, `scope`
// and each activity row's `unresolved` / `running` / `buildInFlight`). These rules used to
// run in status-web (`board-staleness.ts`, `overview.ts`); the cases below are those
// tests, ported onto the one server copy.

function row(o: Partial<ActivityRow> = {}): ActivityRow {
  return {
    id: "r", kind: "deploy", step: "build", source: "vercel", tone: "bad", verb: "build failed",
    target: "vercel:site", name: "site", environment: "production", detail: null, sourceUrl: null,
    liveUrl: null, commitHash: null, commitMessage: null, commitRepo: null, branch: null,
    errorText: null, at: "2026-10-30T12:00:00.000Z", ...o,
  };
}

function problem(o: Partial<Problem> = {}): Problem {
  return {
    target: "vercel:site", source: "vercel", name: "site", environment: "production", severity: "major",
    state: "failed", statusCode: null, detail: null, sourceUrl: null, liveUrl: null,
    commitHash: null, commitMessage: null, commitRepo: null, branch: null, errorText: null,
    since: "2026-10-30T12:00:00.000Z", ...o,
  };
}

describe("boardFreshness — the read's own deadline", () => {
  const now = Date.parse("2026-08-02T12:00:00.000Z");

  it("stamps staleAt three poll cycles after the derivation clock", () => {
    const f = boardFreshness(now - 1000, now, 60_000);
    expect(Date.parse(f.staleAt) - now).toBe(BOARD_STALE_MS);
    expect(BOARD_STALE_MS).toBe(3 * BOARD_POLL_INTERVAL_MS);
    expect(f.pollIntervalMs).toBe(BOARD_POLL_INTERVAL_MS);
    expect(f.state).toBe("current");
  });

  it("carries the data-clock verdict beside the deadline", () => {
    expect(boardFreshness(null, now, 60_000).state).toBe("no-data");
    expect(boardFreshness(now - boardDataStaleMs(60_000) - 1, now, 60_000).state).toBe("frozen");
  });
});

// A wedged monitor keeps re-stamping `generatedAt`, so every case below pairs a perfectly
// fresh derivation clock with a data clock that isn't.
describe("boardDataFreshness", () => {
  const genMs = Date.parse("2026-08-02T12:00:00.000Z");
  const windowMs = boardDataStaleMs();

  it("a board derived from observations it just made is current", () => {
    expect(boardDataFreshness(genMs - 1000, genMs)).toBe("current");
  });

  it("data exactly at the threshold is not yet stale", () => {
    expect(boardDataFreshness(genMs - windowMs, genMs)).toBe("current");
  });

  it("data past the threshold is frozen even though the board itself is brand new", () => {
    expect(boardDataFreshness(genMs - windowMs - 1, genMs)).toBe("frozen");
  });

  it("a non-finite derivation clock fails CLOSED", () => {
    expect(boardDataFreshness(genMs, Number.NaN)).toBe("frozen");
  });

  it("a data clock slightly AHEAD of the derivation clock is clock jitter, not a wedge", () => {
    expect(boardDataFreshness(genMs + 500, genMs)).toBe("current");
  });

  it("a board resting on NO observations reads no-data, NOT frozen", () => {
    expect(boardDataFreshness(null, genMs)).toBe("no-data");
    expect(boardDataFreshness(null, genMs, 3600_000)).toBe("no-data");
    expect(boardDataFreshness(null, Number.NaN)).toBe("no-data");
  });
});

describe("boardDataStaleMs", () => {
  const genMs = Date.parse("2026-08-02T12:00:00.000Z");
  /** The full-sync cadence that rewrites the platform-sample heartbeat (`config.ts`). */
  const platformSampleCadenceMs = (probeIntervalMs: number): number => Math.max(300_000, probeIntervalMs * 5);

  it("scales with the probe interval instead of pinning a fixed 5 minutes", () => {
    const hourly = 3600_000;
    expect(boardDataStaleMs(hourly)).toBeGreaterThan(10 * 60_000);
    expect(boardDataFreshness(genMs - 10 * 60_000, genMs, hourly)).toBe("current");
    expect(boardDataFreshness(genMs - 10 * 60_000 - 1, genMs, 60_000)).toBe("frozen");
  });

  it("is STRICTLY greater than the platform-sample cadence at every probe interval", () => {
    for (const probeIntervalMs of [1_000, 15_000, 60_000, 300_000, 3600_000]) {
      expect(boardDataStaleMs(probeIntervalMs)).toBeGreaterThan(platformSampleCadenceMs(probeIntervalMs));
    }
    expect(boardDataFreshness(genMs - platformSampleCadenceMs(60_000), genMs, 60_000)).toBe("current");
  });

  it("an unknown cadence falls back to the widest window, never a narrower one", () => {
    expect(boardDataStaleMs()).toBe(SNAPSHOT_STALE_FLOOR_MS * BOARD_DATA_STALE_CYCLES);
    expect(boardDataStaleMs(null)).toBe(boardDataStaleMs());
    expect(boardDataStaleMs(0)).toBe(boardDataStaleMs());
  });

  it("needs at least two cycles of headroom for the tail-of-cycle rule to hold", () => {
    expect(BOARD_DATA_STALE_CYCLES).toBeGreaterThanOrEqual(2);
  });
});

describe("isUnresolvedActivity — the 'in progress or failed only' rule", () => {
  it("keeps an in-flight build or deploy row with no problem at all", () => {
    expect(isUnresolvedActivity(row({ tone: "progress", verb: "building" }), [])).toBe(true);
    expect(isUnresolvedActivity(row({ step: "deploy", tone: "progress", verb: "deploying" }), [])).toBe(true);
  });

  it("drops finished, canceled and unknown rows", () => {
    for (const tone of ["good", "neutral", "stale"] as const) {
      expect(isUnresolvedActivity(row({ tone }), [problem()])).toBe(false);
    }
  });

  it("keeps a failure only while its target is still a problem", () => {
    expect(isUnresolvedActivity(row(), [problem()])).toBe(true);
    expect(isUnresolvedActivity(row(), [])).toBe(false);
    expect(isUnresolvedActivity(row(), [problem({ target: "vercel:other" })])).toBe(false);
  });

  it("drops a failure older than the open problem's onset — an earlier, recovered run", () => {
    const p = problem({ since: "2026-10-30T13:00:00.000Z" });
    expect(isUnresolvedActivity(row({ at: "2026-10-30T12:00:00.000Z" }), [p])).toBe(false);
    expect(isUnresolvedActivity(row({ at: "2026-10-30T13:05:00.000Z" }), [p])).toBe(true);
  });

  it("drops issue rows — they are not builds, and the Problems list already carries them", () => {
    const opened = row({ kind: "probe", step: null, source: "glitchtip", target: "gt-1", verb: "app errors" });
    const minor = { ...opened, tone: "progress" as const };
    const live = [problem({ target: "gt-1", source: "glitchtip" })];
    expect(isUnresolvedActivity(opened, [])).toBe(false);
    expect(isUnresolvedActivity(minor, [])).toBe(false);
    expect(isUnresolvedActivity(opened, live)).toBe(false);
    expect(isUnresolvedActivity(minor, live)).toBe(false);
  });
});

describe("isRunningActivity — a build or deploy that has a slot and is running", () => {
  const building = row({ tone: "progress", verb: "building" });

  it("is true for a building build and a deploying deploy", () => {
    expect(isRunningActivity(building)).toBe(true);
    expect(isRunningActivity({ ...building, step: "deploy", verb: "deploying" })).toBe(true);
  });

  it("is false for a queued build — waiting is not running", () => {
    expect(isRunningActivity({ ...building, verb: "queued" })).toBe(false);
  });

  it("is false for finished rows and for probe rows", () => {
    expect(isRunningActivity(row({ tone: "bad", verb: "build failed" }))).toBe(false);
    expect(isRunningActivity(row({ tone: "good", verb: "deployed" }))).toBe(false);
    expect(isRunningActivity({ ...building, kind: "probe", step: null })).toBe(false);
  });
});

describe("isBuildInFlight — what the build-progress bar counts", () => {
  it("counts queued and building deploy-kind builds", () => {
    expect(isBuildInFlight(row({ tone: "progress", verb: "queued" }))).toBe(true);
    expect(isBuildInFlight(row({ tone: "progress", verb: "building" }))).toBe(true);
  });

  it("does not count deploy steps, finished builds or probe rows", () => {
    expect(isBuildInFlight(row({ step: "deploy", tone: "progress", verb: "deploying" }))).toBe(false);
    expect(isBuildInFlight(row({ tone: "good", verb: "built" }))).toBe(false);
    expect(isBuildInFlight(row({ kind: "probe", step: null, tone: "progress" }))).toBe(false);
  });
});

describe("withAttention", () => {
  it("stamps every row with all three judgements against the given problems", () => {
    const rows = [row(), row({ id: "q", tone: "progress", verb: "queued" }), row({ id: "g", tone: "good", verb: "built" })];
    const out = withAttention(rows, [problem()]);
    expect(out.map((r) => [r.id, r.unresolved, r.running, r.buildInFlight])).toEqual([
      ["r", true, false, false],
      ["q", true, false, true],
      ["g", false, false, false],
    ]);
    // Pure: the input rows are not mutated.
    expect(rows[0]!.unresolved).toBeUndefined();
  });
});

describe("deployCounts — the stats strip's figures over the activity window", () => {
  const since = Date.parse("2026-10-30T00:00:00.000Z");

  it("counts builds, deploys and failures of either step inside the window", () => {
    const counts = deployCounts([
      row({ tone: "good", verb: "built" }),
      row({ id: "b", tone: "bad" }),
      row({ id: "d", step: "deploy", tone: "bad", verb: "deploy failed" }),
      row({ id: "e", step: "deploy", tone: "good", verb: "deployed" }),
    ], since);
    expect(counts).toEqual({ builds: 2, deploys: 2, failures: 2 });
  });

  it("ignores rows before the window and non-deploy rows", () => {
    const counts = deployCounts([
      row({ at: "2026-10-29T23:59:59.999Z" }),
      row({ kind: "probe", step: null, tone: "bad" }),
      row({ kind: "platform", step: null, tone: "bad" }),
    ], since);
    expect(counts).toEqual({ builds: 0, deploys: 0, failures: 0 });
  });
});

describe("boardScope — the headline over the chosen environments", () => {
  function entry(endpointId: string, environment: string | null, isActive = true): RosterEntry {
    return { endpointId, environment, isActive } as RosterEntry;
  }
  function fact(endpointId: string, status: string): EndpointFact {
    return { endpointId, status } as EndpointFact;
  }
  const facts = {
    roster: [entry("p1", "production"), entry("p2", "production"), entry("s1", "staging"), entry("x", null), entry("off", "production", false)],
    endpoints: [fact("p1", "healthy"), fact("p2", "down"), fact("s1", "healthy"), fact("x", "healthy"), fact("off", "healthy")],
  };
  const problems = [
    problem({ target: "a", environment: "production", severity: "major" }),
    problem({ target: "b", environment: "staging", severity: "critical" }),
    problem({ target: "c", environment: null, severity: "minor" }),
  ];

  it("null environments is every environment", () => {
    expect(boardScope(facts, problems, null)).toEqual({
      environments: null,
      indicator: "outage",
      problemCount: 3,
      endpoints: { total: 4, healthy: 3 },
    });
  });

  it("scopes problems and endpoints, keeping environment-less rows in every scope", () => {
    expect(boardScope(facts, problems, ["production"])).toEqual({
      environments: ["production"],
      indicator: "degraded",
      problemCount: 2,
      endpoints: { total: 3, healthy: 2 },
    });
  });

  it("an empty scope keeps only the environment-less rows", () => {
    const s = boardScope(facts, problems, []);
    expect(s.problemCount).toBe(1);
    expect(s.endpoints).toEqual({ total: 1, healthy: 1 });
  });

  it("an endpoint never probed counts in total and never in healthy", () => {
    const s = boardScope({ roster: [entry("new", "production")], endpoints: [] }, [], null);
    expect(s.endpoints).toEqual({ total: 1, healthy: 0 });
    expect(s.indicator).toBe("operational");
  });

  it("inScope never hides an environment-less row", () => {
    expect(inScope([], null)).toBe(true);
    expect(inScope([], "")).toBe(true);
    expect(inScope(["staging"], "production")).toBe(false);
    expect(inScope(null, "production")).toBe(true);
  });
});

describe("parseEnvironments", () => {
  it("absent is every environment, empty is none, blanks are dropped", () => {
    expect(parseEnvironments(undefined)).toBeNull();
    expect(parseEnvironments("")).toEqual([]);
    expect(parseEnvironments("production, staging,,")).toEqual(["production", "staging"]);
  });
});
