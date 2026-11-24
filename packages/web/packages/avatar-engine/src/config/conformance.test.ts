// Conformance vectors 1..20 of cookbook/avatar-animation-engine/config. Each
// title starts with the vector's number and requirement name. The older
// `load.test.ts` covers most of these rules by their message; this file ties
// each one to its vector and adds the ones that had no test.
import { describe, expect, it } from "vitest";
import character from "@character/character.json";
import rig from "@character/rig.json";
import poses from "@character/poses.json";
import timelines from "@character/timelines.json";
import behavior from "@character/behavior.json";
import sayings from "@character/sayings.json";
import { loadConfig } from "./load";

const files = { character, rig, poses, timelines, behavior, sayings };
const clone = (): typeof files => structuredClone(files);

type Node = {
  id: string;
  ink?: string;
  shape?: { kind: string; family?: string; points?: number[][] };
  children?: Node[];
};
type Step = {
  at: number; channel: string; duration: number;
  to?: string | number; family?: string; promote?: number; ease?: string;
};
type Tl = { duration: number; steps: Step[] };

const rigOf = (f: typeof files) => f.rig as unknown as { root: Node; groups: Record<string, string[]> };
const posesOf = (f: typeof files) =>
  f.poses as unknown as { poses: Record<string, { channels: Record<string, string | number> }> };
const tlOf = (f: typeof files, name = "yawn") =>
  (f.timelines as unknown as { timelines: Record<string, Tl> }).timelines[name]!;
const behaviorOf = (f: typeof files) => f.behavior as unknown as {
  ladder: { moods: Record<string, string> };
  idleFidget: { rearm: { gapMs: number[] } };
  moodEffects: Record<string, { branch?: unknown; twitch?: unknown[]; drift?: unknown[] }>;
};

function findNode(root: Node, pred: (n: Node) => boolean): Node {
  const stack = [root];
  while (stack.length > 0) {
    const n = stack.pop()!;
    if (pred(n)) return n;
    for (const c of n.children ?? []) stack.push(c);
  }
  throw new Error("no node matches");
}

describe("avatar-animation-engine config conformance vectors", () => {
  it("1 schema-version-required: names the file and both versions", () => {
    const bad = clone();
    (bad.rig as { schemaVersion: number }).schemaVersion = 2;
    expect(() => loadConfig(bad)).toThrow(/rig\.json has schemaVersion 2, expected 1/);
  });

  it("2 duplicate-node-id-rejected: two nodes share one id", () => {
    const bad = clone();
    const root = rigOf(bad).root;
    const id = root.id;
    root.children![0]!.id = id;
    expect(() => loadConfig(bad)).toThrow(new RegExp(`duplicate node id "${id}"`));
  });

  it("3 palette-hex-format: names the palette key and the value", () => {
    const bad = clone();
    (bad.character as { palette: Record<string, string> }).palette.ink1 = "notahex";
    expect(() => loadConfig(bad)).toThrow(/palette "ink1" is "notahex"/);
  });

  it("4 shaped-node-requires-ink: names the node", () => {
    const bad = clone();
    const node = findNode(rigOf(bad).root, (n) => n.shape !== undefined && n.ink !== undefined);
    const id = node.id;
    delete node.ink;
    expect(() => loadConfig(bad)).toThrow(new RegExp(`node "${id}" has a shape but no ink`));
  });

  it("5 bend-response-damping: damps only the inward side", () => {
    const c = loadConfig(clone());
    expect(c.respond("antennaLeft.bend", 10)).toBeCloseTo(7.2, 10);
    expect(c.respond("antennaLeft.bend", -10)).toBe(-10);
    expect(c.respond("antennaRight.bend", -10)).toBeCloseTo(-7.2, 10);
  });

  it("6 command-signature-agreement: names both conflicting sources", () => {
    const bad = clone();
    posesOf(bad).poses.bored!.channels["mouth.shape"] = "M188,241 L212,241";
    expect(() => loadConfig(bad)).toThrow(
      /pose "bored" drives mouth\.shape with path "ML", but the rig's rest shape drives it with "MLL"/,
    );
  });

  it("7 promotion-source-target-kind: accepts promote 4, rejects promote 3", () => {
    // The shipped yawn promotes the two-line mouth into the 4-cubic mouthO family.
    expect(() => loadConfig(clone())).not.toThrow();
    const bad = clone();
    const promote = tlOf(bad).steps.find((s) => s.promote !== undefined)!;
    expect(promote.promote).toBe(4);
    promote.promote = 3;
    expect(() => loadConfig(bad)).toThrow(
      /promotes mouth\.shape into family "mouthO" as 3 cubic\(s\), but that family's shape is "MCCCC"/,
    );
  });

  it("8 timeline-duration-floor: a step that outruns the declared duration rejects", () => {
    const bad = clone();
    const tl = tlOf(bad);
    expect(tl.duration).toBe(2.1);
    tl.steps.push({ at: 3, channel: "body.scale", to: 1, duration: 0, ease: "none" });
    expect(() => loadConfig(bad)).toThrow(/declares duration 2\.1 but its steps run to 3/);
  });

  it("9 pair-fields-exactly-two: a one-element rearm gap rejects", () => {
    const bad = clone();
    behaviorOf(bad).idleFidget.rearm.gapMs = [500];
    expect(() => loadConfig(bad)).toThrow(
      /behavior\.idleFidget\.rearm\.gapMs needs exactly two numbers, not 1/,
    );
  });

  it("10 mood-effect-branch-list-defined: an authored empty list is accepted, an absent one is not", () => {
    const effects = (f: typeof files) => behaviorOf(f).moodEffects;
    const id = Object.keys(effects(files)).sort().find((m) => effects(files)[m]!.branch !== undefined)!;
    const ok = clone();
    effects(ok)[id]!.drift = [];
    expect(() => loadConfig(ok)).not.toThrow();
    const bad = clone();
    delete effects(bad)[id]!.drift;
    expect(() => loadConfig(bad)).toThrow(/branches to "drift", which it does not define/);
  });

  it("11 ladder-three-rungs-required: names the missing rung", () => {
    const bad = clone();
    delete behaviorOf(bad).ladder.moods.asleep;
    expect(() => loadConfig(bad)).toThrow(/ladder is missing the "asleep" rung/);
  });

  it("12 ink-late-binding-target: an unresolved @node reference rejects", () => {
    const bad = clone();
    (bad.character as { inks: Record<string, { kind: string; color: string }> })
      .inks.body!.color = "@missingNode";
    expect(() => loadConfig(bad)).toThrow(/ink "body" uses unresolved ink "@missingNode"/);
  });

  it("13 variant-shape-patch-target-validated: patching a morphable node rejects", () => {
    const bad = clone();
    (bad.character as unknown as {
      variants: Record<string, { shapes: Record<string, Record<string, unknown>> }>;
    }).variants.optical!.shapes.mouth = { points: [[0, 0], [1, 1], [2, 2]] };
    expect(() => loadConfig(bad)).toThrow(/patches morphable node "mouth"/);
  });

  it("14 fallback-mood-has-sayings: the active rung's mood needs a sayings list", () => {
    const bad = clone();
    const active = behaviorOf(bad).ladder.moods.active!;
    delete (bad.sayings as unknown as { sayings: Record<string, string[]> }).sayings[active];
    expect(() => loadConfig(bad)).toThrow(new RegExp(`sayings has no list for "${active}"`));
  });

  it("15 load-does-not-mutate-caller-input: two loads of one object leave it unchanged", () => {
    const shared = clone();
    const before = JSON.stringify(shared);
    const first = loadConfig(shared);
    expect(JSON.stringify(shared)).toBe(before);
    const second = loadConfig(shared);
    expect(JSON.stringify(shared)).toBe(before);
    expect(second.rest.get("body.ink")).toBe(first.rest.get("body.ink"));
    // The loader normalises its own copy: the caller's palette name survives.
    expect(posesOf(shared).poses.excited!.channels["body.ink"]).toBe("orange");
    expect(first.poses.poses.excited!.channels["body.ink"]).toBe("#ff9500");
  });

  it("16 step-order-stable-on-ties: tied steps are applied in authored order", () => {
    // Authored order: the promote snaps mouth.shape into mouthO, then a tied
    // step writes an MCCCC path. Applied in that order it is accepted.
    const ok = loadConfig(clone());
    const steps = ok.timelines.timelines.yawn!.steps;
    const iPromote = steps.findIndex((s) => s.promote !== undefined);
    const iTo = steps.findIndex(
      (s) => s.channel === "mouth.shape" && s.at === 0 && s.promote === undefined,
    );
    expect(iPromote).toBeLessThan(iTo);

    // Swap the two tied steps: the path now lands before the family changes,
    // so it is checked against the open-polyline family and rejects.
    const bad = clone();
    const list = tlOf(bad).steps;
    const a = list.findIndex((s) => s.promote !== undefined);
    const b = list.findIndex((s) => s.channel === "mouth.shape" && s.at === 0 && s.promote === undefined);
    [list[a], list[b]] = [list[b]!, list[a]!];
    expect(() => loadConfig(bad)).toThrow(/morphs within family "mouth"/);
  });

  it("17 ink-precedence-inks-before-palette: a name in both resolves as the ink", () => {
    const f = clone();
    // `flash` is a palette key no node uses; adding an ink of the same name makes it both.
    (f.character as unknown as { inks: Record<string, unknown> }).inks.flash =
      { kind: "stroke", color: "flash", width: 3 };
    const node = findNode(rigOf(f).root, (n) => n.id === "mouth");
    node.ink = "flash";
    const c = loadConfig(f);
    // Resolved as the ink key, not as the palette's hex (which would also be rejected for a shaped node).
    expect(c.rest.get("mouth.ink")).toBe("flash");
  });

  it("18 group-member-must-be-concrete-channel: a group naming a group rejects", () => {
    const bad = clone();
    rigOf(bad).groups["eye.both"] = ["eye.scaleY"];
    expect(() => loadConfig(bad)).toThrow(/group "eye\.both" names unknown channel "eye\.scaleY"/);
  });

  it("19 shape-value-canonicalized: different whitespace stores the same string", () => {
    const f = clone();
    posesOf(f).poses.bored!.channels["mouth.shape"] = "M 188,241  L 200,235 L212,241";
    posesOf(f).poses.sad!.channels["mouth.shape"] = "M188,241L200,235L 212,241";
    const c = loadConfig(f);
    const a = c.poses.poses.bored!.channels["mouth.shape"];
    const b = c.poses.poses.sad!.channels["mouth.shape"];
    expect(a).toBe(b);
    expect(a).toBe("M188,241L200,235L212,241");
  });

  it.skip("20 raw-file-read-errors-unwrapped: Apple RawFiles.read(fromDirectory:) is Swift-only; the web loader has no directory reader", () => {});
});
