import { describe, it, expect } from "vitest";
import { shortSha, commitFirstLine, plural } from "./format";

describe("format conformance vectors", () => {
  it("format-001: shortSha takes the 7-char prefix", () => {
    expect(shortSha("abcdef1234567")).toBe("abcdef1");
  });
  it("format-002: shortSha leaves a short input unchanged", () => {
    expect(shortSha("abc")).toBe("abc");
  });
  it("format-003: shortSha gives no result for absent or empty input", () => {
    expect(shortSha(null)).toBeNull();
    expect(shortSha(undefined)).toBeNull();
    expect(shortSha("")).toBeNull();
  });
  it("format-004: shortSha does not validate", () => {
    expect(shortSha("  zz-not-hex")).toBe("  zz-no");
  });
  it("format-005: commitFirstLine returns the subject", () => {
    expect(commitFirstLine("subject\n\nbody text")).toBe("subject");
  });
  it("format-006: commitFirstLine returns a one-line message whole", () => {
    expect(commitFirstLine("just one line")).toBe("just one line");
  });
  it("format-007: commitFirstLine gives no result for absent or empty input", () => {
    expect(commitFirstLine(null)).toBeNull();
    expect(commitFirstLine(undefined)).toBeNull();
    expect(commitFirstLine("")).toBeNull();
  });
  it("format-008: commitFirstLine caps at 200 by default", () => {
    expect(commitFirstLine("x".repeat(250))).toHaveLength(200);
  });
  it("format-009: commitFirstLine caps at max with no ellipsis", () => {
    expect(commitFirstLine("x".repeat(250), 10)).toBe("xxxxxxxxxx");
  });
  it("format-010: commitFirstLine leaves a line under the cap", () => {
    expect(commitFirstLine("short", 200)).toBe("short");
  });
  it("format-011: commitFirstLine splits on LF only", () => {
    expect(commitFirstLine("subject\r\nbody")).toBe("subject\r");
  });
  it("format-012: commitFirstLine returns an empty subject", () => {
    expect(commitFirstLine("\nbody")).toBe("");
  });
  it("format-013: plural uses the singular at one", () => {
    expect(plural(1, "site")).toBe("1 site");
  });
  it("format-014: plural defaults the plural form to noun + s", () => {
    expect(plural(3, "site")).toBe("3 sites");
  });
  it("format-015: plural uses the plural at zero", () => {
    expect(plural(0, "project")).toBe("0 projects");
  });
  it("format-016: plural uses the plural at -1", () => {
    expect(plural(-1, "site")).toBe("-1 sites");
  });
  it("format-017: plural honors an explicit plural form", () => {
    expect(plural(2, "person", "people")).toBe("2 people");
  });
  it("format-018: plural renders the count with default number conversion", () => {
    expect(plural(1000, "site")).toBe("1000 sites");
    expect(plural(1.5, "site")).toBe("1.5 sites");
  });
  it("format-019: plural applies the English rule", () => {
    expect(plural(21, "site")).toBe("21 sites");
  });
  it("format-020: commitFirstLine cuts by UTF-16 code unit", () => {
    const out = commitFirstLine("ab\u{1F600}cd", 3)!;
    expect(out).toHaveLength(3);
    expect(out).toBe("ab\ud83d");
  });
  it("format-021: every export is pure and synchronous", () => {
    expect(plural(2, "site")).toBe(plural(2, "site"));
    expect(shortSha("abcdef1234567")).toBe(shortSha("abcdef1234567"));
    expect(commitFirstLine("a\nb")).toBe(commitFirstLine("a\nb"));
    expect(plural(2, "site")).not.toBeInstanceOf(Promise);
    expect(shortSha("abcdef1234567")).not.toBeInstanceOf(Promise);
    expect(commitFirstLine("a\nb")).not.toBeInstanceOf(Promise);
  });
});

describe("shortSha", () => {
  it("returns the first 7 chars of a hash, or null", () => {
    expect(shortSha("abcdef1234567")).toBe("abcdef1");
    expect(shortSha("abc")).toBe("abc"); // shorter than 7 → unchanged
    expect(shortSha(null)).toBeNull();
    expect(shortSha(undefined)).toBeNull();
    expect(shortSha("")).toBeNull(); // empty → no commit
  });
});

describe("commitFirstLine", () => {
  it("returns the subject line (first line), or null", () => {
    expect(commitFirstLine("subject\n\nbody text")).toBe("subject");
    expect(commitFirstLine("just one line")).toBe("just one line");
    expect(commitFirstLine(null)).toBeNull();
    expect(commitFirstLine(undefined)).toBeNull();
    expect(commitFirstLine("")).toBeNull();
  });

  it("caps the subject at `max` chars (default 200)", () => {
    const long = "x".repeat(250);
    expect(commitFirstLine(long)).toHaveLength(200);
    expect(commitFirstLine(long, 10)).toHaveLength(10);
    expect(commitFirstLine("short", 200)).toBe("short");
  });
});
