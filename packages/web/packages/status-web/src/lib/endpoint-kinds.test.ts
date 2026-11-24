import { describe, expect, it } from "vitest";
import { endpointNeedsWiring, NON_DEPLOY_KINDS as ENGINE_NON_DEPLOY } from "@adh-sdk/deploy-platform/engine";
import { ENDPOINT_KINDS, NON_DEPLOY_KINDS, isEndpointKind, type EndpointKind } from "./endpoint-kinds";

describe("endpoint kinds", () => {
  it("endpoint-kinds-001: lists the six kinds in order", () => {
    expect([...ENDPOINT_KINDS]).toEqual(["http", "frontend", "admin", "health", "custom", "dns"]);
    expect(ENDPOINT_KINDS).toHaveLength(6);
  });
  it("endpoint-kinds-002: http is first", () => {
    expect(ENDPOINT_KINDS[0]).toBe("http");
  });
  it("endpoint-kinds-003: the guard accepts every kind", () => {
    for (const k of ENDPOINT_KINDS) expect(isEndpointKind(k)).toBe(true);
  });
  it("endpoint-kinds-004: the guard rejects non-members", () => {
    for (const k of ["tcp", "icmp", "mcp"]) expect(isEndpointKind(k)).toBe(false);
  });
  it("endpoint-kinds-005: the guard does not normalize case or whitespace", () => {
    for (const k of ["HTTP", " http", "http "]) expect(isEndpointKind(k)).toBe(false);
  });
  it("endpoint-kinds-006: the guard returns false for the empty string without throwing", () => {
    expect(() => isEndpointKind("")).not.toThrow();
    expect(isEndpointKind("")).toBe(false);
  });
  it("endpoint-kinds-007: the guard narrows a string to EndpointKind", () => {
    const k: string = "dns";
    if (isEndpointKind(k)) {
      const e: EndpointKind = k;
      expect(e).toBe("dns");
    } else {
      throw new Error("dns should be an endpoint kind");
    }
  });
  it.skip("endpoint-kinds-008: the kinds tuple is readonly (type error only; vitest does not run tsc)", () => {});
  it.skip("endpoint-kinds-009: EndpointKind rejects non-members (type error only; vitest does not run tsc)", () => {});
  it("endpoint-kinds-010: NON_DEPLOY_KINDS is health, custom, dns and a subset of the kinds", () => {
    expect([...NON_DEPLOY_KINDS]).toEqual(["health", "custom", "dns"]);
    for (const k of NON_DEPLOY_KINDS) expect(ENDPOINT_KINDS.includes(k as EndpointKind)).toBe(true);
  });
  it("endpoint-kinds-011: the engine wires only the deploy-backed kinds", () => {
    const wired = Object.fromEntries(ENDPOINT_KINDS.map((k) => [k, endpointNeedsWiring(k)]));
    expect(wired).toEqual({ http: true, frontend: true, admin: true, health: false, custom: false, dns: false });
  });
  it("endpoint-kinds-012: NON_DEPLOY_KINDS is re-exported, not restated", () => {
    expect(Object.is(NON_DEPLOY_KINDS, ENGINE_NON_DEPLOY)).toBe(true);
  });
});
