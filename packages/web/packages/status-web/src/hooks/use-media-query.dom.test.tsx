// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { renderHook, cleanup, act } from "@testing-library/react";
import { renderToString } from "react-dom/server";
import { useMediaQuery } from "./use-media-query";

type Handler = (e: MediaQueryListEvent) => void;

interface FakeMql {
  query: string;
  matches: boolean;
  handlers: Set<Handler>;
  addEventListener: ReturnType<typeof vi.fn>;
  removeEventListener: ReturnType<typeof vi.fn>;
}

const originalMatchMedia = window.matchMedia;
let created: FakeMql[] = [];

/** Install a matchMedia whose result per query comes from `results` (default no match). */
function installMatchMedia(results: Record<string, boolean>): ReturnType<typeof vi.fn> {
  created = [];
  const fn = vi.fn((query: string): MediaQueryList => {
    const handlers = new Set<Handler>();
    const mql: FakeMql = {
      query,
      matches: results[query] ?? false,
      handlers,
      addEventListener: vi.fn((_type: string, h: Handler): void => {
        handlers.add(h);
      }),
      removeEventListener: vi.fn((_type: string, h: Handler): void => {
        handlers.delete(h);
      }),
    };
    created.push(mql);
    return mql as unknown as MediaQueryList;
  });
  window.matchMedia = fn as unknown as typeof window.matchMedia;
  return fn;
}

function notify(mql: FakeMql, matches: boolean): void {
  act(() => {
    for (const h of [...mql.handlers]) h({ matches } as MediaQueryListEvent);
  });
}

afterEach(() => {
  cleanup();
  window.matchMedia = originalMatchMedia;
});

describe("useMediaQuery", () => {
  it("media-query-001: the first evaluation is false even when the viewport matches", () => {
    installMatchMedia({ "(max-width: 760px)": true });
    const seen: boolean[] = [];
    renderHook(() => {
      const v = useMediaQuery("(max-width: 760px)");
      seen.push(v);
      return v;
    });
    expect(seen[0]).toBe(false);
  });

  it("media-query-002: a server-rendering pass renders false", () => {
    const matchMedia = installMatchMedia({ "(min-width: 761px)": true });
    function Probe() {
      return <span>{String(useMediaQuery("(min-width: 761px)"))}</span>;
    }
    expect(renderToString(<Probe />)).toContain("false");
    expect(matchMedia).not.toHaveBeenCalled();
  });

  it("media-query-003: a matching query becomes true once subscribed", () => {
    installMatchMedia({ "(max-width: 760px)": true });
    const { result } = renderHook(() => useMediaQuery("(max-width: 760px)"));
    expect(result.current).toBe(true);
  });

  it("media-query-004: a non-matching query stays false once subscribed", () => {
    installMatchMedia({ "(max-width: 760px)": false });
    const { result } = renderHook(() => useMediaQuery("(max-width: 760px)"));
    expect(result.current).toBe(false);
  });

  it("media-query-005: change notifications drive the value both ways", () => {
    installMatchMedia({ "(max-width: 760px)": false });
    const { result } = renderHook(() => useMediaQuery("(max-width: 760px)"));
    expect(result.current).toBe(false);
    notify(created[0]!, true);
    expect(result.current).toBe(true);
    notify(created[0]!, false);
    expect(result.current).toBe(false);
  });

  it("media-query-006: unmount removes the same change handler once", () => {
    installMatchMedia({ "(max-width: 760px)": false });
    const { unmount } = renderHook(() => useMediaQuery("(max-width: 760px)"));
    const mql = created[0]!;
    const added = mql.addEventListener.mock.calls[0]!;
    expect(added[0]).toBe("change");
    unmount();
    expect(mql.removeEventListener).toHaveBeenCalledTimes(1);
    expect(mql.removeEventListener).toHaveBeenCalledWith("change", added[1]);
    expect(mql.handlers.size).toBe(0);
  });

  it("media-query-007: a changed query removes the old listener, asks about the new query and subscribes", () => {
    const matchMedia = installMatchMedia({ "(max-width: 760px)": false, "(min-width: 761px)": true });
    const { result, rerender } = renderHook(({ q }: { q: string }) => useMediaQuery(q), {
      initialProps: { q: "(max-width: 760px)" },
    });
    const first = created[0]!;
    expect(result.current).toBe(false);
    rerender({ q: "(min-width: 761px)" });
    expect(first.removeEventListener).toHaveBeenCalledTimes(1);
    expect(first.handlers.size).toBe(0);
    expect(matchMedia).toHaveBeenLastCalledWith("(min-width: 761px)");
    const second = created[1]!;
    expect(second.addEventListener).toHaveBeenCalledTimes(1);
    expect(result.current).toBe(true);
  });

  it("media-query-008: an unchanged query is not re-evaluated or re-subscribed", () => {
    const matchMedia = installMatchMedia({ "(max-width: 760px)": false });
    const { rerender } = renderHook(({ q }: { q: string }) => useMediaQuery(q), {
      initialProps: { q: "(max-width: 760px)" },
    });
    rerender({ q: "(max-width: 760px)" });
    rerender({ q: "(max-width: 760px)" });
    expect(matchMedia).toHaveBeenCalledTimes(1);
    expect(created[0]!.addEventListener).toHaveBeenCalledTimes(1);
    expect(created[0]!.removeEventListener).not.toHaveBeenCalled();
  });

  it("media-query-009: the render pass after a query change still reports the old result, then the new one", () => {
    installMatchMedia({ "(max-width: 760px)": true, "(min-width: 761px)": false });
    const seen: boolean[] = [];
    const { rerender } = renderHook(({ q }: { q: string }) => {
      const v = useMediaQuery(q);
      seen.push(v);
      return v;
    }, { initialProps: { q: "(max-width: 760px)" } });
    expect(seen[seen.length - 1]).toBe(true);
    seen.length = 0;
    rerender({ q: "(min-width: 761px)" });
    expect(seen[0]).toBe(true);
    expect(seen[seen.length - 1]).toBe(false);
  });

  it("media-query-010: a missing matchMedia surfaces an error with no fallback", () => {
    window.matchMedia = undefined as unknown as typeof window.matchMedia;
    const errSpy = vi.spyOn(console, "error").mockImplementation(() => undefined);
    expect(() => renderHook(() => useMediaQuery("(max-width: 760px)"))).toThrow();
    errSpy.mockRestore();
  });

  it.skip("media-query-011: module is client-only in a server-only rendering context", () => {
    // jsdom cannot exercise a server-components bundler boundary; the "use client" directive is a build-time contract.
  });
});
