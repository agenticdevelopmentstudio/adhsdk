import { describe, it, expect } from "vitest";
import { inEnvScope, matchesQuery } from "./filter";

describe("matchesQuery", () => {
  it("matches everything on an empty/blank query", () => {
    expect(matchesQuery("anything", "")).toBe(true);
    expect(matchesQuery("anything", "   ")).toBe(true);
  });

  it("is case-insensitive substring", () => {
    expect(matchesQuery("staging.adh deploy failed", "ADH")).toBe(true);
    expect(matchesQuery("staging.adh", "prod")).toBe(false);
  });

  it("requires all tokens (AND)", () => {
    expect(matchesQuery("testing.admin.adh deploy failed", "testing failed")).toBe(true);
    expect(matchesQuery("testing.admin.adh deploy failed", "testing deployed")).toBe(false);
  });
});

// The same cases status-server's board-view test pins for `inScope`: the rows kept here and
// the server's `board.scope` headline must agree on every one.
describe("inEnvScope", () => {
  it("keeps everything when every environment is selected", () => {
    expect(inEnvScope(null, "production")).toBe(true);
    expect(inEnvScope(null, null)).toBe(true);
  });

  it.each([null, undefined, ""])("never hides an environment-less row (%j)", (environment) => {
    expect(inEnvScope(new Set(), environment)).toBe(true);
    expect(inEnvScope(new Set(["staging"]), environment)).toBe(true);
  });

  it("keeps a row only when its environment is selected", () => {
    expect(inEnvScope(new Set(["staging"]), "staging")).toBe(true);
    expect(inEnvScope(new Set(["staging"]), "production")).toBe(false);
  });
});
