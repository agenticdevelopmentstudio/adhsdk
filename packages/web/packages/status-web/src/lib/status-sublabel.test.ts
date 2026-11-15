import { describe, it, expect } from "vitest";
import { buildSublabel } from "./status-sublabel";
import type { Row } from "./row-model";

const row = (w: string) => ({ statusWord: w }) as unknown as Row;
const rows = (w: string, n: number) => Array.from({ length: n }, () => row(w));

describe("buildSublabel", () => {
  it("sublabel-001: ok and all healthy", () => {
    expect(buildSublabel("ok", 12, 12, [])).toBe("12/12 endpoints healthy · no failed builds");
  });
  it("sublabel-002: ok and not all healthy", () => {
    expect(buildSublabel("ok", 4, 5, [])).toBe("5 endpoints monitored · no failed builds");
  });
  it("sublabel-003: ok ignores problems", () => {
    expect(buildSublabel("ok", 3, 3, [row("down")])).toBe("3/3 endpoints healthy · no failed builds");
  });
  it("sublabel-004: strict equality", () => {
    expect(buildSublabel("ok", 6, 5, [])).toBe("5 endpoints monitored · no failed builds");
  });
  it("sublabel-005: zero of zero is all healthy", () => {
    expect(buildSublabel("ok", 0, 0, [])).toBe("0/0 endpoints healthy · no failed builds");
  });
  it("sublabel-006: down and degraded phrases with separator", () => {
    expect(buildSublabel("warn", 0, 0, [row("degraded"), row("down"), row("down")])).toBe("2 down · 1 degraded");
  });
  it("sublabel-007: build failed singular and plural", () => {
    expect(buildSublabel("down", 0, 0, rows("build failed", 1))).toBe("1 failed build");
    expect(buildSublabel("down", 0, 0, rows("build failed", 2))).toBe("2 failed builds");
  });
  it("sublabel-008: deploy failed singular and plural", () => {
    expect(buildSublabel("down", 0, 0, rows("deploy failed", 1))).toBe("1 failed deploy");
    expect(buildSublabel("down", 0, 0, rows("deploy failed", 3))).toBe("3 failed deploys");
  });
  it("sublabel-009: deployment failed is stale deploys", () => {
    expect(buildSublabel("warn", 0, 0, rows("deployment failed", 2))).toBe("2 stale deploys");
  });
  it("sublabel-010: building is a stuck build", () => {
    expect(buildSublabel("warn", 0, 0, [row("building")])).toBe("1 stuck build");
  });
  it("sublabel-011: platform unreachable singular and plural", () => {
    expect(buildSublabel("down", 0, 0, rows("platform unreachable", 1))).toBe("1 platform unreachable");
    expect(buildSublabel("down", 0, 0, rows("platform unreachable", 2))).toBe("2 platforms unreachable");
  });
  it("sublabel-012: mapped phrases follow table order", () => {
    expect(buildSublabel("down", 0, 0, [row("building"), row("build failed"), row("down")])).toBe(
      "1 down · 1 failed build · 1 stuck build",
    );
  });
  it("sublabel-013: unmapped words verbatim after mapped, in first-seen order", () => {
    expect(buildSublabel("warn", 0, 0, [row("expired"), row("down"), row("cert warn"), row("expired")])).toBe(
      "1 down · 2 expired · 1 cert warn",
    );
  });
  it("sublabel-014: empty problems give empty string", () => {
    expect(buildSublabel("warn", 5, 5, [])).toBe("");
  });
  it("sublabel-015: matching is case-sensitive", () => {
    expect(buildSublabel("warn", 0, 0, [row("Down")])).toBe("1 Down");
  });
  it("sublabel-016: counts sum to problem count", () => {
    const problems = [
      ...rows("down", 2),
      ...rows("degraded", 1),
      ...rows("build failed", 1),
      ...rows("building", 1),
      ...rows("expired", 1),
      ...rows("cert warn", 1),
    ];
    expect(problems).toHaveLength(7);
    const out = buildSublabel("warn", 0, 0, problems);
    const total = out.split(" · ").reduce((s, p) => s + parseInt(p, 10), 0);
    expect(total).toBe(7);
  });
  it("sublabel-017: ignores count arguments when not ok", () => {
    expect(buildSublabel("down", 1, 9, [row("down")])).toBe("1 down");
    expect(buildSublabel("down", 9, 9, [row("down")])).toBe("1 down");
  });
  it("sublabel-018: does not mutate frozen input", () => {
    const problems = Object.freeze([Object.freeze(row("down")), Object.freeze(row("expired"))]) as unknown as Row[];
    expect(() => buildSublabel("warn", 0, 0, problems)).not.toThrow();
    expect(problems).toHaveLength(2);
    expect(problems[0].statusWord).toBe("down");
  });
});
