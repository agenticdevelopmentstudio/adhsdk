// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { renderHook, act, cleanup } from "@testing-library/react";
import { useSourceFilter } from "./use-source-filter";
import { ISSUE_SOURCES, type IssueSource } from "../lib/issue-sources";

const ALL: IssueSource[] = ["dns", "http", "glitchtip", "vercel", "vercel-runtime", "cloudflare-pages", "railway", "crunchy"];

afterEach(() => {
  vi.restoreAllMocks();
  cleanup();
  localStorage.clear();
});

describe("useSourceFilter", () => {
  it("source-filter-001 starts with every source in canonical order and a toggle function", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    expect(result.current.sources.size).toBe(8);
    expect([...result.current.sources]).toEqual(ALL);
    expect(typeof result.current.toggleSource).toBe("function");
  });

  it("source-filter-002 contains cloudflare-pages by default", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    expect(result.current.sources.has("cloudflare-pages")).toBe(true);
  });

  it("source-filter-003 toggling a selected source removes it and yields a new Set", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    const before = result.current.sources;
    act(() => result.current.toggleSource("http"));
    expect(result.current.sources.size).toBe(7);
    expect(result.current.sources.has("http")).toBe(false);
    expect(result.current.sources).not.toBe(before);
    expect(before.size).toBe(8);
  });

  it("source-filter-004 toggling it back appends it at the end", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    act(() => result.current.toggleSource("http"));
    act(() => result.current.toggleSource("http"));
    expect([...result.current.sources]).toEqual([
      "dns",
      "glitchtip",
      "vercel",
      "vercel-runtime",
      "cloudflare-pages",
      "railway",
      "crunchy",
      "http",
    ]);
  });

  it("source-filter-005 toggling every source leaves an empty set without error", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    for (const s of ALL) act(() => result.current.toggleSource(s));
    expect(result.current.sources.size).toBe(0);
  });

  it("source-filter-006 two toggles in one batch both apply", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    act(() => {
      result.current.toggleSource("dns");
      result.current.toggleSource("railway");
    });
    expect(result.current.sources.size).toBe(6);
    expect(result.current.sources.has("dns")).toBe(false);
    expect(result.current.sources.has("railway")).toBe(false);
  });

  it("source-filter-007 the same source toggled twice in one batch cancels out", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    act(() => {
      result.current.toggleSource("vercel");
      result.current.toggleSource("vercel");
    });
    expect(result.current.sources.size).toBe(8);
    expect(result.current.sources.has("vercel")).toBe(true);
  });

  it("source-filter-008 toggling never mutates the shared source list", () => {
    const { result } = renderHook(() => useSourceFilter("k"));
    act(() => result.current.toggleSource("dns"));
    expect(ISSUE_SOURCES).toHaveLength(8);
    expect(ISSUE_SOURCES).toContain("dns");
  });

  it("source-filter-009 two uses keep independent state", () => {
    const a = renderHook(() => useSourceFilter("a"));
    const b = renderHook(() => useSourceFilter("b"));
    act(() => a.result.current.toggleSource("glitchtip"));
    expect(a.result.current.sources.size).toBe(7);
    expect(b.result.current.sources.size).toBe(8);
  });

  it("source-filter-010 a toggled selection is written to storage and restored on remount", () => {
    const first = renderHook(() => useSourceFilter("pane"));
    for (const s of ALL.filter((x) => x !== "dns")) act(() => first.result.current.toggleSource(s));
    expect([...first.result.current.sources]).toEqual(["dns"]);
    expect(JSON.parse(localStorage.getItem("pane")!)).toEqual(["dns"]);
    first.unmount();
    const second = renderHook(() => useSourceFilter("pane"));
    expect([...second.result.current.sources]).toEqual(["dns"]);
  });

  it("source-filter-011 toggle is a new function each render; sources is stable without a toggle", () => {
    const { result, rerender } = renderHook(() => useSourceFilter("k"));
    const first = result.current;
    rerender();
    expect(result.current.toggleSource).not.toBe(first.toggleSource);
    expect(result.current.sources).toBe(first.sources);
  });

  it.skip("source-filter-012 is unavailable in a server-only rendering context (jsdom cannot host a server component boundary)", () => {});
});
