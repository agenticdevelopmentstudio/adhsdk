import { describe, it, expect, vi } from "vitest";
import {
  COLORS,
  DEPLOY_COLORS,
  ENV_COLORS,
  HEALTH_COLORS,
  OVERALL_COLORS,
  PALETTE,
  TINT,
  envBadgeLabel,
  envColor,
} from "./colors";

const DIM = "var(--color-apt-text-dim)";

describe("colors", () => {
  it("colors-001 HEALTH_COLORS.down is red", () => {
    expect(HEALTH_COLORS.down).toBe("var(--color-apt-red)");
  });
  it("colors-002 HEALTH_COLORS.unknown is caution gold", () => {
    expect(HEALTH_COLORS.unknown).toBe("var(--color-apt-gold)");
  });
  it("colors-003 OVERALL_COLORS operational and major_outage", () => {
    expect(OVERALL_COLORS.operational).toBe("var(--color-apt-green)");
    expect(OVERALL_COLORS.major_outage).toBe("var(--color-apt-red)");
  });
  it("colors-004 in-flight and canceled deploys are gold", () => {
    for (const k of ["building", "queued", "canceled"]) {
      expect(DEPLOY_COLORS[k]).toBe("var(--color-apt-gold)");
    }
  });
  it("colors-005 DEPLOY_COLORS.unknown is muted", () => {
    expect(DEPLOY_COLORS.unknown).toBe("var(--color-apt-text-muted)");
  });
  it("colors-006 missing deploy key is undefined", () => {
    expect(DEPLOY_COLORS["nonexistent"]).toBeUndefined();
  });
  it("colors-007 envColor staging is violet", () => {
    expect(envColor("staging")).toBe("var(--color-apt-cat-violet)");
  });
  it("colors-008 envColor falls back for nullish, empty and unknown", () => {
    for (const v of [null, undefined, "", "preview"]) {
      expect(envColor(v)).toBe(DIM);
    }
  });
  it("colors-009 envColor is case sensitive", () => {
    expect(envColor("Production")).toBe(DIM);
  });
  it("colors-010 envBadgeLabel known envs", () => {
    expect(envBadgeLabel("production")).toBe("PROD");
    expect(envBadgeLabel("staging")).toBe("STAG");
    expect(envBadgeLabel("testing")).toBe("TEST");
  });
  it("colors-011 envBadgeLabel upper-cases unknown", () => {
    expect(envBadgeLabel("preview")).toBe("PREVIEW");
  });
  it("colors-012 envBadgeLabel of empty string is empty", () => {
    expect(envBadgeLabel("")).toBe("");
  });
  it("colors-013 env hues avoid the status triad", () => {
    const banned = ["var(--color-apt-green)", "var(--color-apt-gold)", "var(--color-apt-red)"];
    for (const v of Object.values(ENV_COLORS)) expect(banned).not.toContain(v);
  });
  it("colors-014 PALETTE.amber is gold", () => {
    expect(PALETTE.amber).toBe("var(--color-apt-gold)");
  });
  it("colors-015 surfacePane and surfaceHover collapse", () => {
    expect(COLORS.surfacePane === COLORS.surfaceHover).toBe(true);
    expect(COLORS.surfacePane).toBe("var(--color-apt-surface-2)");
  });
  it("colors-016 textSoft mix", () => {
    expect(COLORS.textSoft).toBe(
      "color-mix(in srgb, var(--color-apt-text) 80%, var(--color-apt-text-muted))",
    );
  });
  it("colors-017 amberBgMid", () => {
    expect(COLORS.amberBgMid).toBe("color-mix(in srgb, var(--color-apt-gold) 30%, var(--color-apt-bg))");
  });
  it("colors-018 amberLight exists, no greenLight or redLight", () => {
    expect(COLORS.amberLight).toBe("var(--color-apt-gold-bright)");
    expect(Object.keys(COLORS)).not.toContain("greenLight");
    expect(Object.keys(COLORS)).not.toContain("redLight");
  });
  it("colors-019 TINT.amberGlow", () => {
    expect(TINT.amberGlow).toBe("color-mix(in srgb, var(--color-apt-gold) 45%, transparent)");
  });
  it("colors-020 TINT.redBgStrong", () => {
    expect(TINT.redBgStrong).toBe("color-mix(in srgb, var(--color-apt-red) 16%, transparent)");
  });
  it("colors-021 TINT.blueBgMed", () => {
    expect(TINT.blueBgMed).toBe("color-mix(in srgb, var(--color-apt-blue) 14%, transparent)");
  });
  it("colors-022 theme-independent shadow and white ghost", () => {
    expect(TINT.shadowStrong).toBe("color-mix(in srgb, black 60%, transparent)");
    expect(TINT.whiteGhost).toBe("color-mix(in srgb, white 2%, transparent)");
  });
  it("colors-023 COLORS.white and dimBlue", () => {
    expect(COLORS.white).toBe("white");
    expect(COLORS.dimBlue).toBe("var(--color-apt-text-dim)");
  });
  it("colors-024 status tables hold token strings with no hex", () => {
    for (const t of [HEALTH_COLORS, OVERALL_COLORS, DEPLOY_COLORS]) {
      for (const v of Object.values(t)) {
        expect(v.startsWith("var(--color-apt-")).toBe(true);
        expect(v).not.toContain("#");
      }
    }
  });
  it("colors-025 envColor is pure", () => {
    const spies = [
      vi.spyOn(console, "log"),
      vi.spyOn(console, "warn"),
      vi.spyOn(console, "error"),
      vi.spyOn(globalThis, "fetch").mockImplementation(() => Promise.reject(new Error("no"))),
      vi.spyOn(Storage.prototype, "getItem"),
      vi.spyOn(Storage.prototype, "setItem"),
    ];
    expect(envColor("testing")).toBe("var(--color-apt-cat-pink)");
    expect(envColor("testing")).toBe("var(--color-apt-cat-pink)");
    for (const s of spies) expect(s).not.toHaveBeenCalled();
    vi.restoreAllMocks();
  });
  it("colors-026 envColor inherited key returns a function", () => {
    expect(typeof envColor("constructor")).toBe("function");
  });
});
