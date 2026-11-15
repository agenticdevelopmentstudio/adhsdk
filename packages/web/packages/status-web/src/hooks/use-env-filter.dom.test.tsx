// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { renderHook, act } from "@testing-library/react";
// @ts-expect-error vite raw import; read as text to check the directive
import source from "./use-env-filter.ts?raw";
import { useEnvFilter } from "./use-env-filter";
import { purgeRetiredStorage } from "../lib/retired-storage";

const KEY = "adh-env-filter";
const ALL = ["production", "staging", "testing"];
const sorted = (s: Set<string>): string[] => [...s].sort();

beforeEach(() => {
  window.localStorage.clear();
});
afterEach(() => {
  vi.restoreAllMocks();
});

describe("useEnvFilter", () => {
  it("env-filter-001 starts with every environment selected", () => {
    const { result } = renderHook(() => useEnvFilter());
    expect(sorted(result.current.envs)).toEqual(ALL);
    expect(result.current.all).toEqual(ALL);
    expect(typeof result.current.toggle).toBe("function");
  });

  it("env-filter-002 hydrates from storage after the first render", () => {
    window.localStorage.setItem(KEY, JSON.stringify(["production"]));
    // Capture the first render's value; effects have run by the time renderHook returns.
    const seen: string[][] = [];
    const { result } = renderHook(() => {
      const r = useEnvFilter();
      seen.push(sorted(r.envs));
      return r;
    });
    expect(seen[0]).toEqual(ALL);
    expect(sorted(result.current.envs)).toEqual(["production"]);
  });

  it("env-filter-003 an empty stored string keeps the default and is never parsed", () => {
    window.localStorage.setItem(KEY, "");
    const parse = vi.spyOn(JSON, "parse");
    const { result } = renderHook(() => useEnvFilter());
    expect(sorted(result.current.envs)).toEqual(ALL);
    expect(parse).not.toHaveBeenCalled();
  });

  it("env-filter-004 drops invalid entries and collapses duplicates", () => {
    window.localStorage.setItem(KEY, JSON.stringify(["staging", 7, "prod", "staging", null]));
    const { result } = renderHook(() => useEnvFilter());
    expect(sorted(result.current.envs)).toEqual(["staging"]);
    expect(result.current.envs.size).toBe(1);
  });

  it("env-filter-005 an empty stored array hydrates to an empty set", () => {
    window.localStorage.setItem(KEY, "[]");
    const { result } = renderHook(() => useEnvFilter());
    expect(result.current.envs.size).toBe(0);
  });

  it("env-filter-006 an array of only unknown environments hydrates to an empty set", () => {
    window.localStorage.setItem(KEY, JSON.stringify(["qa", "dev"]));
    const { result } = renderHook(() => useEnvFilter());
    expect(result.current.envs.size).toBe(0);
  });

  it("env-filter-007 a non-array stored value keeps the default", () => {
    window.localStorage.setItem(KEY, JSON.stringify({ production: true }));
    const { result } = renderHook(() => useEnvFilter());
    expect(sorted(result.current.envs)).toEqual(ALL);
  });

  it("env-filter-008 malformed JSON keeps the default without throwing", () => {
    window.localStorage.setItem(KEY, "{not json");
    const { result } = renderHook(() => useEnvFilter());
    expect(sorted(result.current.envs)).toEqual(ALL);
  });

  it("env-filter-009 a throwing storage read keeps the default without throwing", () => {
    vi.spyOn(window.localStorage, "getItem").mockImplementation(() => {
      throw new DOMException("denied", "SecurityError");
    });
    const { result } = renderHook(() => useEnvFilter());
    expect(sorted(result.current.envs)).toEqual(ALL);
  });

  it("env-filter-010 toggling an environment off removes it, replaces the set and persists", () => {
    const { result } = renderHook(() => useEnvFilter());
    const before = result.current.envs;
    act(() => result.current.toggle("staging"));
    expect(sorted(result.current.envs)).toEqual(["production", "testing"]);
    expect(result.current.envs).not.toBe(before);
    expect(JSON.parse(window.localStorage.getItem(KEY)!)).toEqual(["production", "testing"]);
  });

  it("env-filter-011 toggling it back on appends it and persists in insertion order", () => {
    const { result } = renderHook(() => useEnvFilter());
    act(() => result.current.toggle("staging"));
    act(() => result.current.toggle("staging"));
    expect([...result.current.envs]).toEqual(["production", "testing", "staging"]);
    expect(JSON.parse(window.localStorage.getItem(KEY)!)).toEqual(["production", "testing", "staging"]);
  });

  it("env-filter-012 the last environment can be toggled off, leaving an empty selection", () => {
    window.localStorage.setItem(KEY, JSON.stringify(["production"]));
    const { result } = renderHook(() => useEnvFilter());
    act(() => result.current.toggle("production"));
    expect(result.current.envs.size).toBe(0);
    expect(window.localStorage.getItem(KEY)).toBe("[]");
  });

  it("env-filter-013 two toggles in one batch both apply", () => {
    const { result } = renderHook(() => useEnvFilter());
    act(() => {
      result.current.toggle("production");
      result.current.toggle("testing");
    });
    expect(sorted(result.current.envs)).toEqual(["staging"]);
    expect(JSON.parse(window.localStorage.getItem(KEY)!)).toEqual(["staging"]);
  });

  it("env-filter-014 a throwing storage write is ignored", () => {
    vi.spyOn(window.localStorage, "setItem").mockImplementation(() => {
      throw new DOMException("full", "QuotaExceededError");
    });
    const { result } = renderHook(() => useEnvFilter());
    expect(() => act(() => result.current.toggle("testing"))).not.toThrow();
    expect(sorted(result.current.envs)).toEqual(["production", "staging"]);
  });

  it("env-filter-015 toggle does not validate; hydration drops the unknown name again", () => {
    const first = renderHook(() => useEnvFilter());
    act(() => first.result.current.toggle("qa"));
    expect(first.result.current.envs.size).toBe(4);
    expect(first.result.current.envs.has("qa")).toBe(true);
    expect(JSON.parse(window.localStorage.getItem(KEY)!)).toEqual([...ALL, "qa"]);
    first.unmount();

    const second = renderHook(() => useEnvFilter());
    expect(sorted(second.result.current.envs)).toEqual(ALL);
  });

  it("env-filter-016 toggle and all keep their identity across state updates", () => {
    const { result } = renderHook(() => useEnvFilter());
    const { toggle, all } = result.current;
    act(() => result.current.toggle("staging"));
    expect(result.current.toggle).toBe(toggle);
    expect(result.current.all).toBe(all);
  });

  it("env-filter-017 the storage-purge routine leaves the filter key alone", () => {
    window.localStorage.setItem(KEY, JSON.stringify(["production"]));
    purgeRetiredStorage();
    expect(window.localStorage.getItem(KEY)).toBe(JSON.stringify(["production"]));
  });

  it("env-filter-018 the module is marked client-only", () => {
    expect((source as string).trimStart().startsWith('"use client"')).toBe(true);
  });
});
