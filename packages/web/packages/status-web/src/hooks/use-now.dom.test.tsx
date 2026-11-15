// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { renderHook, cleanup, act } from "@testing-library/react";
import { useNow } from "./use-now";

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

const advance = (ms: number): void => {
  act(() => {
    vi.advanceTimersByTime(ms);
  });
};

describe("useNow", () => {
  it("use-now-001: returns the current epoch milliseconds on first use", () => {
    vi.setSystemTime(1_000_000);
    const { result } = renderHook(() => useNow());
    expect(result.current).toBe(1_000_000);
  });

  it("use-now-002: stays stable between ticks even when the clock moves", () => {
    vi.setSystemTime(1_000_000);
    const { result, rerender } = renderHook(() => useNow());
    vi.setSystemTime(1_010_000);
    rerender();
    expect(result.current).toBe(1_000_000);
  });

  it("use-now-003: default interval is 30s and the first refresh waits a full interval", () => {
    vi.setSystemTime(1_000_000);
    const { result } = renderHook(() => useNow());
    advance(29_999);
    expect(result.current).toBe(1_000_000);
    advance(1);
    expect(result.current).toBe(1_030_000);
  });

  it("use-now-004: refreshes on every interval", () => {
    vi.setSystemTime(0);
    const seen: number[] = [];
    renderHook(() => {
      const n = useNow(1_000);
      seen.push(n);
      return n;
    });
    advance(1_000);
    advance(1_000);
    advance(1_000);
    expect([...new Set(seen)]).toEqual([0, 1_000, 2_000, 3_000]);
  });

  it("use-now-005: a changed interval restarts a single timer without resetting the value", () => {
    vi.setSystemTime(0);
    const { result, rerender } = renderHook(({ ms }: { ms: number }) => useNow(ms), {
      initialProps: { ms: 1_000 },
    });
    advance(500);
    rerender({ ms: 5_000 });
    expect(vi.getTimerCount()).toBe(1);
    advance(500);
    expect(result.current).toBe(0);
    expect(vi.getTimerCount()).toBe(1);
    advance(4_499);
    expect(result.current).toBe(0);
    advance(1);
    expect(result.current).toBe(5_500);
  });

  it("use-now-006: unmount clears the timer once and nothing fires afterwards", () => {
    vi.setSystemTime(0);
    const clearSpy = vi.spyOn(globalThis, "clearInterval");
    const errSpy = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const { unmount } = renderHook(() => useNow(1_000));
    unmount();
    expect(clearSpy).toHaveBeenCalledTimes(1);
    advance(5_000);
    expect(vi.getTimerCount()).toBe(0);
    expect(errSpy).not.toHaveBeenCalled();
    expect(warnSpy).not.toHaveBeenCalled();
  });

  it("use-now-007: each use owns an independent clock", () => {
    vi.setSystemTime(0);
    const first = renderHook(() => useNow(1_000));
    advance(400);
    const second = renderHook(() => useNow(1_000));
    expect(first.result.current).toBe(0);
    expect(second.result.current).toBe(400);
    advance(600);
    expect(first.result.current).toBe(1_000);
    expect(second.result.current).toBe(400);
  });

  it("use-now-008: performs no network, storage or logging calls", () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const setItem = vi.spyOn(window.localStorage, "setItem");
    const getItem = vi.spyOn(window.localStorage, "getItem");
    const logs = (["log", "info", "warn", "error", "debug"] as const).map((k) =>
      vi.spyOn(console, k).mockImplementation(() => undefined),
    );
    renderHook(() => useNow());
    advance(60_000);
    expect(fetchMock).not.toHaveBeenCalled();
    expect(setItem).not.toHaveBeenCalled();
    expect(getItem).not.toHaveBeenCalled();
    for (const l of logs) expect(l).not.toHaveBeenCalled();
  });

  it.skip("use-now-009: module is client-only in a server-only rendering context", () => {
    // jsdom cannot exercise a server-components bundler boundary; the "use client" directive is a build-time contract.
  });
});
