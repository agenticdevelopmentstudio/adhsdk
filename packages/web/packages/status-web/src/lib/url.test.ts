import { describe, it, expect } from "vitest";
import { PLACEHOLDER_URL } from "@adh-sdk/deploy-platform/engine";
import { endpointLabel, hostOf, siteNameForUrl } from "./url";

describe("a deploy-only monitor's placeholder URL", () => {
  it("is labelled by the monitor's name, not by \"https://\"", () => {
    expect(endpointLabel({ url: PLACEHOLDER_URL, name: "ai-processing-node" })).toBe("ai-processing-node · deploys only");
    expect(endpointLabel({ url: "https://api.example.test/health", name: "api" })).toBe("api.example.test");
  });

  it("never renames the site it belongs to", () => {
    expect(siteNameForUrl(PLACEHOLDER_URL)).toBeNull();
    expect(siteNameForUrl("https://api.example.test/health")).toBe("api.example.test");
  });
});

describe("hostOf", () => {
  it("url-001 returns the host without path, query or fragment", () => {
    expect(hostOf("https://adh.app/health?x=1#top")).toBe("adh.app");
  });
  it("url-002 lowercases the host and keeps a non-default port", () => {
    expect(hostOf("https://Example.COM:8443/a?b")).toBe("example.com:8443");
  });
  it("url-003 drops the default port", () => {
    expect(hostOf("https://example.com:443/")).toBe("example.com");
  });
  it("url-004 drops userinfo", () => {
    expect(hostOf("http://user:pw@host.test/")).toBe("host.test");
  });
  it("url-005 punycodes an internationalized host", () => {
    expect(hostOf("https://bücher.de/")).toBe("xn--bcher-kva.de");
  });
  it("url-006 keeps IPv6 brackets and port", () => {
    expect(hostOf("http://[::1]:8080/")).toBe("[::1]:8080");
  });
  it("url-007 returns an unparseable string unchanged without throwing", () => {
    expect(() => hostOf("example.com")).not.toThrow();
    expect(hostOf("example.com")).toBe("example.com");
  });
  it("url-008 returns the empty string unchanged without throwing", () => {
    expect(() => hostOf("")).not.toThrow();
    expect(hostOf("")).toBe("");
  });
  it("url-009 gives an empty host for scheme-like host:port input", () => {
    expect(hostOf("localhost:3000")).toBe("");
  });
  it("url-010 gives an empty host for mailto", () => {
    expect(hostOf("mailto:a@b.c")).toBe("");
  });
  it("url-011 gives an empty host for file URLs", () => {
    expect(hostOf("file:///tmp/x")).toBe("");
  });
  it("url-012 strips surrounding spaces", () => {
    expect(hostOf("  https://a.test  ")).toBe("a.test");
  });
  it("url-013 is deterministic and pure", () => {
    expect(hostOf("https://adh.app")).toBe("adh.app");
    expect(hostOf("https://adh.app")).toBe("adh.app");
  });
  it("url-014 gives no signal separating a fallback from a parsed host", () => {
    const a = hostOf("not a url");
    const b = hostOf("https://not-a-url.test");
    expect(a).toBe("not a url");
    expect(b).toBe("not-a-url.test");
    expect(typeof a).toBe("string");
    expect(typeof b).toBe("string");
  });
});
