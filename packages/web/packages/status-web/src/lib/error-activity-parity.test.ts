import { describe, expect, it } from "vitest";
import { ERROR_JUDGED_LEVELS, ERROR_RECENT_MS } from "@adh-sdk/status-server/board";
import { ACTIVE_LEVEL_NAMES, ACTIVE_WINDOW_MS, isActiveError } from "./error-activity";

// DRIFT GUARD. The Overview's Errors card and the board's Problems pane must judge the same
// issues active, or the card goes red while Problems stays clear.

describe("the active-error rule", () => {
  it("matches the board's", () => {
    expect([...ACTIVE_LEVEL_NAMES].sort()).toEqual([...ERROR_JUDGED_LEVELS].sort());
    expect(ACTIVE_WINDOW_MS).toBe(ERROR_RECENT_MS);
  });
});

describe("isActiveError", () => {
  const NOW = Date.parse("2026-11-04T12:00:00.000Z");
  const hoursAgo = (hours: number): string => new Date(NOW - hours * 3_600_000).toISOString();

  it("counts an error or a fatal seen in the last day", () => {
    expect(isActiveError("error", hoursAgo(23), NOW)).toBe(true);
    expect(isActiveError("FATAL", hoursAgo(1), NOW)).toBe(true);
  });

  it("leaves an old issue in the backlog however loud it once was", () => {
    expect(isActiveError("fatal", hoursAgo(25), NOW)).toBe(false);
  });

  it("does not treat a warning as an incident", () => {
    expect(isActiveError("warning", hoursAgo(1), NOW)).toBe(false);
  });

  it("makes no claim from a missing level or time", () => {
    expect(isActiveError(null, hoursAgo(1), NOW)).toBe(false);
    expect(isActiveError("error", null, NOW)).toBe(false);
    expect(isActiveError("error", "not a date", NOW)).toBe(false);
  });
});
