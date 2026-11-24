// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from "vitest";
import { localCache, parseSnapshot } from "./local-cache";
import type { TelemetrySnapshot } from "../types";

const KEY = "adh-telemetry-v1";

const snap: TelemetrySnapshot = {
  generatedAt: "2026-06-13T12:00:00.000Z",
  errors: [
    {
      id: "1",
      issueKey: "1",
      project: "hub",
      title: "boom",
      culprit: null,
      level: "error",
      count: 3,
      userCount: 1,
      firstSeen: null,
      lastSeen: null,
      permalink: null,
    },
  ],
  analytics: [{ metric: "pageviews", window: "24h", scope: "all", value: 10, capturedAt: "2026-06-13T12:00:00.000Z" }],
};

beforeEach(() => {
  window.localStorage.clear();
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("parseSnapshot", () => {
  it("stores-001 round-trips a stored snapshot", () => {
    expect(parseSnapshot(JSON.stringify(snap))).toEqual(snap);
  });

  it("stores-002 returns null for null / empty input", () => {
    expect(parseSnapshot(null)).toBeNull();
    expect(parseSnapshot("")).toBeNull();
  });

  it("stores-003 returns null for malformed JSON without throwing", () => {
    expect(() => parseSnapshot("{not json")).not.toThrow();
    expect(parseSnapshot("{not json")).toBeNull();
  });

  it("stores-004 returns null for JSON null", () => {
    expect(parseSnapshot(JSON.stringify(null))).toBeNull();
  });

  it("stores-005 returns null when errors and analytics are missing", () => {
    expect(parseSnapshot(JSON.stringify({ generatedAt: "x" }))).toBeNull();
  });

  it("stores-006 returns null when generatedAt is not a string", () => {
    expect(parseSnapshot(JSON.stringify({ generatedAt: 1, errors: [], analytics: [] }))).toBeNull();
  });

  it("stores-007 returns null when errors is not an array", () => {
    expect(parseSnapshot(JSON.stringify({ generatedAt: "x", errors: "nope", analytics: [] }))).toBeNull();
  });

  it("stores-008 returns null when analytics is not an array", () => {
    expect(parseSnapshot('{"generatedAt":"x","errors":[],"analytics":{}}')).toBeNull();
  });

  it("stores-009 drops extra top-level keys", () => {
    const out = parseSnapshot('{"generatedAt":"x","errors":[],"analytics":[],"extra":1}');
    expect(out).toEqual({ generatedAt: "x", errors: [], analytics: [] });
    expect(out).not.toHaveProperty("extra");
  });

  it("stores-010 passes array elements through unchecked", () => {
    expect(parseSnapshot('{"generatedAt":"x","errors":[42],"analytics":["y"]}')).toEqual({
      generatedAt: "x",
      errors: [42],
      analytics: ["y"],
    });
  });

  it("stores-011 accepts an empty-string generatedAt", () => {
    expect(parseSnapshot('{"generatedAt":"","errors":[],"analytics":[]}')).toEqual({
      generatedAt: "",
      errors: [],
      analytics: [],
    });
  });
});

describe("localCache", () => {
  it("stores-012 saves JSON under the versioned key and loads it back", () => {
    localCache.save(snap);
    expect(window.localStorage.getItem(KEY)).toBe(JSON.stringify(snap));
    expect(localCache.load()).toEqual(snap);
  });

  it("stores-013 loads null when the key is missing", () => {
    expect(window.localStorage.getItem(KEY)).toBeNull();
    expect(localCache.load()).toBeNull();
  });

  it("stores-014 overwrites an earlier save", () => {
    const a: TelemetrySnapshot = { ...snap, generatedAt: "2026-01-01T00:00:00.000Z" };
    const b: TelemetrySnapshot = { ...snap, generatedAt: "2026-02-02T00:00:00.000Z", analytics: [] };
    localCache.save(a);
    localCache.save(b);
    expect(localCache.load()).toEqual(b);
    expect(window.localStorage.getItem(KEY)).toBe(JSON.stringify(b));
    expect(window.localStorage.getItem(KEY)).not.toContain(a.generatedAt);
  });

  it("stores-015 load returns null and save writes nothing when window is undefined", () => {
    const setItem = vi.spyOn(window.localStorage, "setItem");
    const getItem = vi.spyOn(window.localStorage, "getItem");
    vi.stubGlobal("window", undefined);
    expect(localCache.load()).toBeNull();
    expect(() => localCache.save(snap)).not.toThrow();
    expect(setItem).not.toHaveBeenCalled();
    expect(getItem).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
    expect(window.localStorage.getItem(KEY)).toBeNull();
  });

  it("stores-016 load returns null when reading storage throws", () => {
    vi.spyOn(window.localStorage, "getItem").mockImplementation(() => {
      throw new Error("denied");
    });
    expect(() => localCache.load()).not.toThrow();
    expect(localCache.load()).toBeNull();
  });

  it("stores-017 save swallows a quota error and leaves the stored value unchanged", () => {
    localCache.save(snap);
    const before = window.localStorage.getItem(KEY);
    vi.spyOn(window.localStorage, "setItem").mockImplementation(() => {
      throw new DOMException("quota", "QuotaExceededError");
    });
    expect(() => localCache.save({ ...snap, generatedAt: "later" })).not.toThrow();
    expect(window.localStorage.getItem(KEY)).toBe(before);
  });

  it("stores-018 load leaves a corrupt value in place", () => {
    window.localStorage.setItem(KEY, "{not json");
    expect(localCache.load()).toBeNull();
    expect(window.localStorage.getItem(KEY)).toBe("{not json");
  });

  it("stores-019 save stores extra keys verbatim and load projects them away", () => {
    localCache.save({ ...snap, extra: 1 } as TelemetrySnapshot);
    expect(window.localStorage.getItem(KEY)).toContain('"extra":1');
    const loaded = localCache.load();
    expect(loaded).toEqual(snap);
    expect(loaded).not.toHaveProperty("extra");
  });

  it("stores-020 touches only getItem and setItem on the one key, and nothing else", () => {
    const ls = window.localStorage;
    const setItem = vi.spyOn(ls, "setItem");
    const getItem = vi.spyOn(ls, "getItem");
    const removeItem = vi.spyOn(ls, "removeItem");
    const clear = vi.spyOn(ls, "clear");
    const key = vi.spyOn(ls, "key");
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);
    const log = vi.spyOn(console, "log").mockImplementation(() => {});
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const error = vi.spyOn(console, "error").mockImplementation(() => {});

    localCache.save(snap);
    localCache.load();

    expect(setItem).toHaveBeenCalledTimes(1);
    expect(setItem.mock.calls[0]![0]).toBe(KEY);
    expect(getItem).toHaveBeenCalledTimes(1);
    expect(getItem.mock.calls[0]![0]).toBe(KEY);
    expect(removeItem).not.toHaveBeenCalled();
    expect(clear).not.toHaveBeenCalled();
    expect(key).not.toHaveBeenCalled();
    expect(fetchSpy).not.toHaveBeenCalled();
    expect(log).not.toHaveBeenCalled();
    expect(warn).not.toHaveBeenCalled();
    expect(error).not.toHaveBeenCalled();
  });
});
