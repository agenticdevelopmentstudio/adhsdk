import { describe, it, expect } from "vitest";
import { slugify } from "./slug";

describe("slugify", () => {
  it("slug-001: lowercases and hyphenates spaces", () => {
    expect(slugify("Production Sites")).toBe("production-sites");
  });
  it("slug-002: trims surrounding whitespace", () => {
    expect(slugify("  Hello World  ")).toBe("hello-world");
  });
  it("slug-003: collapses separator runs", () => {
    expect(slugify("a -- b__c")).toBe("a-b-c");
  });
  it("slug-004: dots become hyphens", () => {
    expect(slugify("status.example.com")).toBe("status-example-com");
  });
  it("slug-005: strips leading and trailing hyphens", () => {
    expect(slugify("--Edge!!")).toBe("edge");
  });
  it("slug-006: non-ASCII letters are separators", () => {
    expect(slugify("Café Menu")).toBe("caf-menu");
  });
  it("slug-007: input with no ASCII alphanumerics gives empty string", () => {
    for (const s of ["", "   ", "---", "日本"]) {
      expect(() => slugify(s)).not.toThrow();
      expect(slugify(s)).toBe("");
    }
  });
  it("slug-008: idempotent", () => {
    const once = slugify("My Group #1");
    expect(once).toBe("my-group-1");
    expect(slugify(once)).toBe(once);
  });
  it("slug-009: does not guarantee uniqueness", () => {
    for (const s of ["A B", "a-b", "a_b"]) expect(slugify(s)).toBe("a-b");
  });
  it("slug-010: digits are kept", () => {
    expect(slugify("Server 42")).toBe("server-42");
  });
  it("slug-011: synchronous and repeatable", () => {
    const r = slugify("x");
    expect(typeof r).toBe("string");
    expect(r).toBe("x");
    expect(slugify("x")).toBe("x");
  });
});
