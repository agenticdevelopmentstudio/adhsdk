import { describe, it, expect } from "vitest";
import {
  deployStatusColor,
  deployStatusLabel,
  platformColor,
  platformGlyph,
  platformLabel,
  platformLabelShort,
} from "./deploy-display";

const KNOWN = ["vercel", "cloudflare-pages", "railway", "http", "dns", "crunchy", "glitchtip"];
const t = (n: string) => `var(--color-${n})`;

describe("deploy-display", () => {
  it("deploy-display-001 vercel glyph", () => {
    expect(platformGlyph("vercel")).toBe("▲");
  });
  it("deploy-display-002 glitchtip glyph uses text presentation", () => {
    expect(platformGlyph("glitchtip")).toBe("⚠︎");
    expect(platformGlyph("glitchtip")).toHaveLength(2);
  });
  it("deploy-display-003 unknown platform glyph falls back", () => {
    expect(platformGlyph("netlify")).toBe("◆");
  });
  it("deploy-display-004 empty platform glyph falls back", () => {
    expect(platformGlyph("")).toBe("◆");
  });
  it("deploy-display-005 remaining glyphs", () => {
    const got = ["cloudflare-pages", "railway", "http", "dns", "crunchy"].map(platformGlyph);
    expect(got).toEqual(["☁", "⬢", "◉", "⌖", "⛁"]);
  });
  it("deploy-display-006 glyph lookup is case sensitive", () => {
    expect(platformGlyph("Vercel")).toBe("◆");
  });
  it("deploy-display-007 platform colors", () => {
    const got = ["vercel", "cloudflare-pages", "railway", "http", "dns"].map(platformColor);
    expect(got).toEqual([
      t("apt-text"),
      t("apt-cat-orange"),
      t("apt-cat-purple"),
      t("apt-cat-teal"),
      t("apt-cat-indigo"),
    ]);
  });
  it("deploy-display-008 crunchy shares http color", () => {
    expect(platformColor("crunchy")).toBe(platformColor("http"));
  });
  it("deploy-display-009 glitchtip color is orange", () => {
    expect(platformColor("glitchtip")).toBe(t("apt-cat-orange"));
  });
  it("deploy-display-010 unknown platform color is muted", () => {
    expect(platformColor("netlify")).toBe(t("apt-text-muted"));
  });
  it("deploy-display-011 known platforms use theme roles outside env hues", () => {
    for (const k of KNOWN) {
      const c = platformColor(k);
      expect(c).toMatch(/^var\(--color-apt-[a-z-]+\)$/);
      for (const env of ["apt-cat-blue", "apt-cat-violet", "apt-cat-pink"]) {
        expect(c).not.toBe(t(env));
      }
    }
  });
  it("deploy-display-012 cloudflare label", () => {
    expect(platformLabel("cloudflare-pages")).toBe("CLOUDFLARE");
  });
  it("deploy-display-013 glitchtip label falls back to upper-case", () => {
    expect(platformLabel("glitchtip")).toBe("GLITCHTIP");
  });
  it("deploy-display-014 fly-io label upper-cases", () => {
    expect(platformLabel("fly-io")).toBe("FLY-IO");
  });
  it("deploy-display-015 short label overrides", () => {
    expect(platformLabelShort("cloudflare-pages")).toBe("CF");
    expect(platformLabelShort("crunchy")).toBe("CB");
  });
  it("deploy-display-016 short label falls back to table label", () => {
    expect(platformLabelShort("railway")).toBe("RAILWAY");
  });
  it("deploy-display-017 short label falls back to upper-case", () => {
    expect(platformLabelShort("netlify")).toBe("NETLIFY");
  });
  it("deploy-display-018 status colors", () => {
    expect([deployStatusColor("success"), deployStatusColor("failed"), deployStatusColor("building")]).toEqual([
      t("apt-green"),
      t("apt-red"),
      t("apt-gold"),
    ]);
  });
  it("deploy-display-019 unknown status is muted", () => {
    expect(deployStatusColor("unknown")).toBe(t("apt-text-muted"));
  });
  it("deploy-display-020 unlisted status falls back to canceled gold", () => {
    expect(deployStatusColor("rolling-back")).toBe(t("apt-gold"));
    expect(deployStatusColor("rolling-back")).toBe(deployStatusColor("canceled"));
  });
  it("deploy-display-021 success and failed labels", () => {
    expect(deployStatusLabel("success")).toBe("ready");
    expect(deployStatusLabel("failed")).toBe("FAILED");
  });
  it("deploy-display-022 in-flight and canceled labels", () => {
    expect(["building", "queued", "canceled"].map(deployStatusLabel)).toEqual(["building", "queued", "canceled"]);
  });
  it("deploy-display-023 unknown status label", () => {
    expect(deployStatusLabel("unknown")).toBe("outcome unknown");
  });
  it("deploy-display-024 unrecognized status passes through", () => {
    expect(deployStatusLabel("PROMOTED")).toBe("PROMOTED");
  });
  it("deploy-display-025 exports are pure", () => {
    const fns: Array<[(s: string) => string, string]> = [
      [platformGlyph, "vercel"],
      [platformColor, "dns"],
      [platformLabel, "fly-io"],
      [platformLabelShort, "crunchy"],
      [deployStatusColor, "failed"],
      [deployStatusLabel, "success"],
    ];
    for (const [fn, arg] of fns) expect(fn(arg)).toBe(fn(arg));
  });
});
