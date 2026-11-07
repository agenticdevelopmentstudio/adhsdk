import { describe, it, expect } from "vitest";
import { activityWindowLabel, stillUnresolved } from "./overview";
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
