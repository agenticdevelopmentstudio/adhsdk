// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { RunRateHeader } from "./RunRateHeader";
import type { RunRate } from "../api/insight";

afterEach(cleanup);

const runRate = (over: Partial<RunRate> = {}): RunRate => ({
  month: "2026-09",
  elapsed_days: 10,
  days_in_month: 30,
  direct_to_date_micros: 0,
  fixed_month_micros: 20_000_000,
  projected_month_micros: 20_000_000,
  unpriced_items: 0,
  by_category: [],
  ...over,
});

const header = (rr: RunRate | undefined, extra: { error?: unknown; onShowUnpriced?: () => void } = {}) =>
  render(
    <RunRateHeader
      month="2026-09"
      onMonthChange={vi.fn()}
      maxMonth="2026-09"
      runRate={rr}
      onShowUnpriced={extra.onShowUnpriced ?? vi.fn()}
      error={extra.error}
    />,
  );

describe("RunRateHeader", () => {
  it("prefixes month to date and projected with a floor marker when items are unpriced", () => {
    header(
      runRate({ direct_to_date_micros: 3_000_000, projected_month_micros: 29_000_000, unpriced_items: 2 }),
    );
    expect(screen.getByText("≥ $3.00")).toBeTruthy(); // month to date
    expect(screen.getByText("≥ $29.00")).toBeTruthy(); // projected
    expect(screen.getByText("$20.00")).toBeTruthy(); // fixed stays exact
  });

  it("reads Unpriced, never ≥ $0.00, when the whole month's direct cost is unpriced", () => {
    header(runRate({ direct_to_date_micros: null, unpriced_items: 2 }));
    expect(screen.getByText("Unpriced")).toBeTruthy(); // month to date
    // The projection is the fixed part alone, and the unpriced direct part can only add to it.
    expect(screen.getByText("≥ $20.00")).toBeTruthy();
    expect(screen.queryByText("≥ $0.00")).toBeNull();
  });

  it("reads Unpriced for the projection too when there is no fixed cost to floor it", () => {
    header(
      runRate({ direct_to_date_micros: null, fixed_month_micros: 0, projected_month_micros: 0, unpriced_items: 1 }),
    );
    expect(screen.getAllByText("Unpriced")).toHaveLength(2); // month to date and projected
    expect(screen.queryByText("≥ $0.00")).toBeNull();
  });

  it("shows exact figures, and no button, when nothing is unpriced", () => {
    header(runRate({ direct_to_date_micros: 5_000_000, projected_month_micros: 35_000_000 }));
    expect(screen.getByText("$5.00")).toBeTruthy();
    expect(screen.queryByText(/≥/)).toBeNull();
    expect(screen.queryByRole("button", { name: /unpriced/ })).toBeNull();
  });

  it("the unpriced count is a button that asks to show them", () => {
    const onShow = vi.fn();
    header(runRate({ unpriced_items: 3 }), { onShowUnpriced: onShow });
    fireEvent.click(screen.getByRole("button", { name: "3 unpriced items" }));
    expect(onShow).toHaveBeenCalledTimes(1);
  });

  it("shows a run-rate load error in the header", () => {
    header(undefined, { error: new Error("run rate exploded") });
    expect(screen.getByText("run rate exploded")).toBeTruthy();
  });
});
