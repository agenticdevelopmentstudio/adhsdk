import { describe, it, expect, vi, afterEach } from "vitest";
import { projectKeyOf, uniqueByProject } from "./project-key";

afterEach(() => vi.restoreAllMocks());

describe("projectKeyOf", () => {
  it("project-key-001: formats platform|projectName", () => {
    expect(projectKeyOf({ platform: "railway", projectName: "api" })).toBe("railway|api");
  });
  it("project-key-002: keeps case and spaces", () => {
    expect(projectKeyOf({ platform: "Railway", projectName: " api " })).toBe("Railway| api ");
  });
  it("project-key-003: ignores extra fields", () => {
    const p = { platform: "vercel", projectName: "web", domain: "x.app", env: "prod" };
    expect(projectKeyOf(p)).toBe("vercel|web");
  });
  it("project-key-004: empty fields give a bare separator", () => {
    expect(projectKeyOf({ platform: "", projectName: "" })).toBe("|");
  });
  it("project-key-011: deterministic", () => {
    const p = { platform: "fly", projectName: "svc" };
    expect(projectKeyOf(p)).toBe("fly|svc");
    expect(projectKeyOf(p)).toBe("fly|svc");
  });
});

describe("uniqueByProject", () => {
  it("project-key-005: first seen wins and identity is preserved", () => {
    const A = { platform: "railway", projectName: "api", env: "production" };
    const B = { platform: "railway", projectName: "api", env: "staging" };
    const C = { platform: "railway", projectName: "api", env: "testing" };
    const out = uniqueByProject([A, B, C]);
    expect(out).toHaveLength(1);
    expect(out[0]).toBe(A);
  });
  it("project-key-006: preserves relative order", () => {
    const X = { platform: "vercel", projectName: "web" };
    const Y = { platform: "railway", projectName: "api" };
    const Z = { platform: "vercel", projectName: "web" };
    const W = { platform: "railway", projectName: "db" };
    const out = uniqueByProject([X, Y, Z, W]);
    expect(out).toHaveLength(3);
    expect(out[0]).toBe(X);
    expect(out[1]).toBe(Y);
    expect(out[2]).toBe(W);
  });
  it("project-key-007: returns a new array without mutating input", () => {
    const X = { platform: "vercel", projectName: "web" };
    const input = [X];
    const out = uniqueByProject(input);
    expect(out).not.toBe(input);
    expect(input).toHaveLength(1);
    expect(input[0]).toBe(X);
  });
  it("project-key-008: keys differing by case are both kept", () => {
    const out = uniqueByProject([
      { platform: "railway", projectName: "api" },
      { platform: "Railway", projectName: "api" },
    ]);
    expect(out).toHaveLength(2);
  });
  it("project-key-009: empty list gives empty list", () => {
    expect(uniqueByProject([])).toEqual([]);
  });
  it("project-key-010: each call is independent", () => {
    const X = { platform: "vercel", projectName: "web" };
    expect(uniqueByProject([X])).toEqual([X]);
    expect(uniqueByProject([X])).toEqual([X]);
  });
  it("project-key-014: no reordering toward production", () => {
    const S = { platform: "railway", projectName: "api", env: "staging" };
    const P = { platform: "railway", projectName: "api", env: "production" };
    const out = uniqueByProject([S, P]);
    expect(out).toHaveLength(1);
    expect(out[0]).toBe(S);
  });
});

describe("purity and shared use", () => {
  it("project-key-012: no throw, no console, network or storage activity", () => {
    const log = vi.spyOn(console, "log");
    const warn = vi.spyOn(console, "warn");
    const error = vi.spyOn(console, "error");
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);
    const setItem = vi.spyOn(Storage.prototype, "setItem");
    const p = { platform: "a", projectName: "b" };
    expect(() => {
      projectKeyOf(p);
      uniqueByProject([p, p]);
    }).not.toThrow();
    expect(log).not.toHaveBeenCalled();
    expect(warn).not.toHaveBeenCalled();
    expect(error).not.toHaveBeenCalled();
    expect(fetchSpy).not.toHaveBeenCalled();
    expect(setItem).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
  it.skip("project-key-013: spans the review view and the provider components; needs their rendered integration, not this module alone", () => {});
});
