import { describe, expect, it } from "vitest";
import character from "@character/character.json";
import rig from "@character/rig.json";
import poses from "@character/poses.json";
import timelines from "@character/timelines.json";
import behavior from "@character/behavior.json";
import sayings from "@character/sayings.json";
import { loadConfig } from "../config/load";
import { disc, ring } from "../path/build";
import { parsePath } from "../path/parse";
import { createChannels } from "../runtime/channels";
import { buildScene, compose, cropList, seedChannels, type DisplayItem } from "./rig";

const config = loadConfig({ character, rig, poses, timelines, behavior, sayings });

const fresh = () => {
  const scene = buildScene(config);
  const channels = createChannels();
  seedChannels(config, channels);
  return { scene, channels };
};

describe("compose", () => {
  it("emits every shape node once, in declaration order", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    const ids = list.map((i) => i.id);
    expect(ids).toEqual([
      "browLeft", "browRight",
      "antennaLeft", "antennaRight",
      "mouth", "descender",
      "eyeLeftBg", "eyeLeftRing", "irisLeft",
      "eyeRightBg", "eyeRightRing", "irisRight",
      "pinprickLeft", "pinprickRight",
    ]);
    // Depth-first through `root` in declaration order — so each eye's background
    // comes before its ring, and both come before the iris. This list is the
    // one `scrape.ts` (Task 22) emits in, and it is the paint order, so a
    // reordering here is a visual change and the differ treats it as a hard
    // failure rather than a tolerance.
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("places the left eye ring at its rest centre", () => {
    const { scene, channels } = fresh();
    const item = compose(scene, channels).find((i) => i.id === "eyeLeftRing")!;
    // The ring path is authored around the eye centre in local space and the
    // matrix is identity-at-rest, so the composed centre is the authored centre.
    expect(item.m).toEqual([1, 0, 0, 1, 0, 0]);
    expect(item.kind).toBe("MCCCCZMCCCCZ");
  });

  it("composes a parent transform into its children", () => {
    const { scene, channels } = fresh();
    channels.set("body.rotation", 90);
    const item = compose(scene, channels).find((i) => i.id === "irisLeft")!;
    const [a, b, c, d] = item.m;
    expect(Math.abs(a - 0)).toBeLessThan(1e-9);
    expect(Math.abs(b - 1)).toBeLessThan(1e-9);
    expect(Math.abs(c + 1)).toBeLessThan(1e-9);
    expect(Math.abs(d - 0)).toBeLessThan(1e-9);
  });

  it("turns the whole glyph about the character's centre, not the canvas origin", () => {
    // The idle fidget's sway and breath drive the ROOT layer, and the original
    // states both with `svgOrigin` at the rig's pivot. A root with no pivot of
    // its own turns the glyph about (0, 0) instead, which reads as the whole
    // character sliding rather than breathing — 18 design units of it on the
    // mouth, at nothing more than a 3.5 degree sway and a 1.035 swell.
    const { scene, channels } = fresh();
    const centre = config.rig.root.transform?.pivot;
    expect(centre).toEqual([200, 200]);
    const [px, py] = centre!;

    const sway = config.behavior.idleFidget.sway;
    const breath = config.behavior.idleFidget.breath;
    expect(config.expand(sway.channel)).toEqual(["idle.rotation"]);
    for (const ch of config.expand(sway.channel)) channels.set(ch, sway.amplitude);
    for (const ch of config.expand(breath.channel)) channels.set(ch, breath.to);

    // The centre is the fixed point of a turn taken about it, at every depth.
    for (const id of ["mouth", "browLeft", "irisRight"]) {
      const [a, b, c, d, e, f] = compose(scene, channels).find((i) => i.id === id)!.m;
      expect(a * px + c * py + e).toBeCloseTo(px, 9);
      expect(b * px + d * py + f).toBeCloseTo(py, 9);
    }
  });

  it("pins the multiply argument order — parent-then-local, not local-then-parent", () => {
    // multiply(parent, local) and multiply(local, parent) agree whenever either
    // operand is identity, which every node but the root is at rest — a single
    // rotated ancestor isn't enough to tell them apart either, because a lone
    // rotation still leaves the translation `e`/`f` matching both orders. Two
    // ancestors are needed: a ROTATED one (body) and, further down the chain, a
    // TRANSLATED one (face) whose own pivot is off-centre. `a,b,c,d` (the linear
    // part) come out identical under either argument order — `e` and `f` are
    // the ONLY pair that discriminates, which is exactly why the existing
    // parent-transform test above, which never checks them, missed this. Do not
    // "simplify" this back down to a,b,c,d.
    const { scene, channels } = fresh();
    channels.set("body.rotation", 90);
    channels.set("face.y", 10);
    const [a, b, c, d, e, f] = compose(scene, channels).find((i) => i.id === "irisLeft")!.m;
    expect(a).toBeCloseTo(0, 9);
    expect(b).toBeCloseTo(1, 9);
    expect(c).toBeCloseTo(-1, 9);
    expect(d).toBeCloseTo(0, 9);
    expect(e).toBeCloseTo(390, 9);
    expect(f).toBeCloseTo(0, 9);
  });

  it("squashes only the eyes when eye.scaleY is driven", () => {
    const { scene, channels } = fresh();
    channels.set("eyeLeftRing.scaleY", 0.1);
    const list = compose(scene, channels);
    expect(list.find((i) => i.id === "eyeLeftRing")!.m[3]).toBeCloseTo(0.1, 12);
    expect(list.find((i) => i.id === "eyeRightRing")!.m[3]).toBe(1);
  });

  it("resolves @body late-bound ink through body.ink", () => {
    // body.ink names a PALETTE key; every "@body" ink resolves through it, which
    // is how one channel recolours the whole face.
    const { scene, channels } = fresh();
    channels.set("body.ink", "red");
    const list = compose(scene, channels);
    expect(list.find((i) => i.id === "mouth")!.paint.ink).toBe("#ff2d2d");
    expect(list.find((i) => i.id === "browLeft")!.paint.ink).toBe("#ff2d2d");
    // …but a node whose ink names a literal palette entry is untouched by it.
    expect(list.find((i) => i.id === "irisLeft")!.paint.ink).toBe("#33ccff");
  });

  it("takes stroke-vs-fill and width from the ink, not the shape", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    const mouth = list.find((i) => i.id === "mouth")!;
    expect(mouth.paint.fill).toBe(false);
    expect(mouth.paint.width).toBe(8);
    const brow = list.find((i) => i.id === "browLeft")!;
    expect(brow.paint.width).toBe(5);
    expect(list.find((i) => i.id === "irisLeft")!.paint.fill).toBe(true);
  });

  it("keeps a fully transparent node in the list", () => {
    const { scene, channels } = fresh();
    channels.set("pinprickLeft.alpha", 0);
    const list = compose(scene, channels);
    const item = list.find((i) => i.id === "pinprickLeft")!;
    expect(item.paint.alpha).toBe(0);
  });

  it("takes a driven mouth path straight off mouth.shape", () => {
    const { scene, channels } = fresh();
    channels.set("mouth.shape", "M189,235L200,235L211,235");
    const item = compose(scene, channels).find((i) => i.id === "mouth")!;
    expect(item.d).toBe("M189,235L200,235L211,235");
    expect(item.kind).toBe("MLL");
  });

  it("rebuilds a bend-driven antenna from its points and .bend", () => {
    // The antennae have NO .shape channel — two authorities over one node's
    // geometry is exactly how a bend stops bending. `bend` moves the control
    // points, and it moves them by exactly what the channel holds: the inward
    // damp is applied where the value is WRITTEN (`CharacterConfig.respond`),
    // never here, because the original damps a tween's endpoints and lerps the
    // paths between them. A channel set by hand is therefore already rendered.
    const { scene, channels } = fresh();
    const rest = compose(scene, channels).find((i) => i.id === "antennaLeft")!.d;
    channels.set("antennaLeft.bend", 10);
    const out = compose(scene, channels).find((i) => i.id === "antennaLeft")!;
    expect(out.kind).toBe("MC");
    expect(out.d).not.toBe(rest);
    // weights [0, 0.3, 0.8, 1] on x, undamped: the anchor does not move and the
    // tip takes the whole offset.
    // `points` is flat [x0,y0,x1,y1,…]: index 0 is the M anchor, index 3 the tip.
    const pts = parsePath(out.d).points;
    expect(pts[0]).toBeCloseTo(183, 12);
    expect(pts[6]).toBeCloseTo(179 + 10, 12);
  });
});

describe("variants", () => {
  it("applies the optical cut to shapes and inks, and nothing else", () => {
    const { channels } = fresh();
    const plain = compose(buildScene(config), channels);
    const optical = compose(buildScene(config, "optical"), channels);

    // Same nodes, same order, same transforms — a variant is a size cut of the
    // anatomy, not a different rig shape.
    expect(optical.map((i) => i.id)).toEqual(plain.map((i) => i.id));
    expect(optical.map((i) => i.m)).toEqual(plain.map((i) => i.m));

    const by = (list: readonly DisplayItem[], id: string) => list.find((i) => i.id === id)!;
    expect(by(plain, "mouth").paint.width).toBe(8);
    expect(by(optical, "mouth").paint.width).toBe(13);
    expect(by(plain, "browLeft").paint.width).toBe(5);
    expect(by(optical, "browLeft").paint.width).toBe(9);

    // 35 - 13 = 22: the eye interior shrinks by exactly the extra band, which is
    // the arithmetic `OlyloMark.Weights.innerR` used to do in Swift.
    expect(by(optical, "eyeLeftBg").d).toBe(disc(152, 200, 22));
    expect(by(optical, "irisLeft").d).toBe(disc(152, 200, 10));

    // The ring is FILLED, so its weight is `band` and its ink has no width to
    // patch. Stroking it would paint 23..39 instead of 27..35 — the defect this
    // group of assertions exists to catch.
    expect(by(plain, "eyeLeftRing").paint.fill).toBe(true);
    expect(by(plain, "eyeLeftRing").paint.width).toBeUndefined();
    expect(by(plain, "eyeLeftRing").d).toBe(ring(152, 200, 35, 8));
    expect(by(optical, "eyeLeftRing").d).toBe(ring(152, 200, 35, 13));

    // The alignment invariant, asserted rather than trusted: each antenna's
    // inner edge lands on its eye's inner edge and its outer edge on the outer,
    // at BOTH weights. This is the one thing the four hand-written points in
    // `character.json` have to get right.
    const antennaX = (list: readonly DisplayItem[], id: string) =>
      parsePath(by(list, id).d).points[0]!;
    expect(antennaX(plain, "antennaLeft") + 8 / 2).toBeCloseTo(152 + 35, 9);
    expect(antennaX(optical, "antennaLeft") + 13 / 2).toBeCloseTo(152 + 35, 9);
    expect(antennaX(plain, "antennaRight") - 8 / 2).toBeCloseTo(248 - 35, 9);
    expect(antennaX(optical, "antennaRight") - 13 / 2).toBeCloseTo(248 - 35, 9);

    // The pinpricks carry no variant entry, so they are byte-identical.
    expect(by(optical, "pinprickLeft")).toEqual(by(plain, "pinprickLeft"));
  });

  it("throws on an unknown variant rather than silently rendering the true rig", () => {
    expect(() => buildScene(config, "chunky")).toThrow(/chunky/);
  });

  it("throws on a variant named after an Object.prototype member instead of rendering the true rig", () => {
    // `character.variants` is a JSON-derived Record, so a plain index sees
    // Object.prototype too — "constructor" resolves to a function, which is
    // truthy, so a guard that only checks `=== undefined` never fires and this
    // silently renders the true rig, exactly what the test above forbids.
    expect(() => buildScene(config, "constructor")).toThrow(/constructor/);
  });
});

describe("crops", () => {
  it("keeps every item when the crop's features cover every feature in the rig", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    // `full` is ["brows","antennae","mouth","descender","eyes"], which between
    // them name every feature `rig.json` declares — so this asserts the filter
    // subtracts nothing when nothing should be subtracted, the failure mode a
    // count alone would miss.
    expect(cropList(config, list, "full")).toEqual(list);
    expect(list).toHaveLength(14);
  });

  it("inherits a feature from the nearest ancestor that declares one", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    const kept = cropList(config, list, "browsAndEyes");
    // `eyeLeft` and `eyeRight` carry "eyes"; the six discs and rings underneath
    // them carry nothing. The pinpricks hang off `body`, which declares no
    // feature, so they survive by naming "eyes" themselves rather than by the
    // structural fallback — which is why `rig.json` names it on them (Task 2).
    expect(kept.map((i) => i.id)).toEqual([
      "browLeft", "browRight",
      "eyeLeftBg", "eyeLeftRing", "irisLeft",
      "eyeRightBg", "eyeRightRing", "irisRight",
      "pinprickLeft", "pinprickRight",
    ]);
    // Same items, same order, same paint — a filter, not a recomposition.
    const dropped = new Set(["antennaLeft", "antennaRight", "mouth", "descender"]);
    expect(kept).toEqual(list.filter((i) => !dropped.has(i.id)));
  });

  it("drops an inherited feature the crop excludes — neither shipped crop can show this", () => {
    // Both `full` and `browsAndEyes` include "eyes", so real inheritance and the
    // no-feature-declared fallback produce the SAME output for every crop
    // `character.json` ships — a crop that discriminates has to exclude "eyes"
    // while a node still inherits it. Inventing that crop in the shipped config
    // would put fiction nothing in the product wants into real data, so it is
    // built here instead: a clone of the imported config with one extra crop,
    // loaded through the real loader like any other config would be.
    const patched = structuredClone(character) as typeof character;
    (patched.crops as Record<string, string[]>).browsOnly = ["brows"];
    const localConfig = loadConfig({ character: patched, rig, poses, timelines, behavior, sayings });
    const { channels } = fresh();
    const list = compose(buildScene(localConfig), channels);
    const kept = cropList(localConfig, list, "browsOnly");
    // Under inheritance, eyeLeft/eyeRight's six undeclared children inherit
    // "eyes" and are dropped along with the pinpricks, which declare "eyes"
    // directly. The no-feature fallback would have kept the six children
    // regardless, since they declare nothing of their own.
    expect(kept.map((i) => i.id)).toEqual(["browLeft", "browRight"]);
  });

  it("throws on an unknown crop name rather than returning an empty list", () => {
    const { scene, channels } = fresh();
    expect(() => cropList(config, compose(scene, channels), "nope")).toThrow(/nope/);
  });

  it("throws on a crop named after an Object.prototype member instead of returning it", () => {
    // `character.crops` is a JSON-derived Record, so a plain index sees
    // Object.prototype too — "constructor" resolves to a function, which is
    // truthy, so a guard that only checks `=== undefined` never fires and this
    // silently returns garbage instead of throwing.
    const { scene, channels } = fresh();
    expect(() => cropList(config, compose(scene, channels), "constructor")).toThrow(/constructor/);
  });
});

// One `it` per row of `conformance-test-vectors.md`; the title starts with the vector number.
// The web fixture is the 14-node olylo rig, so the Apple fixture's node names map onto it as
// eye -> eyeLeftRing, pupil -> irisLeft, line -> mouth, limb -> antennaLeft, spark -> pinprickLeft.
describe("conformance vectors", () => {
  const by = (list: readonly DisplayItem[], id: string) => list.find((i) => i.id === id)!;
  const ALL_IDS = [
    "browLeft", "browRight", "antennaLeft", "antennaRight", "mouth", "descender",
    "eyeLeftBg", "eyeLeftRing", "irisLeft", "eyeRightBg", "eyeRightRing", "irisRight",
    "pinprickLeft", "pinprickRight",
  ];
  /** A scene whose flat list is exactly the given nodes (bypasses the type system on purpose). */
  const sceneOf = (nodes: unknown[], over: Record<string, unknown> = {}) => {
    const base = buildScene(config);
    return {
      ...base,
      ...over,
      flat: nodes.map((node) => ({ node, parents: [] })),
    } as unknown as ReturnType<typeof buildScene>;
  };
  const antenna = () => {
    const { scene } = fresh();
    return structuredClone(scene.flat.find((f) => f.node.id === "antennaLeft")!.node);
  };

  it("vector 1: every shape node is emitted once in declaration order; shapeless body is absent", () => {
    const { scene, channels } = fresh();
    const ids = compose(scene, channels).map((i) => i.id);
    expect(ids).toEqual(ALL_IDS);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).not.toContain("body");
    expect(scene.flat.some((f) => f.node.id === "body")).toBe(true);
  });

  it("vector 2: at rest nothing is driven, so geometry is the authored geometry in local space", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    const ring0 = by(list, "eyeLeftRing");
    expect(ring0.m).toEqual([1, 0, 0, 1, 0, 0]);
    expect(ring0.d).toBe(ring(152, 200, 35, 8));
    expect(ring0.kind).toBe("MCCCCZMCCCCZ");
    expect(by(list, "eyeLeftBg").d).toBe(disc(152, 200, 27));
    expect(by(list, "mouth").kind).toBe("MLL");
    expect(by(list, "mouth").d).toBe("M187,233L200,246L213,233");
    expect(by(list, "irisLeft").kind).toBe(parsePath(by(list, "irisLeft").d).kind);
  });

  it("vector 3: a rotated parent composes into a child with no transform of its own", () => {
    const { scene, channels } = fresh();
    channels.set("body.rotation", 90);
    const m = by(compose(scene, channels), "irisLeft").m;
    const [px, py] = [config.rest.get("body.pivotX") as number, config.rest.get("body.pivotY") as number];
    // 90 degrees about (px, py): a=0 b=1 c=-1 d=0, e = px + py, f = py - px
    expect(m[0]).toBeCloseTo(0, 12);
    expect(m[1]).toBeCloseTo(1, 12);
    expect(m[2]).toBeCloseTo(-1, 12);
    expect(m[3]).toBeCloseTo(0, 12);
    expect(m[4]).toBeCloseTo(px + py, 9);
    expect(m[5]).toBeCloseTo(py - px, 9);
  });

  it("vector 4: multiply order is parent-then-local (e,f of irisLeft are 390, 0)", () => {
    const { scene, channels } = fresh();
    channels.set("body.rotation", 90);
    channels.set("face.y", 10);
    const m = by(compose(scene, channels), "irisLeft").m;
    expect(m[4]).toBeCloseTo(390, 9);
    expect(m[5]).toBeCloseTo(0, 9);
  });

  it("vector 5: scaleY drives only that node's matrix; a sibling stays at 1", () => {
    const { scene, channels } = fresh();
    channels.set("eyeLeftRing.scaleY", 0.1);
    const list = compose(scene, channels);
    expect(by(list, "eyeLeftRing").m[3]).toBeCloseTo(0.1, 12);
    expect(by(list, "eyeLeftRing").m[0]).toBe(1);
    expect(by(list, "eyeRightRing").m[3]).toBe(1);
    expect(by(list, "irisLeft").m[3]).toBe(1);
  });

  it("vector 6: composition uses the pivot channel, not the rig's static origin", () => {
    const { scene, channels } = fresh();
    const y0 = config.rest.get("body.pivotY") as number;
    channels.set("body.rotation", 4);
    const before = by(compose(scene, channels), "mouth").m;
    const delta = 10;
    channels.set("body.pivotY", y0 + delta);
    const after = by(compose(scene, channels), "mouth").m;
    const shift = Math.hypot(after[4] - before[4], after[5] - before[5]);
    expect(shift).toBeCloseTo(delta * 2 * Math.sin((2 * Math.PI) / 180), 9);
    expect(shift).toBeGreaterThan(0);
  });

  it("vector 7: a driven shape channel is taken verbatim and its kind is parsed from it", () => {
    const { scene, channels } = fresh();
    channels.set("mouth.shape", "M1,2L3,4L5,6");
    const item = by(compose(scene, channels), "mouth");
    expect(item.d).toBe("M1,2L3,4L5,6");
    expect(item.kind).toBe("MLL");
  });

  it("vector 8: bend offsets control points by weight x raw channel value, undamped, both directions", () => {
    const { scene, channels } = fresh();
    const restD = by(compose(scene, channels), "antennaLeft").d;
    const restPts = parsePath(restD).points;
    const weights = [0, 0.3, 0.8, 1];
    const src = [[183, 169], [180, 148], [175, 126], [179, 105]];
    for (const a of [10, 6, -10]) {
      channels.set("antennaLeft.bend", a);
      const out = by(compose(scene, channels), "antennaLeft");
      expect(out.d).not.toBe(restD);
      const pts = parsePath(out.d).points;
      expect(pts[0]).toBeCloseTo(src[0]![0]! + weights[0]! * a, 12);
      expect(pts[2]).toBeCloseTo(src[1]![0]! + weights[1]! * a, 12);
      expect(pts[6]).toBeCloseTo(src[3]![0]! + weights[3]! * a, 12);
      // y never moves on an x-axis bend
      expect(pts[7]).toBeCloseTo(restPts[7]!, 12);
    }
  });

  it("vector 9: @body inks track body.ink (rest, palette key, literal); self-coloured inks do not", () => {
    const { scene, channels } = fresh();
    const palette = config.character.palette;
    const restInk = channels.get("body.ink") as string;
    const expectedRest = restInk.startsWith("#") ? restInk : palette[restInk];
    const selfColoured = by(compose(scene, channels), "irisLeft").paint.ink;
    const check = (expected: string) => {
      const list = compose(scene, channels);
      for (const id of ["mouth", "browLeft", "eyeLeftRing"]) expect(by(list, id).paint.ink).toBe(expected);
      expect(by(list, "irisLeft").paint.ink).toBe(selfColoured);
    };
    check(expectedRest!);
    channels.set("body.ink", "orange");
    check("#ff9500");
    channels.set("body.ink", "red");
    check("#ff2d2d");
    channels.set("body.ink", "#ff2d2d");
    check("#ff2d2d");
  });

  it("vector 10: stroke vs fill and width come from the ink", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    for (const id of ["mouth", "browLeft"]) {
      expect(by(list, id).paint.fill).toBe(false);
      expect(typeof by(list, id).paint.width).toBe("number");
    }
    for (const id of ["irisLeft", "eyeLeftBg"]) {
      expect(by(list, id).paint.fill).toBe(true);
      expect(by(list, id).paint.width).toBeUndefined();
    }
  });

  it("vector 11: a fully transparent node stays in the list with alpha 0", () => {
    const { scene, channels } = fresh();
    const atRest = compose(scene, channels);
    const n = atRest.length;
    // a pinprick rests at the authored alpha of 0 and is still listed
    expect(by(atRest, "pinprickRight").paint.alpha).toBe(0);
    channels.set("mouth.alpha", 0);
    channels.set("pinprickLeft.alpha", 0);
    const list = compose(scene, channels);
    expect(list).toHaveLength(n);
    expect(by(list, "mouth").paint.alpha).toBe(0);
    expect(by(list, "pinprickLeft").paint.alpha).toBe(0);
    expect(by(list, "browLeft").paint.alpha).toBe(by(atRest, "browLeft").paint.alpha);
  });

  it("vector 12: a variant patches shapes and inks and nothing else", () => {
    const { channels } = fresh();
    const plain = compose(buildScene(config), channels);
    const optical = compose(buildScene(config, "optical"), channels);
    expect(optical.map((i) => i.id)).toEqual(plain.map((i) => i.id));
    expect(optical.map((i) => i.m)).toEqual(plain.map((i) => i.m));
    expect(by(optical, "mouth").paint.width).not.toBe(by(plain, "mouth").paint.width);
    expect(by(optical, "eyeLeftRing").d).not.toBe(by(plain, "eyeLeftRing").d);
    expect(by(optical, "pinprickLeft")).toEqual(by(plain, "pinprickLeft"));
  });

  it("vector 13: an unknown variant raises and names it", () => {
    expect(() => buildScene(config, "chunky")).toThrow(/chunky/);
  });

  it("vector 14: a variant named after an Object.prototype member raises", () => {
    expect(() => buildScene(config, "constructor")).toThrow(/constructor/);
  });

  it("vector 15: a self-referential ink raises naming @body instead of looping", () => {
    const { scene, channels } = fresh();
    channels.set("body.ink", "@body");
    expect(() => compose(scene, channels)).toThrow(/@body/);
  });

  it("vector 16: a crop whose features cover every feature is the identity", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    expect(cropList(config, list, "full")).toEqual(list);
  });

  it("vector 17: an unfeatured node inherits its ancestor's feature and is kept by a crop naming it", () => {
    const { scene, channels } = fresh();
    const list = compose(scene, channels);
    const kept = cropList(config, list, "browsAndEyes").map((i) => i.id);
    // irisLeft declares no feature of its own; its parent eyeLeft declares "eyes"
    expect(kept).toContain("irisLeft");
    expect(kept).not.toContain("mouth");
    expect(kept).toEqual(
      list.filter((i) => !["antennaLeft", "antennaRight", "mouth", "descender"].includes(i.id)).map((i) => i.id),
    );
  });

  it("vector 18: an inherited feature the crop excludes drops the node", () => {
    const patched = structuredClone(character) as typeof character;
    (patched.crops as Record<string, string[]>).limbOnly = ["antennae"];
    const localConfig = loadConfig({ character: patched, rig, poses, timelines, behavior, sayings });
    const { channels } = fresh();
    const kept = cropList(localConfig, compose(buildScene(localConfig), channels), "limbOnly");
    expect(kept.map((i) => i.id)).toEqual(["antennaLeft", "antennaRight"]);
  });

  it("vector 19: an unknown crop raises and names it", () => {
    const { scene, channels } = fresh();
    expect(() => cropList(config, compose(scene, channels), "nope")).toThrow(/nope/);
  });

  it("vector 20: a crop named after an Object.prototype member raises", () => {
    const { scene, channels } = fresh();
    expect(() => cropList(config, compose(scene, channels), "constructor")).toThrow(/constructor/);
  });

  it("vector 21: a non-numeric transform channel falls back to its default", () => {
    const { scene, channels } = fresh();
    const rest = by(compose(scene, channels), "mouth").m;
    channels.set("mouth.x", "oops");
    const m = by(compose(scene, channels), "mouth").m;
    expect(m).toEqual(rest);
    expect(m.every((v) => typeof v === "number" && Number.isFinite(v))).toBe(true);
  });

  it("vector 22: an unknown shape kind throws `unknown shape kind`", () => {
    const { channels } = fresh();
    const scene = sceneOf([{ id: "weird", ink: "body", shape: { kind: "squiggle" } }]);
    expect(() => compose(scene, channels)).toThrow(/unknown shape kind: squiggle/);
  });

  it("vector 23: an ink named after the palette colour it points at resolves via the palette", () => {
    const { channels } = fresh();
    const cfg = {
      ...config,
      character: {
        ...config.character,
        palette: { ...config.character.palette, shell: "#123456" },
      },
    } as typeof config;
    const scene = sceneOf(
      [{ id: "n", ink: "shell", shape: { kind: "disc", cx: 0, cy: 0, r: 5 } }],
      { config: cfg, inks: { shell: { kind: "fill", color: "shell" } } },
    );
    const [item] = compose(scene, channels);
    expect(item!.paint.ink).toBe("#123456");
    expect(item!.paint.fill).toBe(true);
  });

  it("vector 24: a late-bound ink with no channel value raises naming the reference and channel", () => {
    const { scene, channels } = fresh();
    channels.set("mouth.ink", "@missingNode");
    expect(() => compose(scene, channels)).toThrow(/@missingNode.*missingNode\.ink/);
  });

  it("vector 25: an ink name that is no colour, ink or palette key raises naming it", () => {
    const { scene, channels } = fresh();
    channels.set("mouth.ink", "nonexistent");
    expect(() => compose(scene, channels)).toThrow(/nonexistent/);
  });

  it("vector 26: cropping ignores alpha", () => {
    const { scene, channels } = fresh();
    for (const crop of ["full", "browsAndEyes"]) {
      const opaque = cropList(config, compose(scene, channels), crop).map((i) => i.id);
      channels.set("mouth.alpha", 0);
      channels.set("irisLeft.alpha", 0);
      const clear = cropList(config, compose(scene, channels), crop).map((i) => i.id);
      expect(clear).toEqual(opaque);
      channels.set("mouth.alpha", 1);
      channels.set("irisLeft.alpha", 1);
    }
  });

  it("vector 27: seedChannels writes every config.rest entry and compose at rest reproduces the authored geometry", () => {
    const { scene, channels } = fresh();
    for (const [key, value] of config.rest) expect(channels.get(key)).toBe(value);
    const list = compose(scene, channels);
    expect(by(list, "eyeLeftRing").d).toBe(ring(152, 200, 35, 8));
    expect(by(list, "mouth").d).toBe("M187,233L200,246L213,233");
  });

  it("vector 28: a late-bound chain resolving at depth 8 succeeds", () => {
    const { scene, channels } = fresh();
    for (let i = 0; i < 7; i++) channels.set(`n${i}.ink`, `@n${i + 1}`);
    channels.set("n7.ink", "#ff0000");
    channels.set("mouth.ink", "@n0");
    expect(by(compose(scene, channels), "mouth").paint.ink).toBe("#ff0000");
  });

  it("vector 29: the same chain one step longer (depth 9) raises", () => {
    const { scene, channels } = fresh();
    for (let i = 0; i < 7; i++) channels.set(`n${i}.ink`, `@n${i + 1}`);
    channels.set("n7.ink", "@n8");
    channels.set("n8.ink", "#ff0000");
    channels.set("mouth.ink", "@n0");
    expect(() => compose(scene, channels)).toThrow(/does not resolve to a colour/);
  });

  it("vector 30: cropping an empty list returns an empty list", () => {
    expect(cropList(config, [], "full")).toEqual([]);
    expect(cropList(config, [], "browsAndEyes")).toEqual([]);
  });

  it("vector 31: a node with no children is recorded once and not recursed into", () => {
    const { scene } = fresh();
    expect(scene.flat.filter((f) => f.node.id === "browLeft")).toHaveLength(1);
    const solo = {
      ...config,
      rig: { ...config.rig, root: { id: "solo", ink: "body", shape: { kind: "disc", cx: 1, cy: 2, r: 3 } } },
    } as unknown as typeof config;
    const s = buildScene(solo);
    expect(s.flat).toHaveLength(1);
    expect(s.flat[0]!.parents).toEqual([]);
  });

  it("vector 32: a bend.weights array shorter than the points leaves the extra points unmoved", () => {
    const { channels } = fresh();
    const node = antenna();
    (node.shape as { bend: { weights: number[] } }).bend.weights = [0.5, 1];
    channels.set("antennaLeft.bend", 10);
    const out = compose(sceneOf([node]), channels)[0]!;
    const pts = parsePath(out.d).points;
    expect(pts[0]).toBeCloseTo(183 + 5, 12);
    expect(pts[2]).toBeCloseTo(180 + 10, 12);
    expect(pts[4]).toBeCloseTo(175, 12);
    expect(pts[6]).toBeCloseTo(179, 12);
  });

  it("vector 33: only axis \"x\" offsets x; \"y\" and any other axis string offset y", () => {
    const { channels } = fresh();
    channels.set("antennaLeft.bend", 10);
    const pointsFor = (axis: string) => {
      const node = antenna();
      (node.shape as { bend: { axis: string; weights: number[] } }).bend.axis = axis;
      (node.shape as { bend: { weights: number[] } }).bend.weights = [0, 1, 1, 1];
      return parsePath(compose(sceneOf([node]), channels)[0]!.d).points;
    };
    const x = pointsFor("x");
    expect(x[2]).toBeCloseTo(190, 12);
    expect(x[3]).toBeCloseTo(148, 12);
    for (const p of [pointsFor("y"), pointsFor("z")]) {
      expect(p[2]).toBeCloseTo(180, 12);
      expect(p[3]).toBeCloseTo(158, 12);
    }
  });
});
