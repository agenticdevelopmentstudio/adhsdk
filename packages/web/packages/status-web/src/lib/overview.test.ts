import { describe, it, expect } from "vitest";
import { activityWindowLabel } from "./overview";

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
