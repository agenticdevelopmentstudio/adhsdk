// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { renderHook, act, cleanup } from "@testing-library/react";
import { usePersistedState, decodeBoolean } from "./use-persisted-state";
import { useSourceFilter } from "./use-source-filter";

afterEach(() => {
  vi.restoreAllMocks();
  cleanup();
  localStorage.clear();
});

describe("usePersistedState — gear settings survive a reload", () => {
  it("pstate-001 restores a value set in an earlier mount", () => {
    const first = renderHook(() => usePersistedState("k", false, decodeBoolean));
    act(() => first.result.current[1](true));
    first.unmount();
    const second = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(second.result.current[0]).toBe(true);
  });

  it("pstate-002 keeps the default for a stored value the decoder doesn't recognise", () => {
    localStorage.setItem("k", JSON.stringify("yes"));
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(result.current[0]).toBe(false);
  });

  it("pstate-003 persists each pane's source filter under its own key", () => {
    const a = renderHook(() => useSourceFilter("src-activity"));
    act(() => a.result.current.toggleSource("glitchtip"));
    a.unmount();
    expect(renderHook(() => useSourceFilter("src-activity")).result.current.sources.has("glitchtip")).toBe(false);
    expect(renderHook(() => useSourceFilter("src-problems")).result.current.sources.has("glitchtip")).toBe(true);
  });
});

describe("usePersistedState — hydration and setter edge cases", () => {
  it("pstate-004 starts at initial with empty storage and writes nothing", () => {
    const { result } = renderHook(() => usePersistedState("k", 7, (r) => (typeof r === "number" ? r : undefined)));
    expect(result.current[0]).toBe(7);
    expect(localStorage.length).toBe(0);
  });

  it("pstate-005 keeps the default when the stored text is not JSON", () => {
    localStorage.setItem("k", "{oops");
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(result.current[0]).toBe(false);
  });

  it("pstate-006 keeps the default when reading storage throws", () => {
    vi.spyOn(localStorage, "getItem").mockImplementation(() => {
      throw new Error("blocked");
    });
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(result.current[0]).toBe(false);
  });

  it("pstate-007 composes two functional updates in one batch and stores the result", () => {
    const { result } = renderHook(() => usePersistedState("k", 0, (r) => (typeof r === "number" ? r : undefined)));
    act(() => {
      result.current[1]((p) => p + 1);
      result.current[1]((p) => p + 1);
    });
    expect(result.current[0]).toBe(2);
    expect(localStorage.getItem("k")).toBe("2");
  });

  it("pstate-008 applies the in-memory value when writing storage throws", () => {
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    vi.spyOn(localStorage, "setItem").mockImplementation(() => {
      throw new Error("quota");
    });
    act(() => result.current[1](true));
    expect(result.current[0]).toBe(true);
  });

  it("pstate-009 stores the value itself as JSON when encode is omitted", () => {
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    act(() => result.current[1](true));
    expect(localStorage.getItem("k")).toBe("true");
  });

  it("pstate-010 round-trips a Set through encode and decode", () => {
    const decode = (r: unknown) => (Array.isArray(r) ? new Set(r as string[]) : undefined);
    const encode = (v: Set<string>) => [...v];
    const first = renderHook(() => usePersistedState("k", new Set<string>(), decode, encode));
    act(() => first.result.current[1](new Set(["a", "b"])));
    first.unmount();
    expect(localStorage.getItem("k")).toBe('["a","b"]');
    const second = renderHook(() => usePersistedState("k", new Set<string>(), decode, encode));
    expect(second.result.current[0]).toEqual(new Set(["a", "b"]));
  });

  it("pstate-011 decodeBoolean accepts only real booleans", () => {
    expect(decodeBoolean(true)).toBe(true);
    expect(decodeBoolean(false)).toBe(false);
    expect(decodeBoolean("true")).toBeUndefined();
    expect(decodeBoolean(1)).toBeUndefined();
    expect(decodeBoolean(null)).toBeUndefined();
  });

  it("pstate-012 keeps the old key's value on a key change with no stored entry, and adopts a stored value", () => {
    const { result, rerender } = renderHook(({ k }) => usePersistedState(k, false, decodeBoolean), {
      initialProps: { k: "a" },
    });
    act(() => result.current[1](true));
    rerender({ k: "b" });
    expect(result.current[0]).toBe(true);
    localStorage.setItem("c", "false");
    rerender({ k: "c" });
    expect(result.current[0]).toBe(false);
  });

  it("pstate-013 reads storage once and ignores a new inline decode on re-render", () => {
    localStorage.setItem("k", "true");
    const getItem = vi.spyOn(localStorage, "getItem");
    const { result, rerender } = renderHook(() => usePersistedState("k", false, (r) => decodeBoolean(r)));
    rerender();
    rerender();
    rerender();
    expect(getItem).toHaveBeenCalledTimes(1);
    expect(result.current[0]).toBe(true);
  });

  it("pstate-014 keeps initial when decode throws", () => {
    localStorage.setItem("k", "true");
    const { result } = renderHook(() =>
      usePersistedState<boolean>("k", false, () => {
        throw new Error("bad shape");
      }),
    );
    expect(result.current[0]).toBe(false);
  });

  it("pstate-015 writes storage even when the value is unchanged", () => {
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    localStorage.clear();
    act(() => result.current[1](false));
    expect(localStorage.getItem("k")).toBe("false");
  });

  it("pstate-016 the setter uses the encode from the render that created it", () => {
    const decode = (r: unknown) => (typeof r === "number" ? r : undefined);
    const { result, rerender } = renderHook(
      ({ encode }: { encode: (v: number) => unknown }) => usePersistedState("k", 0, decode, encode),
      { initialProps: { encode: (v: number): unknown => [v] } },
    );
    rerender({ encode: (v: number) => ({ v }) });
    act(() => result.current[1](1));
    expect(localStorage.getItem("k")).toBe("[1]");
  });

  it("pstate-017 the setter is stable for one key, changes with the key, and a captured setter writes to its own key", () => {
    const { result, rerender } = renderHook(({ k }) => usePersistedState(k, false, decodeBoolean), {
      initialProps: { k: "a" },
    });
    const captured = result.current[1];
    rerender({ k: "a" });
    expect(result.current[1]).toBe(captured);
    rerender({ k: "b" });
    expect(result.current[1]).not.toBe(captured);
    act(() => captured(true));
    expect(localStorage.getItem("a")).toBe("true");
    expect(localStorage.getItem("b")).toBeNull();
  });

  it("pstate-018 an updater that throws is not caught and writes nothing", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    const { result } = renderHook(() => usePersistedState("k", 0, (r) => (typeof r === "number" ? r : undefined)));
    expect(() =>
      act(() => {
        result.current[1](() => {
          throw new Error("updater failed");
        });
      }),
    ).toThrow("updater failed");
    expect(localStorage.getItem("k")).toBeNull();
  });

  it("pstate-019 reads storage once per key, not on re-renders", () => {
    const getItem = vi.spyOn(localStorage, "getItem");
    const { rerender } = renderHook(({ k }) => usePersistedState(k, false, decodeBoolean), {
      initialProps: { k: "k" },
    });
    rerender({ k: "k" });
    rerender({ k: "k" });
    rerender({ k: "k" });
    expect(getItem).toHaveBeenCalledTimes(1);
    rerender({ k: "j" });
    expect(getItem).toHaveBeenCalledTimes(2);
    expect(getItem).toHaveBeenLastCalledWith("j");
  });

  it("pstate-020 hydration does not write to storage", () => {
    localStorage.setItem("k", "true");
    const setItem = vi.spyOn(localStorage, "setItem");
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    expect(result.current[0]).toBe(true);
    expect(setItem).not.toHaveBeenCalled();
  });

  it("pstate-021 two mounts of one key hold separate in-memory values", () => {
    const a = renderHook(() => usePersistedState("k", false, decodeBoolean));
    const b = renderHook(() => usePersistedState("k", false, decodeBoolean));
    act(() => a.result.current[1](true));
    expect(a.result.current[0]).toBe(true);
    expect(b.result.current[0]).toBe(false);
    expect(localStorage.getItem("k")).toBe("true");
  });

  it("pstate-022 ignores storage events from other tabs", () => {
    const { result } = renderHook(() => usePersistedState("k", false, decodeBoolean));
    act(() => {
      localStorage.setItem("k", "true");
      window.dispatchEvent(new StorageEvent("storage", { key: "k", newValue: "true" }));
    });
    expect(result.current[0]).toBe(false);
  });
});
