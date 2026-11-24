// @vitest-environment jsdom
import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, within } from "@testing-library/react";
import { UsageOverviewPane, overviewTotals } from "./UsageOverviewPane";
import type { InsightOverview } from "../api/insight";

const useInsightOverview = vi.fn();

vi.mock("../api/insight", () => ({
  useInsightOverview: (...args: unknown[]) => useInsightOverview(...args),
}));

vi.mock("@adh-sdk/adh-ui/components/time-series-chart", () => ({
  TimeSeriesChart: ({ series }: { series: { label: string }[] }) => (
    <div data-testid="chart">{series.map((s) => s.label).join(",")}</div>
  ),
}));

type Point = InsightOverview["points"][number];

const point = (over: Partial<Point> = {}): Point => ({
  start: "2026-09-01",
  requests: 100,
  bytes_in: 1024,
  bytes_out: 2048,
  server_ms: 1_000,
  db_ms: 500,
  llm_tokens: { input: 10, output: 20, cache_read: 5, cache_write: 1, reasoning: 4 },
  embeddings: 0,
  emails: 2,
  sms_segments: 1,
  storage_ops: 0,
  direct_micros: 1_000_000,
  unpriced_lines: 0,
  ...over,
});

beforeEach(() => {
  useInsightOverview.mockReset();
  useInsightOverview.mockReturnValue({
    data: { interval: "day", points: [point(), point({ start: "2026-09-02" })] },
    isLoading: false,
    error: null,
  });
});

afterEach(cleanup);

describe("overviewTotals", () => {
  it("sums every series; tokens exclude reasoning, which output already holds", () => {
    const t = overviewTotals([point(), point()]);
    expect(t).toMatchObject({ requests: 200, bytesIn: 2048, llmTokens: 72, emails: 4 });
    expect(t).toMatchObject({ directMicros: 2_000_000, directIsFloor: false });
  });

  it("is Unpriced when every bucket is, and a floor when only some are", () => {
    const unpriced = point({ direct_micros: null, unpriced_lines: 1 });
    expect(overviewTotals([unpriced]).directMicros).toBeNull();
    expect(overviewTotals([point(), unpriced])).toMatchObject({
      directMicros: 1_000_000,
      directIsFloor: true,
    });
  });

  it("is a floor when a priced bucket still has unpriced lines", () => {
    expect(overviewTotals([point(), point({ unpriced_lines: 2 })])).toMatchObject({
      directMicros: 2_000_000,
      directIsFloor: true,
    });
  });
});

describe("UsageOverviewPane", () => {
  it("draws a chart per series group and a totals row", () => {
    render(<UsageOverviewPane />);
    expect(screen.getAllByTestId("chart").map((c) => c.textContent)).toEqual([
      "Requests",
      "In,Out",
      "Server,Database",
      "Input,Output,Cache read,Cache write",
      "Emails,SMS",
      "Direct cost",
    ]);
    const totals = within(screen.getByRole("region", { name: "Totals" }));
    expect(totals.getByText("200")).toBeTruthy();
    expect(totals.getByText("$2.00")).toBeTruthy();
  });

  it("reads Unpriced, never $0.00, when every bucket is unpriced", () => {
    useInsightOverview.mockReturnValue({
      data: { interval: "day", points: [point({ direct_micros: null, unpriced_lines: 1 })] },
      isLoading: false,
      error: null,
    });
    render(<UsageOverviewPane />);
    const totals = within(screen.getByRole("region", { name: "Totals" }));
    expect(totals.getByText("Unpriced")).toBeTruthy();
    expect(totals.queryByText("$0.00")).toBeNull();
  });

  it("marks the direct total a floor when a priced bucket has unpriced lines", () => {
    useInsightOverview.mockReturnValue({
      data: { interval: "day", points: [point(), point({ unpriced_lines: 3 })] },
      isLoading: false,
      error: null,
    });
    render(<UsageOverviewPane />);
    const totals = within(screen.getByRole("region", { name: "Totals" }));
    expect(totals.getByText("≥ $2.00")).toBeTruthy();
  });

  it("refetches with the chosen interval", () => {
    render(<UsageOverviewPane />);
    expect(useInsightOverview.mock.calls.at(-1)![1]).toBe("day");
    fireEvent.change(screen.getByLabelText("Interval"), { target: { value: "week" } });
    expect(useInsightOverview.mock.calls.at(-1)![1]).toBe("week");
  });
});
