// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { renderHook, cleanup } from "@testing-library/react";
import { usePortfolioIndicator } from "./use-portfolio-indicator";

// Fix Round 3 item 1: `useBoard` itself now folds "never arrived", "fetch failed",
// AND "gone stale" into a single `board: null` — this hook no longer computes its
// own `isBoardStale` term (that was the second of three instances of one bug: a
// consumer re-deriving a check the hook can just never let it skip). So this file
// mocks `useBoard` at the boundary and only proves `usePortfolioIndicator` treats
// whatever `board` it's handed literally: null renders "unknown" regardless of WHY
// it's null, non-null backs its own indicator. The "why does a stale board become
// null" rule itself is exercised against the REAL `useBoard` in
// `use-board.dom.test.tsx`, alongside a test that this hook and `GlobalPanel` agree.

const mockState = vi.hoisted(() => ({
  snapshot: null as { generatedAt: string; freshness?: { state: string; asOf: string | null } } | null,  offline: false,
  blind: false,
  board: null as { generatedAt: string; indicator: "operational" | "degraded" | "outage"; problems: unknown[] } | null,
}));

vi.mock("./use-live-snapshot", () => ({
  useLiveSnapshot: () => ({ snapshot: mockState.snapshot, offline: mockState.offline, blind: mockState.blind }),
}));
vi.mock("./use-board", () => ({ useBoard: () => ({ board: mockState.board }) }));

afterEach(() => {
  cleanup();
  mockState.snapshot = null;
  mockState.offline = false;
  mockState.blind = false;
  mockState.board = null;
});

type Indicator = "operational" | "degraded" | "outage";
const boardOf = (indicator: Indicator, problemCount = 0): NonNullable<typeof mockState.board> => ({
  generatedAt: "2026-01-01T00:00:00.000Z",
  indicator,
  problems: Array.from({ length: problemCount }, (_, i) => ({ id: `p${i + 1}` })),
});
const snapshotWith = (freshness?: { state: string; asOf: string | null }): NonNullable<typeof mockState.snapshot> => ({
  generatedAt: "2026-01-01T00:00:00.000Z",
  ...(freshness ? { freshness } : {}),
});
const FRESH = { state: "fresh", asOf: "2026-01-01T00:00:00.000Z" };

describe("usePortfolioIndicator — conformance vectors", () => {
  it("portfolio-001: null snapshot is not stale; operational board maps to ok", () => {
    mockState.board = boardOf("operational");
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "ok", count: 0 });
  });

  it("portfolio-002: no board is unknown with count 0", () => {
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "unknown", count: 0 });
  });

  it("portfolio-003: offline is unknown but the count still comes from the board", () => {
    mockState.offline = true;
    mockState.board = boardOf("operational", 1);
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "unknown", count: 1 });
  });

  it("portfolio-004: blind is unknown with the board's count", () => {
    mockState.blind = true;
    mockState.board = boardOf("degraded", 2);
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "unknown", count: 2 });
  });

  it("portfolio-005: degraded maps to warn", () => {
    mockState.snapshot = snapshotWith(FRESH);
    mockState.board = boardOf("degraded", 2);
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "warn", count: 2 });
  });

  it("portfolio-006: outage maps to down", () => {
    mockState.snapshot = snapshotWith(FRESH);
    mockState.board = boardOf("outage", 1);
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "down", count: 1 });
  });

  it("portfolio-007: a stale snapshot verdict forces unknown", () => {
    mockState.snapshot = snapshotWith({ state: "stale", asOf: "2026-01-01T00:00:00.000Z" });
    mockState.board = boardOf("operational");
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "unknown", count: 0 });
  });

  it("portfolio-008: a very-stale snapshot verdict forces unknown", () => {
    mockState.snapshot = snapshotWith({ state: "very-stale", asOf: "2026-01-01T00:00:00.000Z" });
    mockState.board = boardOf("operational");
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("unknown");
  });

  it("portfolio-009: a fresh snapshot verdict leaves the board's verdict standing", () => {
    mockState.snapshot = snapshotWith(FRESH);
    mockState.board = boardOf("operational");
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("ok");
  });

  it("portfolio-010: a fresh verdict with no data clock (no probe yet) is not an alarm", () => {
    mockState.snapshot = snapshotWith({ state: "fresh", asOf: null });
    mockState.board = boardOf("operational");
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("ok");
  });

  it("portfolio-011: a snapshot with no freshness verdict reads as unknown without throwing", () => {
    mockState.snapshot = snapshotWith();
    mockState.board = boardOf("operational");
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("unknown");
  });

  it("portfolio-012: a stale snapshot alone overrides an outage board", () => {
    mockState.snapshot = snapshotWith({ state: "stale", asOf: "2026-01-01T00:00:00.000Z" });
    mockState.board = boardOf("outage", 1);
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current).toEqual({ pillKey: "unknown", count: 1 });
  });

  // portfolio-013 runs against the real useBoard in use-board.dom.test.tsx (this file mocks useBoard).

  it("portfolio-014: no memoisation; a null board after an ok verdict reads unknown", () => {
    mockState.board = boardOf("operational");
    const { result, rerender } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("ok");
    mockState.board = null;
    rerender();
    expect(result.current.pillKey).toBe("unknown");
  });

  it("portfolio-015: the result has exactly the keys pillKey and count", () => {
    mockState.board = boardOf("degraded", 1);
    const { result } = renderHook(() => usePortfolioIndicator());
    expect(Object.keys(result.current).sort()).toEqual(["count", "pillKey"]);
  });
});

describe("usePortfolioIndicator — trusts useBoard's null fold, doesn't re-derive it", () => {
  it("a present board backs its own verdict", () => {
    mockState.board = {
      generatedAt: new Date().toISOString(),
      indicator: "operational",
      problems: [],
    };

    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("ok");
  });

  it("board === null renders unknown, never the last verdict — whatever null means this time", () => {
    // Deliberately not constructing a stale board with an old `generatedAt` here:
    // this hook no longer has an `isBoardStale` term to exercise (Fix Round 3 item
    // 1 removed it), so a board object could only ever demonstrate the mock is
    // wired, not that the hook does anything. `board === null` is the one signal
    // this hook still reads directly, and it's the same signal for all three
    // reasons `useBoard` can produce it.
    mockState.board = null;

    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("unknown");
  });

  it("a snapshot with the server's fresh verdict leaves the board's verdict standing", () => {
    mockState.board = { generatedAt: new Date().toISOString(), indicator: "operational", problems: [] };
    mockState.snapshot = { generatedAt: new Date().toISOString(), freshness: { state: "fresh", asOf: null } };

    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("ok");
  });

  it("a snapshot from a backend older than `freshness` reads as unknown instead of throwing", () => {
    mockState.board = { generatedAt: new Date().toISOString(), indicator: "operational", problems: [] };
    mockState.snapshot = { generatedAt: new Date().toISOString() };

    const { result } = renderHook(() => usePortfolioIndicator());
    expect(result.current.pillKey).toBe("unknown");
  });
});
