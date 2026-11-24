import { describe, expect, it } from "vitest";
import { mixColor, oklabToSrgb, parseHex, srgbToOklab, toHex } from "./color";
import { EASE_NAMES, resolveEase } from "./ease";
import { applyPoint, fromTransform, IDENTITY, multiply, type Mat } from "./mat";
import { createPrng } from "./prng";

// One test per conformance vector in cookbook/avatar-animation-engine/math/conformance-test-vectors.md.
const near = (a: number, b: number, eps: number): void =>
  expect(Math.abs(a - b)).toBeLessThan(eps);
const nearArr = (got: readonly number[], want: readonly number[], eps: number): void => {
  expect(got).toHaveLength(want.length);
  got.forEach((v, i) => near(v, want[i]!, eps));
};

describe("avatar-engine math conformance vectors", () => {
  it("avatar-engine-math-001: parseHex/toHex round-trips every palette entry", () => {
    for (const hex of ["#00ff41", "#ff9500", "#ffd400", "#fffce0", "#ff2d2d",
                       "#4f7cff", "#5f7a64", "#4f6e57", "#33ccff", "#06140d"]) {
      expect(toHex(parseHex(hex))).toBe(hex);
    }
  });

  it("avatar-engine-math-002: parseHex rejects a fullwidth digit", () => {
    expect(() => parseHex("#０0ff41")).toThrow(/bad hex colour/);
  });

  it("avatar-engine-math-003: toHex renders a NaN channel as black", () => {
    expect(toHex([NaN, NaN, NaN])).toBe("#000000");
    expect(toHex([NaN, 1, 0])).toBe("#00ff00");
  });

  it("avatar-engine-math-004: OKLab round trip stays within 1e-5", () => {
    for (const hex of ["#00ff41", "#ff2d2d", "#4f7cff", "#000000", "#ffffff"]) {
      const rgb = parseHex(hex);
      nearArr(oklabToSrgb(srgbToOklab(rgb)), rgb, 1e-5);
    }
  });

  it("avatar-engine-math-005: OKLab L pins white to 1 and black to 0", () => {
    near(srgbToOklab(parseHex("#ffffff"))[0], 1, 1e-6);
    near(srgbToOklab(parseHex("#000000"))[0], 0, 1e-9);
  });

  it("avatar-engine-math-006: mix returns the endpoints exactly", () => {
    expect(mixColor("#00ff41", "#ff2d2d", 0)).toBe("#00ff41");
    expect(mixColor("#00ff41", "#ff2d2d", 1)).toBe("#ff2d2d");
  });

  it("avatar-engine-math-007: mix midpoint is the pinned OKLab #cead37 and stays saturated", () => {
    const mid = mixColor("#00ff41", "#ff2d2d", 0.5);
    expect(mid).toBe("#cead37");
    const [r, g, b] = parseHex(mid);
    expect(Math.max(r, g, b) - Math.min(r, g, b)).toBeGreaterThan(0.55);
  });

  it("avatar-engine-math-008: all 24 names resolve and pin both endpoints", () => {
    expect(EASE_NAMES).toHaveLength(24);
    for (const name of EASE_NAMES) {
      const e = resolveEase(name);
      near(e(0), 0, 1e-12);
      near(e(1), 1, 1e-12);
    }
  });

  it("avatar-engine-math-009: ease samples match the pinned table", () => {
    const table: Record<string, number[]> = {
      none: [0, 0.25, 0.5, 0.75, 1],
      "power1.in": [0, 0.0625, 0.25, 0.5625, 1],
      "power1.out": [0, 0.4375, 0.75, 0.9375, 1],
      "power1.inOut": [0, 0.125, 0.5, 0.875, 1],
      "power2.in": [0, 0.015625, 0.125, 0.421875, 1],
      "power2.out": [0, 0.578125, 0.875, 0.984375, 1],
      "power3.inOut": [0, 0.03125, 0.5, 0.96875, 1],
      "sine.in": [0, 0.07612046748871326, 0.2928932188134524, 0.6173165676349102, 1],
      "sine.out": [0, 0.3826834323650898, 0.7071067811865475, 0.9238795325112867, 1],
      "back.out": [0, 0.8174096875, 1.0876975, 1.0641365625, 1],
    };
    for (const [name, want] of Object.entries(table)) {
      nearArr([0, 0.25, 0.5, 0.75, 1].map((t) => resolveEase(name)(t)), want, 1e-12);
    }
  });

  it("avatar-engine-math-010: resolveEase rejects names outside the vocabulary", () => {
    for (const name of ["elastic.out", "back.in(2)", "power2", "back.out(2.2)"]) {
      expect(() => resolveEase(name)).toThrow(/unknown ease/);
    }
  });

  it("avatar-engine-math-011: identity is a no-op on either side", () => {
    const m: Mat = [2, 0, 0, 3, 10, 20];
    expect(multiply(IDENTITY, m)).toEqual(m);
    expect(multiply(m, IDENTITY)).toEqual(m);
  });

  it("avatar-engine-math-012: rotation about an absolute pivot leaves the pivot fixed", () => {
    const m = fromTransform({ rotation: 90, pivot: [200, 200] });
    nearArr(applyPoint(m, 200, 200), [200, 200], 1e-9);
    nearArr(applyPoint(m, 200, 100), [300, 200], 1e-9);
  });

  it("avatar-engine-math-013: scale about an absolute pivot", () => {
    const m = fromTransform({ scaleX: 2, scaleY: 2, pivot: [200, 200] });
    nearArr(m, [2, 0, 0, 2, -200, -200], 1e-9);
    nearArr(applyPoint(m, 300, 200), [400, 200], 1e-9);
  });

  it("avatar-engine-math-014: translate applies after the pivoted rotate and scale", () => {
    const m = fromTransform({ x: 5, y: 7, rotation: 180, scaleX: 2, scaleY: 2, pivot: [10, 10] });
    nearArr(applyPoint(m, 20, 10), [-5, 17], 1e-9);
  });

  it("avatar-engine-math-015: multiply composes parent then child", () => {
    const parent = fromTransform({ x: 100 });
    const child = fromTransform({ scaleX: 2, scaleY: 2, pivot: [0, 0] });
    nearArr(applyPoint(multiply(parent, child), 3, 4), [106, 8], 1e-9);
  });

  it("avatar-engine-math-016: seed 1 emits the pinned reference stream", () => {
    const p = createPrng(1);
    expect([p.next(), p.next(), p.next(), p.next(), p.next()]).toEqual([
      1144403687, 1290228702, 3651710282, 626043614, 3583050788,
    ]);
  });

  it("avatar-engine-math-017: a seed reproduces its stream", () => {
    const a = createPrng(0x9e3779b9);
    const b = createPrng(0x9e3779b9);
    for (let i = 0; i < 1000; i += 1) expect(a.next()).toBe(b.next());
  });

  it("avatar-engine-math-018: float stays in [0,1)", () => {
    const p = createPrng(42);
    for (let i = 0; i < 10_000; i += 1) {
      const f = p.float();
      expect(f).toBeGreaterThanOrEqual(0);
      expect(f).toBeLessThan(1);
    }
  });

  it("avatar-engine-math-019: signed is centred on zero and range stays in [lo,hi)", () => {
    const p = createPrng(7);
    let sum = 0;
    for (let i = 0; i < 20_000; i += 1) sum += p.signed(4);
    expect(Math.abs(sum / 20_000)).toBeLessThan(0.1);
    const q = createPrng(7);
    for (let i = 0; i < 1000; i += 1) {
      const v = q.range(2, 5);
      expect(v).toBeGreaterThanOrEqual(2);
      expect(v).toBeLessThan(5);
    }
  });

  it("avatar-engine-math-020: pick only returns members", () => {
    const p = createPrng(3);
    const items = ["a", "b", "c"];
    for (let i = 0; i < 5000; i += 1) expect(items).toContain(p.pick(items));
  });

  it("avatar-engine-math-021: pickOrUndefined on an empty array draws nothing", () => {
    const p = createPrng(3);
    expect(p.pickOrUndefined<number>([])).toBeUndefined();
    expect(p.pickOrUndefined<string>([])).toBeUndefined();
    expect(p.next()).toBe(createPrng(3).next());
  });

  it("avatar-engine-math-022: pickOrUndefined consumes the same stream as pick", () => {
    const items = ["a", "b", "c", "d", "e"];
    const a = createPrng(7);
    const b = createPrng(7);
    for (let i = 0; i < 200; i += 1) expect(b.pickOrUndefined(items)).toBe(a.pick(items));
  });

  it.skip("avatar-engine-math-023: Swift rejects 'abc#def' and a leading newline (Swift-only vector)", () => {
    // Platform-scoped to Swift; the web accepts both (vector 024).
  });

  it("avatar-engine-math-024: web parseHex accepts 'abc#def' and '\\n#fff'", () => {
    nearArr(parseHex("abc#def"), [0xab / 255, 0xcd / 255, 0xef / 255], 1e-12);
    expect(toHex(parseHex("abc#def"))).toBe("#abcdef");
    expect(toHex(parseHex("\n#fff"))).toBe("#ffffff");
  });

  it("avatar-engine-math-025: pick on an empty array throws naming the contract", () => {
    expect(() => createPrng(3).pick([])).toThrow(/Prng\.pick on an empty array/);
  });

  it("avatar-engine-math-026: applyPoint maps (1,1) through Mat(2,0,0,3,10,20) to (12,23)", () => {
    expect(applyPoint([2, 0, 0, 3, 10, 20], 1, 1)).toEqual([12, 23]);
  });

  it("avatar-engine-math-027: chance(p) agrees with float() < p in lockstep", () => {
    const a = createPrng(3);
    const b = createPrng(3);
    for (let i = 0; i < 1000; i += 1) expect(a.chance(0.5)).toBe(b.float() < 0.5);
  });

  it("avatar-engine-math-028: mix propagates the parseHex error for a bad endpoint", () => {
    expect(() => mixColor("#00ff41", "zz", 0.5)).toThrow("bad hex colour: zz");
  });
});
