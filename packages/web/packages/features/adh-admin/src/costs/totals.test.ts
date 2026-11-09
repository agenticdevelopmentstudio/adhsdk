import { describe, it, expect } from "vitest";
import { directTotal, llmTokenTotal } from "./totals";

describe("llmTokenTotal", () => {
  it("adds input, output and cache, never reasoning (it is inside output)", () => {
    expect(
      llmTokenTotal({ input: 1, output: 20, cache_read: 300, cache_write: 4_000, reasoning: 50_000 }),
    ).toBe(4_321);
  });
});

describe("directTotal", () => {
  it("sums priced rows exactly when nothing is unpriced", () => {
    expect(
      directTotal([
        { direct_micros: 1_000_000, unpriced_lines: 0 },
        { direct_micros: 500_000, unpriced_lines: 0 },
      ]),
    ).toEqual({ directMicros: 1_500_000, isFloor: false });
  });

  it("is a floor when a priced row still has unpriced lines", () => {
    expect(
      directTotal([
        { direct_micros: 1_000_000, unpriced_lines: 2 },
        { direct_micros: 500_000, unpriced_lines: 0 },
      ]),
    ).toEqual({ directMicros: 1_500_000, isFloor: true });
  });

  it("is a floor over the priced rows when some row is unpriced", () => {
    expect(
      directTotal([
        { direct_micros: 1_000_000, unpriced_lines: 0 },
        { direct_micros: null, unpriced_lines: 3 },
      ]),
    ).toEqual({ directMicros: 1_000_000, isFloor: true });
  });

  it("is null when every row is unpriced, and 0 over no rows", () => {
    expect(directTotal([{ direct_micros: null, unpriced_lines: 1 }]).directMicros).toBeNull();
    expect(directTotal([])).toEqual({ directMicros: 0, isFloor: false });
  });
});
