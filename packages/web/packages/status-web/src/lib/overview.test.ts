import { describe, it, expect } from "vitest";
import { INDICATOR_STATE, activityWindowLabel, headlineFor, stillUnresolved } from "./overview";
import type { ActivityRow } from "./board-types";

describe("activityWindowLabel — the caption for the window the SERVER chose", () => {
  const HOUR = 3_600_000;

  it("names the default 24h window", () => {
    expect(activityWindowLabel(0, 24 * HOUR)).toBe("24h");
  });

  it("switches to days once the window is at least two of them", () => {
    expect(activityWindowLabel(0, 7 * 24 * HOUR)).toBe("7d");
    // 47h is not a whole number of days, so it stays in hours rather than rounding to "2d"
    // and captioning the counts with a window nobody configured.
    expect(activityWindowLabel(0, 47 * HOUR)).toBe("47h");
  });

  it("never captions a sub-hour window as 0h", () => {
    expect(activityWindowLabel(0, 60_000)).toBe("1h");
  });
});

describe("stillUnresolved — a held row against the current board", () => {
  const SINCE = "2026-11-06T11:00:00.000Z";
  const row = (o: Partial<ActivityRow>): ActivityRow => ({
    id: "r", kind: "deploy", step: "build", source: "vercel", tone: "bad", verb: "build failed",
    target: "vercel|site|", name: "site", environment: "production", detail: null, sourceUrl: null,
    liveUrl: null, commitHash: null, commitMessage: null, commitRepo: null, branch: null,
    errorText: null, at: "2026-11-06T12:00:00.000Z", ...o,
  });
  const open = [{ target: "vercel|site|", since: SINCE }];

  it("keeps a failure while a problem the server named is still on the board", () => {
    expect(stillUnresolved(row({ unresolved: true, heldOpenBy: [SINCE] }), open)).toBe(true);
  });

  it("drops a failure once every problem the server named has cleared", () => {
    expect(stillUnresolved(row({ unresolved: true, heldOpenBy: [SINCE] }), [])).toBe(false);
    // A new run on the same target is a different problem: the old failure is history.
    const reopened = [{ target: "vercel|site|", since: "2026-11-06T13:00:00.000Z" }];
    expect(stillUnresolved(row({ unresolved: true, heldOpenBy: [SINCE] }), reopened)).toBe(false);
    // The same onset on another target is not the same problem.
    expect(stillUnresolved(row({ unresolved: true, heldOpenBy: [SINCE] }), [{ target: "vercel|other|", since: SINCE }])).toBe(false);
  });

  it("keeps the server's verdict for a row in flight, and from a backend without heldOpenBy", () => {
    expect(stillUnresolved(row({ tone: "progress", verb: "building", unresolved: true, heldOpenBy: [] }), [])).toBe(true);
    expect(stillUnresolved(row({ unresolved: true }), [])).toBe(true);
  });

  it("never revives a row the server judged resolved", () => {
    expect(stillUnresolved(row({ unresolved: false, heldOpenBy: [] }), open)).toBe(false);
    expect(stillUnresolved(row({}), open)).toBe(false);
  });
});

describe("overview conformance vectors", () => {
  const H = 3_600_000;
  const SINCE = "2026-11-06T11:00:00.000Z";
  const row = (o: Partial<ActivityRow>): ActivityRow => ({
    id: "r", kind: "deploy", step: "build", source: "vercel", tone: "bad", verb: "build failed",
    target: "vercel|site|", name: "site", environment: "production", detail: null, sourceUrl: null,
    liveUrl: null, commitHash: null, commitMessage: null, commitRepo: null, branch: null,
    errorText: null, at: "2026-11-06T12:00:00.000Z", ...o,
  });

  it("overview-001 the wire-indicator map has exactly three keys and the sign's values", () => {
    expect(Object.keys(INDICATOR_STATE).sort()).toEqual(["degraded", "operational", "outage"]);
    expect(INDICATOR_STATE.degraded).toBe("warn");
    expect(INDICATOR_STATE.operational).toBe("ok");
    expect(INDICATOR_STATE.outage).toBe("down");
  });

  it("overview-002 the caption names 24h, 7d and 47h", () => {
    expect(activityWindowLabel(0, 24 * H)).toBe("24h");
    expect(activityWindowLabel(0, 7 * 24 * H)).toBe("7d");
    expect(activityWindowLabel(0, 47 * H)).toBe("47h");
  });

  it("overview-003 a 60000 ms span is captioned 1h", () => {
    expect(activityWindowLabel(0, 60_000)).toBe("1h");
  });

  it("overview-004 whole days from 48h up, 24h stays hours", () => {
    expect(activityWindowLabel(0, 48 * H)).toBe("2d");
    expect(activityWindowLabel(0, 72 * H)).toBe("3d");
    expect(activityWindowLabel(0, 24 * H)).toBe("24h");
  });

  it("overview-005 a negative span is captioned 1h", () => {
    expect(activityWindowLabel(10 * H, 0)).toBe("1h");
  });

  it("overview-006 the ok headline ignores the count", () => {
    expect(headlineFor("ok", 5)).toBe("ALL SYSTEMS OPERATIONAL");
  });

  it("overview-007 the warn headline is singular for one and plural otherwise", () => {
    expect(headlineFor("warn", 1)).toBe("1 SERVICE NEEDS ATTENTION");
    expect(headlineFor("warn", 3)).toBe("3 SERVICES NEED ATTENTION");
  });

  it("overview-008 the down headline is singular for one and plural otherwise", () => {
    expect(headlineFor("down", 1)).toBe("1 PROBLEM");
    expect(headlineFor("down", 4)).toBe("4 PROBLEMS");
  });

  it("overview-009 a held row is unresolved while a named problem is on its target", () => {
    expect(stillUnresolved(row({ unresolved: true, heldOpenBy: [SINCE] }), [{ target: "vercel|site|", since: SINCE }])).toBe(true);
  });

  it("overview-010 a held row resolves with no problem, a different onset, or another target", () => {
    const held = row({ unresolved: true, heldOpenBy: [SINCE] });
    expect(stillUnresolved(held, [])).toBe(false);
    expect(stillUnresolved(held, [{ target: "vercel|site|", since: "2026-11-06T13:00:00.000Z" }])).toBe(false);
    expect(stillUnresolved(held, [{ target: "vercel|other|", since: SINCE }])).toBe(false);
  });

  it("overview-011 an in-flight row and a row without heldOpenBy keep the server's verdict", () => {
    expect(stillUnresolved(row({ tone: "progress", verb: "building", unresolved: true, heldOpenBy: [] }), [])).toBe(true);
    expect(stillUnresolved(row({ unresolved: true }), [])).toBe(true);
  });

  it("overview-012 a row the server judged resolved is never revived", () => {
    const match = [{ target: "vercel|site|", since: SINCE }];
    expect(stillUnresolved(row({ unresolved: false, heldOpenBy: [] }), match)).toBe(false);
    expect(stillUnresolved(row({}), match)).toBe(false);
  });

  it("overview-013 the operations are pure and do not throw", () => {
    const problems = Object.freeze([Object.freeze({ target: "vercel|site|", since: SINCE })]);
    const r = Object.freeze(row({ unresolved: true, heldOpenBy: Object.freeze([SINCE]) as unknown as string[] }));
    const run = () => [activityWindowLabel(0, 24 * H), headlineFor("warn", 2), stillUnresolved(r, problems)];
    expect(run).not.toThrow();
    expect(run()).toEqual(run());
    expect(r.heldOpenBy).toEqual([SINCE]);
    expect(problems).toHaveLength(1);
  });
});
