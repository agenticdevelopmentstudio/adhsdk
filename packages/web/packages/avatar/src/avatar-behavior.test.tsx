// @vitest-environment jsdom
// Avatar engine — conformance vectors avatar-behavior-001..063.
//
// GSAP is replaced by a recording fake: these tests assert WHAT the engine asks GSAP to
// do (targets, vars, loops, kills), which is the engine's whole contract; the motion
// itself is GSAP's. Timers are fake, so blink/ladder/speech timing is exact.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { act, createElement } from "react";
import { createRoot, type Root } from "react-dom/client";
import * as Avatar from "./index";
import { useAvatarEngine, type AvatarEngineConfig } from "./engine";
import { useArbitration, type ArbitrationConfig } from "./arbitration";
import { useBlink, useIdleLadder, useSpeech } from "./reflexes";
import { useGaze, type GazeOptions } from "./gaze";
import { useIdleFidget } from "./idleLife";
import { useSpeechBubble } from "./speechBubble";
import { applyPose } from "./pose";
import { DEFAULT_TUNING, type AvatarRig, type Pose, type Tuning } from "./types";

// ── minimal renderHook (this package carries no @testing-library dependency) ─
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
const mounted: Root[] = [];

function renderHook<P, R>(
  hook: (props: P) => R,
  options?: { initialProps?: P },
): { result: { current: R }; rerender: (props?: P) => void; unmount: () => void } {
  const result = { current: undefined as R };
  let props = options?.initialProps as P;
  const Probe = ({ p }: { p: P }): null => {
    result.current = hook(p);
    return null;
  };
  const root = createRoot(document.createElement("div"));
  mounted.push(root);
  act(() => {
    root.render(createElement(Probe, { p: props }));
  });
  return {
    result,
    rerender: (next?: P) => {
      if (next !== undefined) props = next;
      act(() => {
        root.render(createElement(Probe, { p: props }));
      });
    },
    unmount: () => {
      act(() => {
        root.unmount();
      });
    },
  };
}

// ── recording GSAP fake ─────────────────────────────────────────────────────
interface FakeTween {
  kind: "to" | "fromTo";
  target: unknown;
  vars: Record<string, unknown>;
  killed: boolean;
  kill: () => void;
}
interface FakeTimeline {
  steps: { kind: string; target: unknown; a: Record<string, unknown>; b?: Record<string, unknown> }[];
  killed: boolean;
  fromTo: (t: unknown, a: Record<string, unknown>, b: Record<string, unknown>) => FakeTimeline;
  to: (t: unknown, a: Record<string, unknown>) => FakeTimeline;
  kill: () => void;
}
interface QuickEntry {
  target: unknown;
  prop: string;
  fn: ReturnType<typeof vi.fn>;
}

const g = vi.hoisted(() => {
  const state = {
    tweens: [] as FakeTween[],
    sets: [] as { target: unknown; vars: Record<string, unknown> }[],
    quick: [] as QuickEntry[],
    timelines: [] as FakeTimeline[],
    killedTargets: [] as unknown[],
  };
  const gsap = {
    registerPlugin: vi.fn(),
    to: vi.fn((target: unknown, vars: Record<string, unknown>): FakeTween => {
      const t: FakeTween = {
        kind: "to",
        target,
        vars,
        killed: false,
        kill() {
          t.killed = true;
        },
      };
      state.tweens.push(t);
      return t;
    }),
    set: vi.fn((target: unknown, vars: Record<string, unknown>) => {
      state.sets.push({ target, vars });
    }),
    killTweensOf: vi.fn((target: unknown) => {
      state.killedTargets.push(target);
    }),
    quickTo: vi.fn((target: unknown, prop: string) => {
      const fn = vi.fn();
      state.quick.push({ target, prop, fn });
      return fn;
    }),
    timeline: vi.fn((): FakeTimeline => {
      const tl: FakeTimeline = {
        steps: [],
        killed: false,
        fromTo(target, a, b) {
          tl.steps.push({ kind: "fromTo", target, a, b });
          return tl;
        },
        to(target, a) {
          tl.steps.push({ kind: "to", target, a });
          return tl;
        },
        kill() {
          tl.killed = true;
        },
      };
      state.timelines.push(tl);
      return tl;
    }),
  };
  return { state, gsap };
});

vi.mock("gsap", () => ({ default: g.gsap }));
vi.mock("gsap/MorphSVGPlugin", () => ({ MorphSVGPlugin: { name: "MorphSVGPlugin" } }));

// ── fixtures ────────────────────────────────────────────────────────────────
type E = "calm" | "bored" | "sleepy" | "angry" | "surprised" | "yawn" | "laughing" | "hyper";

const pose = (extra: Partial<Pose> = {}): Pose => ({ dur: 0.3, ease: "power1.out", ...extra });
const POSES: Record<E, Pose> = {
  calm: pose({ sayings: ["hi", "hello"] }),
  bored: pose(),
  sleepy: pose({ sayings: ["zzz"] }),
  angry: pose({ sayings: ["grr"], scale: 1.2 }),
  surprised: pose(),
  yawn: pose({ scale: 3 }),
  laughing: pose(),
  hyper: pose({ wiggle: 5 }),
};

const el = <T,>(name: string): T => ({ name }) as unknown as T;
const ref = <T,>(name: string): { current: T } => ({ current: el<T>(name) });

interface TestRig {
  rig: AvatarRig;
  body: SVGGElement;
  idle: SVGGElement;
  tilt: SVGGElement;
  lean: SVGGElement;
  irisL: SVGCircleElement;
  irisR: SVGCircleElement;
  antL: SVGPathElement;
  antR: SVGPathElement;
  face: SVGGElement;
  blinkL: SVGGElement;
  blinkR: SVGGElement;
  mouth: SVGPathElement;
  desc: SVGPathElement;
  speechEl: SVGTextElement;
}

function makeRig(): TestRig {
  const svg = {
    current: {
      getBoundingClientRect: () => ({ left: 0, top: 0, width: 100, height: 100 }),
    } as unknown as SVGSVGElement,
  };
  const body = ref<SVGGElement>("body");
  const idle = ref<SVGGElement>("idle");
  const tilt = ref<SVGGElement>("tilt");
  const lean = ref<SVGGElement>("lean");
  const irisL = ref<SVGCircleElement>("irisL");
  const irisR = ref<SVGCircleElement>("irisR");
  const antL = ref<SVGPathElement>("antL");
  const antR = ref<SVGPathElement>("antR");
  const face = ref<SVGGElement>("face");
  const blinkL = ref<SVGGElement>("blinkL");
  const blinkR = ref<SVGGElement>("blinkR");
  const mouth = ref<SVGPathElement>("mouth");
  const desc = ref<SVGPathElement>("desc");
  const speech = ref<SVGTextElement>("speech");
  const rig: AvatarRig = {
    svg,
    pivot: "160 50",
    idleLayer: idle,
    tiltLayer: tilt,
    leanLayer: lean,
    body: { ref: body },
    eyes: { leftRef: ref<SVGGElement>("eyeL"), rightRef: ref<SVGGElement>("eyeR"), blinkLeftRef: blinkL, blinkRightRef: blinkR },
    iris: { leftRef: irisL, rightRef: irisR, baseR: 3 },
    antennae: { leftRef: antL, rightRef: antR, bend: (side, amp) => `${side}:${amp}` },
    mouth: { ref: mouth },
    descender: { ref: desc, logoPath: "LOGO", plainPath: "PLAIN", wiggleOrigin: "160 85" },
    face: { ref: face },
    speech,
  };
  return {
    rig,
    body: body.current,
    idle: idle.current,
    tilt: tilt.current,
    lean: lean.current,
    irisL: irisL.current,
    irisR: irisR.current,
    antL: antL.current,
    antR: antR.current,
    face: face.current,
    blinkL: blinkL.current,
    blinkR: blinkR.current,
    mouth: mouth.current,
    desc: desc.current,
    speechEl: speech.current,
  };
}

const tweensOn = (target: unknown, pred: (v: Record<string, unknown>) => boolean = () => true): FakeTween[] =>
  g.state.tweens.filter((t) => t.target === target && pred(t.vars));
const quickFor = (target: unknown, prop: string): ReturnType<typeof vi.fn> => {
  const entry = g.state.quick.find((q) => q.target === target && q.prop === prop);
  if (!entry) throw new Error(`no quickTo for ${String(prop)}`);
  return entry.fn;
};
const lastArg = (fn: ReturnType<typeof vi.fn>): number => {
  const calls = fn.mock.calls;
  return calls[calls.length - 1]![0] as number;
};
const setsOn = (target: unknown): Record<string, unknown>[] =>
  g.state.sets.filter((s) => s.target === target).map((s) => s.vars);

const advance = (ms: number): void => {
  act(() => {
    vi.advanceTimersByTime(ms);
  });
};

function baseConfig(r: TestRig, extra: Partial<AvatarEngineConfig<E>> = {}): AvatarEngineConfig<E> {
  return { poses: POSES, rig: r.rig, moods: { idle: "calm", bored: "bored", asleep: "sleepy" }, ...extra };
}

function engine(r: TestRig, initial: Partial<AvatarEngineConfig<E>> = {}) {
  return renderHook((p: Partial<AvatarEngineConfig<E>>) => useAvatarEngine<E>({ ...baseConfig(r), ...p }), {
    initialProps: initial,
  });
}

function arbitration(initial: ArbitrationConfig<E>) {
  return renderHook((c: ArbitrationConfig<E>) => useArbitration<E>(c), { initialProps: initial });
}

let randomSpy: ReturnType<typeof vi.spyOn> | undefined;
const randomIs = (v: number): void => {
  randomSpy?.mockRestore();
  randomSpy = vi.spyOn(Math, "random").mockReturnValue(v);
};

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(1_000_000);
  g.state.tweens.length = 0;
  g.state.sets.length = 0;
  g.state.quick.length = 0;
  g.state.timelines.length = 0;
  g.state.killedTargets.length = 0;
  for (const fn of [g.gsap.registerPlugin, g.gsap.to, g.gsap.set, g.gsap.killTweensOf, g.gsap.quickTo, g.gsap.timeline]) {
    fn.mockClear();
  }
  randomIs(0.5);
});

afterEach(() => {
  for (const root of mounted.splice(0)) {
    try {
      act(() => root.unmount());
    } catch {
      // already unmounted by the test
    }
  }
  randomSpy?.mockRestore();
  randomSpy = undefined;
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

// ── public API + tuning ─────────────────────────────────────────────────────
describe("public API and tuning", () => {
  it("avatar-behavior-001 exports every hook and applyPose as a function", () => {
    const surface = Avatar as Record<string, unknown>;
    for (const name of [
      "useAvatarEngine",
      "useBlink",
      "useIdleLadder",
      "useSpeech",
      "useArbitration",
      "useGaze",
      "useIdleFidget",
      "useSpeechBubble",
      "applyPose",
    ]) {
      expect(typeof surface[name], name).toBe("function");
    }
  });

  it("avatar-behavior-002 omitted tuning leaves the engine on DEFAULT_TUNING (all 15 fields)", () => {
    const keys = Object.keys(DEFAULT_TUNING) as (keyof Tuning)[];
    expect(keys).toHaveLength(15);
    for (const k of keys) expect(typeof DEFAULT_TUNING[k], k).toBe("number");
    expect(typeof DEFAULT_TUNING.swayCalm).toBe("number");
    expect(typeof DEFAULT_TUNING.swayLively).toBe("number");

    // Observed through the engine: forced gaze uses gazeMax/tiltMax/leanMax, antennae use the sway amps.
    const r = makeRig();
    const { rerender } = engine(r, { expression: "hyper", gaze: { x: 1, y: 1 } });
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(DEFAULT_TUNING.gazeMax);
    expect(lastArg(quickFor(r.tilt, "rotation"))).toBe(-DEFAULT_TUNING.tiltMax);
    expect(lastArg(quickFor(r.lean, "x"))).toBe(DEFAULT_TUNING.leanMax);
    expect(setsOn(r.antL).some((v) => (v.attr as { d: string }).d === `left:${-DEFAULT_TUNING.swayLively}`)).toBe(true);
    rerender({ expression: "angry", gaze: { x: 1, y: 1 } });
    expect(setsOn(r.antL).some((v) => (v.attr as { d: string }).d === `left:${-DEFAULT_TUNING.swayCalm}`)).toBe(true);
  });

  it("avatar-behavior-003 a partial tuning overrides only its own field", () => {
    const r = makeRig();
    const tuning = { boredAfterMs: 1000 };
    const { result } = engine(r, { tuning, gaze: { x: 1, y: 0 } });
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(DEFAULT_TUNING.gazeMax);
    expect(result.current.effective).toBe("calm");
    vi.spyOn(document, "hasFocus").mockReturnValue(true);
    advance(1600);
    expect(result.current.effective).toBe("bored");
    // asleepAfterMs is still the default 14000.
    advance(5000);
    expect(result.current.effective).toBe("bored");
  });
});

// ── arbitration ─────────────────────────────────────────────────────────────
describe("arbitration", () => {
  const moods = { idle: "calm", bored: "bored", asleep: "sleepy" } as const;

  it("avatar-behavior-004 unset expression + active ladder rests on the idle mood", () => {
    const { result } = arbitration({ ladder: "active", moods: { idle: "calm" } });
    expect(result.current.resting).toBe("calm");
  });

  it("avatar-behavior-005 a missing bored entry falls back to idle", () => {
    const { result } = arbitration({ ladder: "bored", moods: { idle: "calm" } });
    expect(result.current.resting).toBe("calm");
  });

  it("avatar-behavior-006 a deliberate expression overrides the ladder entirely", () => {
    const { result } = arbitration({
      expression: "angry",
      ladder: "asleep",
      moods: { idle: "calm", asleep: "sleepy" },
    });
    expect(result.current.resting).toBe("angry");
  });

  it("avatar-behavior-007 a click reaction outranks a pending waking one-shot and the resting mood", () => {
    const waking = { from: "sleepy", to: "calm", play: "yawn", ms: 800 } as const;
    const poke = () => ({ expression: "surprised" as const, ms: 5000 });
    const { result, rerender } = arbitration({ ladder: "asleep", moods, waking, poke });
    rerender({ ladder: "active", moods, waking, poke });
    expect(result.current.effective).toBe("yawn");
    act(() => result.current.poke());
    expect(result.current.effective).toBe("surprised");
    expect(result.current.resting).toBe("calm");
  });

  it("avatar-behavior-008 a waking one-shot outranks the resting mood", () => {
    const waking = { from: "sleepy", to: "calm", play: "yawn", ms: 800 } as const;
    const { result, rerender } = arbitration({ ladder: "asleep", moods, waking });
    rerender({ ladder: "active", moods, waking });
    expect(result.current.effective).toBe("yawn");
    expect(result.current.resting).toBe("calm");
  });

  it("avatar-behavior-009 with no transient the effective mood is the resting mood", () => {
    const { result } = arbitration({ ladder: "active", moods });
    expect(result.current.effective).toBe("calm");
  });

  it("avatar-behavior-010 a poke returning null produces no reaction", () => {
    const poke = vi.fn(() => null);
    const { result } = arbitration({ ladder: "active", moods, poke });
    act(() => result.current.poke());
    expect(poke).toHaveBeenCalledWith("calm");
    expect(result.current.effective).toBe("calm");
    expect(vi.getTimerCount()).toBe(0);
  });

  it("avatar-behavior-011 poke is a no-op when config.poke is undefined", () => {
    const { result } = arbitration({ ladder: "active", moods });
    expect(() => act(() => result.current.poke())).not.toThrow();
    expect(result.current.effective).toBe("calm");
  });

  it("avatar-behavior-012 a poke reaction shows immediately and clears after its ms", () => {
    const poke = () => ({ expression: "surprised" as const, ms: 500 });
    const { result } = arbitration({ ladder: "active", moods, poke });
    act(() => result.current.poke());
    expect(result.current.effective).toBe("surprised");
    advance(499);
    expect(result.current.effective).toBe("surprised");
    advance(1);
    expect(result.current.effective).toBe(result.current.resting);
    expect(result.current.effective).toBe("calm");
  });

  it("avatar-behavior-013 a second poke supersedes the first reaction's timer", () => {
    const poke = vi
      .fn<(r: E) => { expression: E; ms: number }>()
      .mockReturnValueOnce({ expression: "surprised", ms: 500 })
      .mockReturnValueOnce({ expression: "angry", ms: 500 });
    const { result } = arbitration({ ladder: "active", moods, poke });
    act(() => result.current.poke());
    advance(100);
    act(() => result.current.poke());
    advance(1);
    expect(result.current.effective).toBe("angry");
    // The first reaction's expiry (t=500) never runs: still the second one.
    advance(399);
    expect(result.current.effective).toBe("angry");
    // The second reaction expires at t=600.
    advance(100);
    expect(result.current.effective).toBe("calm");
  });

  it("avatar-behavior-014 unmounting with a pending reaction fires no later state update", () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const poke = () => ({ expression: "surprised" as const, ms: 500 });
    const { result, unmount } = arbitration({ ladder: "active", moods, poke });
    act(() => result.current.poke());
    expect(vi.getTimerCount()).toBe(1);
    unmount();
    expect(vi.getTimerCount()).toBe(0);
    advance(1000);
    expect(errorSpy).not.toHaveBeenCalled();
  });

  it("avatar-behavior-015 the waking one-shot plays for ms on a from→to transition, then falls back", () => {
    const waking = { from: "sleepy", to: "calm", play: "yawn", ms: 800 } as const;
    const { result, rerender } = arbitration({ ladder: "asleep", moods, waking });
    expect(result.current.resting).toBe("sleepy");
    rerender({ ladder: "active", moods, waking });
    expect(result.current.effective).toBe("yawn");
    advance(799);
    expect(result.current.effective).toBe("yawn");
    advance(1);
    expect(result.current.effective).toBe("calm");
  });

  it("avatar-behavior-016 a click reaction active at the transition suppresses the waking one-shot", () => {
    const waking = { from: "sleepy", to: "calm", play: "yawn", ms: 800 } as const;
    const poke = () => ({ expression: "surprised" as const, ms: 3000 });
    const { result, rerender } = arbitration({ ladder: "asleep", moods, waking, poke });
    act(() => result.current.poke());
    rerender({ ladder: "active", moods, waking, poke });
    expect(result.current.effective).toBe("surprised");
    advance(3000);
    // No waking one-shot was queued behind the reaction.
    expect(result.current.effective).toBe("calm");
  });

  it("avatar-behavior-017 the reverse transition does not start a waking one-shot", () => {
    const waking = { from: "sleepy", to: "calm", play: "yawn", ms: 800 } as const;
    const { result, rerender } = arbitration({ ladder: "active", moods, waking });
    rerender({ ladder: "asleep", moods, waking });
    expect(result.current.effective).toBe("sleepy");
    advance(1000);
    expect(result.current.effective).toBe("sleepy");
  });
});

// ── curious / eyesShut flags (observed through the engine) ──────────────────
describe("curious and eyesShut flags", () => {
  it("avatar-behavior-018 effective asleep mood: curious false, eyesShut true", () => {
    const r = makeRig();
    const mouseleave = vi.spyOn(document, "addEventListener");
    const { result } = engine(r, { expression: "sleepy" });
    expect(result.current.effective).toBe("sleepy");
    // curious false: no breathing loop on the idle layer.
    expect(tweensOn(r.idle, (v) => v.scale === 1.035)).toHaveLength(0);
    // eyesShut true: gaze holds still (no cursor tracking) and antennae rest.
    expect(mouseleave.mock.calls.some((c) => c[0] === "mouseleave")).toBe(false);
    expect(tweensOn(r.antL, (v) => v.morphSVG === "left:0")).toHaveLength(1);
  });

  it("avatar-behavior-019 effective idle mood: curious true, eyesShut false", () => {
    const r = makeRig();
    const docListen = vi.spyOn(document, "addEventListener");
    const { result } = engine(r, { expression: "calm" });
    expect(result.current.effective).toBe("calm");
    expect(tweensOn(r.idle, (v) => v.scale === 1.035)).toHaveLength(1);
    expect(docListen.mock.calls.some((c) => c[0] === "mouseleave")).toBe(true);
    expect(tweensOn(r.antL, (v) => v.morphSVG === "left:0")).toHaveLength(0);
    expect(tweensOn(r.antL, (v) => v.repeat === -1)).toHaveLength(1);
  });
});

// ── blink ───────────────────────────────────────────────────────────────────
describe("blink", () => {
  const tune = (extra: Partial<Tuning> = {}): Tuning => ({
    ...DEFAULT_TUNING,
    minBlinkMs: 100,
    maxBlinkMs: 200,
    blinkDurationMs: 50,
    ...extra,
  });

  it("avatar-behavior-020 each cycle is a min..max gap of false then a blinkDuration stretch of true", () => {
    randomIs(0);
    const tuning = tune();
    const { result } = renderHook(() => useBlink(true, tuning));
    expect(result.current).toBe(false);
    advance(99);
    expect(result.current).toBe(false);
    advance(1); // t=100: gap (min) elapsed
    expect(result.current).toBe(true);
    advance(49);
    expect(result.current).toBe(true);
    advance(1); // t=150: blink over
    expect(result.current).toBe(false);
    advance(99); // t=249
    expect(result.current).toBe(false);
    advance(1); // t=250: second blink inside a 300ms window
    expect(result.current).toBe(true);

    // The upper bound of the gap is maxBlinkMs.
    randomIs(0.999);
    const slow = renderHook(() => useBlink(true, tuning));
    advance(190);
    expect(slow.result.current).toBe(false);
    advance(10);
    expect(slow.result.current).toBe(true);
  });

  it("avatar-behavior-021 disabled blink reports false and schedules nothing", () => {
    const { result } = renderHook(() => useBlink(false, tune()));
    expect(result.current).toBe(false);
    expect(vi.getTimerCount()).toBe(0);
    advance(100_000);
    expect(result.current).toBe(false);
  });

  const blinkShut = (r: TestRig): FakeTween[] => tweensOn(r.blinkL, (v) => v.scaleY === 0.06);

  it("avatar-behavior-022 eyesShut disables blinking regardless of blinkSuppressed", () => {
    randomIs(0);
    // Positive control: an awake avatar blinks within the default gap.
    const awake = makeRig();
    engine(awake, { expression: "calm", blinkSuppressed: [] });
    advance(DEFAULT_TUNING.minBlinkMs);
    expect(blinkShut(awake).length).toBeGreaterThan(0);

    const r = makeRig();
    engine(r, { expression: "sleepy", blinkSuppressed: [] });
    advance(60_000);
    expect(blinkShut(r)).toHaveLength(0);
  });

  it("avatar-behavior-023 a blinkSuppressed effective mood disables blinking", () => {
    randomIs(0);
    const r = makeRig();
    engine(r, { expression: "laughing", blinkSuppressed: ["laughing"] });
    advance(60_000);
    expect(blinkShut(r)).toHaveLength(0);
  });

  it("avatar-behavior-056 blink groups collapse to scaleY 0.06 then 1 over 0.09s, independent of the pose", () => {
    randomIs(0);
    const r = makeRig();
    engine(r, { expression: "calm" });
    advance(DEFAULT_TUNING.minBlinkMs);
    const shut = blinkShut(r);
    expect(shut).toHaveLength(1);
    expect(shut[0]!.vars.duration).toBe(0.09);
    advance(DEFAULT_TUNING.blinkDurationMs);
    const blinkTweens = tweensOn(r.blinkL);
    expect(blinkTweens[blinkTweens.length - 1]!.vars.scaleY).toBe(1);
    expect(blinkTweens[blinkTweens.length - 1]!.vars.duration).toBe(0.09);
    // The pose never touches the blink group.
    expect(tweensOn(r.blinkL, (v) => "scale" in v)).toHaveLength(0);
  });
});

// ── idle ladder ─────────────────────────────────────────────────────────────
describe("idle ladder", () => {
  beforeEach(() => {
    vi.spyOn(document, "hasFocus").mockReturnValue(true);
  });
  const ladder = (expressionActive = false) =>
    renderHook((p: { active: boolean }) => useIdleLadder(p.active, DEFAULT_TUNING), {
      initialProps: { active: expressionActive },
    });

  it("avatar-behavior-024 inactivity beyond asleepAfterMs reports asleep", () => {
    const { result } = ladder();
    advance(14000);
    expect(result.current).not.toBe("asleep");
    advance(400);
    expect(result.current).toBe("asleep");
  });

  it("avatar-behavior-025 inactivity beyond boredAfterMs but below asleepAfterMs reports bored", () => {
    const { result } = ladder();
    expect(result.current).toBe("active");
    advance(6000);
    expect(result.current).toBe("active");
    advance(400);
    expect(result.current).toBe("bored");
    advance(6000);
    expect(result.current).toBe("bored");
  });

  it("avatar-behavior-026 a focused pointermove flips the ladder to active immediately", () => {
    const { result } = ladder();
    advance(6400);
    expect(result.current).toBe("bored");
    act(() => {
      window.dispatchEvent(new Event("pointermove"));
    });
    expect(result.current).toBe("active");
  });

  it("avatar-behavior-027 a pointermove while the window is unfocused is ignored", () => {
    const { result } = ladder();
    advance(6400);
    vi.spyOn(document, "hasFocus").mockReturnValue(false);
    act(() => {
      window.dispatchEvent(new Event("pointermove"));
    });
    expect(result.current).toBe("bored");
  });

  it("avatar-behavior-028 typing holds the ladder active for alertAfterTypingMs, then counting resumes", () => {
    const { result } = ladder();
    act(() => {
      window.dispatchEvent(new Event("keydown"));
    });
    advance(20_000); // would be asleep by 14400 without the typing grace
    expect(result.current).toBe("active");
    advance(10_000); // t=30000
    expect(result.current).toBe("active");
    advance(5_200); // t=35200: still inside the post-grace boredAfter window
    expect(result.current).toBe("active");
    advance(1_200); // t=36400: now counting past boredAfterMs
    expect(result.current).toBe("bored");
  });

  it("avatar-behavior-029 pointerdown resets the idle clock but does not flip the ladder synchronously", () => {
    const { result } = ladder();
    advance(6400);
    expect(result.current).toBe("bored");
    act(() => {
      window.dispatchEvent(new Event("pointerdown"));
    });
    expect(result.current).toBe("bored");
    advance(400);
    expect(result.current).toBe("active");
  });

  it("avatar-behavior-030 expressionActive flipping to true resets the idle clock", () => {
    const { result, rerender } = ladder(false);
    advance(5000);
    rerender({ active: true });
    advance(2000); // t=7000: would be bored (>6000) without the reset
    expect(result.current).toBe("active");
    advance(4400); // t=11400: 6400ms after the reset
    expect(result.current).toBe("bored");
  });
});

// ── speech ──────────────────────────────────────────────────────────────────
describe("speech", () => {
  const sayings: Partial<Record<E, string[]>> = { calm: ["hi", "hello"], angry: ["grr"], sleepy: ["zzz", "snore"] };
  const speech = (initial: { e: E; looping?: boolean }) =>
    renderHook(
      (p: { e: E; looping?: boolean }) => useSpeech<E>(p.e, (e) => sayings[e], p.looping ?? false, 11000),
      { initialProps: initial },
    );

  it("avatar-behavior-031 a mood change emits one of its sayings with an incremented id", () => {
    randomIs(0.99);
    const { result, rerender } = speech({ e: "calm" });
    expect(result.current).toEqual({ text: "hello", id: 1 });
    randomIs(0);
    rerender({ e: "angry" });
    expect(result.current).toEqual({ text: "grr", id: 2 });
    rerender({ e: "calm" });
    expect(result.current).toEqual({ text: "hi", id: 3 });
  });

  it("avatar-behavior-032 a mood with no sayings entry sets speech to null", () => {
    const { result, rerender } = speech({ e: "calm" });
    expect(result.current).not.toBeNull();
    rerender({ e: "surprised" });
    expect(result.current).toBeNull();
  });

  it("avatar-behavior-033 looping emits a new line every mutterMs until the mood changes", () => {
    const { result, rerender } = speech({ e: "sleepy", looping: true });
    expect(result.current!.id).toBe(1);
    advance(10_999);
    expect(result.current!.id).toBe(1);
    advance(1);
    expect(result.current!.id).toBe(2);
    advance(11_000);
    expect(result.current!.id).toBe(3);
    rerender({ e: "angry", looping: false });
    const idAfterChange = result.current!.id;
    advance(60_000);
    expect(result.current!.id).toBe(idAfterChange);
  });

  it("avatar-behavior-034 mute nulls the returned speech and never calls onSpeak", () => {
    randomIs(0);
    const r = makeRig();
    const onSpeak = vi.fn();
    const { result } = engine(r, { expression: "calm", mute: true, onSpeak });
    expect(result.current.speech).toBeNull();
    advance(1000);
    expect(onSpeak).not.toHaveBeenCalled();
  });

  it("avatar-behavior-035 onSpeak is called once per speech id", () => {
    randomIs(0);
    const r = makeRig();
    const onSpeak = vi.fn();
    const { result, rerender } = engine(r, { expression: "calm", onSpeak });
    expect(result.current.speech).toEqual({ text: "hi", id: 1 });
    expect(onSpeak).toHaveBeenCalledTimes(1);
    expect(onSpeak).toHaveBeenLastCalledWith("hi");
    rerender({ expression: "calm", onSpeak });
    expect(onSpeak).toHaveBeenCalledTimes(1);
    rerender({ expression: "angry", onSpeak });
    expect(result.current.speech).toEqual({ text: "grr", id: 2 });
    expect(onSpeak).toHaveBeenCalledTimes(2);
    expect(onSpeak).toHaveBeenLastCalledWith("grr");
  });
});

// ── gaze ────────────────────────────────────────────────────────────────────
describe("gaze", () => {
  const gaze = (r: TestRig, opts: Partial<GazeOptions> = {}) =>
    renderHook(() =>
      useGaze(r.rig, {
        forcedX: null,
        forcedY: null,
        eyesShut: false,
        curious: true,
        tuning: DEFAULT_TUNING,
        watchingRef: { current: 0 },
        ...opts,
      }),
    );

  it("avatar-behavior-036 eyesShut holds iris, tilt and lean at zero and installs no listeners", () => {
    const r = makeRig();
    const winListen = vi.spyOn(window, "addEventListener");
    const docListen = vi.spyOn(document, "addEventListener");
    gaze(r, { eyesShut: true });
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(0);
    expect(lastArg(quickFor(r.irisL, "y"))).toBe(0);
    expect(lastArg(quickFor(r.irisR, "x"))).toBe(0);
    expect(lastArg(quickFor(r.tilt, "rotation"))).toBe(0);
    expect(lastArg(quickFor(r.lean, "x"))).toBe(0);
    expect(lastArg(quickFor(r.lean, "y"))).toBe(0);
    expect(winListen.mock.calls.some((c) => c[0] === "pointermove")).toBe(false);
    expect(docListen.mock.calls.some((c) => c[0] === "mouseleave")).toBe(false);
  });

  it("avatar-behavior-037 a forced gaze sets iris, tilt and lean to their maxima and ignores the cursor", () => {
    const r = makeRig();
    gaze(r, { forcedX: 1, forcedY: -1 });
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(7);
    expect(lastArg(quickFor(r.irisL, "y"))).toBe(-7);
    expect(lastArg(quickFor(r.tilt, "rotation"))).toBe(-9);
    expect(lastArg(quickFor(r.lean, "x"))).toBe(6);
    expect(lastArg(quickFor(r.lean, "y"))).toBe(-6);
    act(() => {
      window.dispatchEvent(new MouseEvent("pointermove", { clientX: -500, clientY: 900 }));
    });
    advance(100);
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(7);
    expect(lastArg(quickFor(r.irisL, "y"))).toBe(-7);
    expect(lastArg(quickFor(r.tilt, "rotation"))).toBe(-9);
  });

  it("avatar-behavior-038 the iris follows a cursor directly right of the rig centre", () => {
    const r = makeRig();
    const watching = { current: 0 };
    gaze(r, { watchingRef: watching });
    act(() => {
      window.dispatchEvent(new MouseEvent("pointermove", { clientX: 500, clientY: 50 }));
    });
    advance(40);
    expect(lastArg(quickFor(r.irisL, "x"))).toBeCloseTo(7);
    expect(lastArg(quickFor(r.irisL, "y"))).toBeCloseTo(0);
    expect(lastArg(quickFor(r.tilt, "rotation"))).toBeCloseTo(-9); // leans into the cursor
    expect(lastArg(quickFor(r.lean, "x"))).toBeCloseTo(6);
    expect(watching.current).toBeGreaterThanOrEqual(1_000_000); // stamped when the cursor drove the gaze
  });

  it("avatar-behavior-039 a mouseleave on document recentres the iris", () => {
    const r = makeRig();
    gaze(r);
    act(() => {
      window.dispatchEvent(new MouseEvent("pointermove", { clientX: 500, clientY: 50 }));
    });
    advance(40);
    expect(lastArg(quickFor(r.irisL, "x"))).toBeCloseTo(7);
    act(() => {
      document.dispatchEvent(new Event("mouseleave"));
    });
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(0);
    expect(lastArg(quickFor(r.irisL, "y"))).toBe(0);
  });

  it("avatar-behavior-040 after wanderAfterMs of stillness a curious avatar glances 0.45..0.90 of gazeMax or recentres", () => {
    // Branch 1: random < 0.25 recentres, after leaving tilt/lean level.
    randomIs(0.1);
    const r1 = makeRig();
    gaze(r1);
    expect(quickFor(r1.irisL, "x").mock.calls).toHaveLength(0);
    advance(DEFAULT_TUNING.wanderMinMs + 0.1 * (DEFAULT_TUNING.wanderMaxMs - DEFAULT_TUNING.wanderMinMs));
    expect(lastArg(quickFor(r1.irisL, "x"))).toBe(0);
    expect(lastArg(quickFor(r1.irisL, "y"))).toBe(0);
    expect(lastArg(quickFor(r1.tilt, "rotation"))).toBe(0);
    expect(lastArg(quickFor(r1.lean, "x"))).toBe(0);

    // Branch 2: otherwise a glance at 0.45..0.90 of gazeMax from centre, within wanderMaxMs.
    randomIs(0.9);
    const r2 = makeRig();
    gaze(r2);
    advance(DEFAULT_TUNING.wanderMaxMs);
    const x = lastArg(quickFor(r2.irisL, "x"));
    const y = lastArg(quickFor(r2.irisL, "y"));
    const dist = Math.hypot(x, y);
    expect(dist).toBeGreaterThanOrEqual(0.45 * DEFAULT_TUNING.gazeMax - 1e-9);
    expect(dist).toBeLessThanOrEqual(0.9 * DEFAULT_TUNING.gazeMax + 1e-9);
    expect(lastArg(quickFor(r2.tilt, "rotation"))).toBe(0);
  });

  it("avatar-behavior-063 config.gaze beyond [-1,1] is clamped before use", () => {
    const r = makeRig();
    engine(r, { expression: "angry", gaze: { x: 2, y: -2 } });
    expect(lastArg(quickFor(r.irisL, "x"))).toBe(7);
    expect(lastArg(quickFor(r.irisL, "y"))).toBe(-7);
    expect(lastArg(quickFor(r.tilt, "rotation"))).toBe(-9);
    expect(lastArg(quickFor(r.lean, "x"))).toBe(6);
    expect(lastArg(quickFor(r.lean, "y"))).toBe(-6);
  });
});

// ── idle fidget ─────────────────────────────────────────────────────────────
describe("idle fidget", () => {
  const fidget = (r: TestRig, curious: boolean, watching = 0) =>
    renderHook(
      (p: { curious: boolean }) =>
        useIdleFidget(r.rig, {
          curious: p.curious,
          idlePose: pose(),
          watchingRef: { current: watching },
          tuning: DEFAULT_TUNING,
        }),
      { initialProps: { curious } },
    );

  it("avatar-behavior-041 curious false starts no breathing or sway loop", () => {
    const r = makeRig();
    fidget(r, false);
    expect(g.state.tweens).toHaveLength(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it("avatar-behavior-042 curious true starts a 1→1.035 sine yoyo breath on the idle layer over 2.6s", () => {
    const r = makeRig();
    fidget(r, true);
    const breath = tweensOn(r.idle, (v) => v.scale === 1.035);
    expect(breath).toHaveLength(1);
    expect(breath[0]!.vars).toMatchObject({ duration: 2.6, repeat: -1, yoyo: true });
  });

  it("avatar-behavior-043 a stale watchingRef lets the sway retarget within ±3.5° every 0.5–0.9s", () => {
    randomIs(0.3);
    const r = makeRig();
    fidget(r, true, 0);
    const sway = (): FakeTween[] => tweensOn(r.idle, (v) => "rotation" in v && v.rotation !== 0 && v.scale === undefined);
    expect(sway()).toHaveLength(1);
    const first = sway()[0]!.vars;
    expect(Math.abs(first.rotation as number)).toBeLessThanOrEqual(3.5);
    expect(first.rotation as number).not.toBe(0);
    expect(first.duration as number).toBeGreaterThanOrEqual(0.5);
    expect(first.duration as number).toBeLessThanOrEqual(0.9);
    advance(700);
    expect(sway().length).toBeGreaterThanOrEqual(2);
  });

  it("avatar-behavior-044 a recent watchingRef holds the sway target at 0 while breathing continues", () => {
    randomIs(0.3);
    const r = makeRig();
    fidget(r, true, Date.now());
    const rotations = tweensOn(r.idle, (v) => "rotation" in v && v.scale === undefined);
    expect(rotations.length).toBeGreaterThan(0);
    for (const t of rotations) expect(t.vars.rotation).toBe(0);
    expect(tweensOn(r.idle, (v) => v.scale === 1.035)).toHaveLength(1);
  });

  it("avatar-behavior-045 curious flipping false clears the timer, kills the breath and settles the layer", () => {
    const r = makeRig();
    const { rerender } = fidget(r, true);
    const breath = tweensOn(r.idle, (v) => v.scale === 1.035)[0]!;
    expect(vi.getTimerCount()).toBe(1);
    rerender({ curious: false });
    expect(breath.killed).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
    const settle = tweensOn(r.idle, (v) => v.rotation === 0 && v.scale === 1);
    expect(settle).toHaveLength(1);
  });
});

// ── pose application ────────────────────────────────────────────────────────
describe("pose application", () => {
  it("avatar-behavior-046 a mood in poses runs applyPose after killing the previous loops", () => {
    const r = makeRig();
    const { rerender } = engine(r, { expression: "hyper" });
    const loops = g.state.tweens.filter((t) => t.vars.repeat === -1);
    expect(loops.length).toBeGreaterThan(0);
    rerender({ expression: "angry" });
    expect(loops.every((t) => t.killed)).toBe(true);
    // The new pose's body tween (scale 1.2) was applied for the new mood.
    expect(tweensOn(r.body, (v) => v.scale === 1.2)).toHaveLength(1);
  });

  it("avatar-behavior-047 a choreographed mood runs its timeline and skips applyPose", () => {
    const r = makeRig();
    const made: FakeTimeline[] = [];
    const choreo = vi.fn(() => {
      const tl = g.gsap.timeline();
      made.push(tl);
      return tl as never;
    });
    const { rerender } = engine(r, { expression: "calm", choreography: { yawn: choreo } });
    rerender({ expression: "yawn", choreography: { yawn: choreo } });
    expect(choreo).toHaveBeenCalledTimes(1);
    expect(choreo).toHaveBeenCalledWith(r.rig, POSES);
    // POSES.yawn.scale is 3; applyPose would have tweened the body to it.
    expect(tweensOn(r.body, (v) => v.scale === 3)).toHaveLength(0);
    // The timeline is tracked and killed on the next change.
    const tl = made[0]!;
    expect(tl.killed).toBe(false);
    rerender({ expression: "angry", choreography: { yawn: choreo } });
    expect(tl.killed).toBe(true);
  });

  it("avatar-behavior-048 a mood in neither poses nor choreography starts no tween or timeline", () => {
    const r = makeRig();
    const { rerender } = engine(r, { expression: "angry" });
    const tweensBefore = g.state.tweens.length;
    const timelinesBefore = g.state.timelines.length;
    const ghost = "ghost" as E;
    rerender({ expression: ghost });
    expect(g.state.tweens.length).toBe(tweensBefore);
    expect(g.state.timelines.length).toBe(timelinesBefore);
  });

  it("avatar-behavior-049 a rig wiring only svg and pivot runs applyPose with no tweens and no throw", () => {
    const bare: AvatarRig = { svg: ref<SVGSVGElement>("svg"), pivot: "160 50" };
    let loops: unknown[] = [];
    expect(() => {
      loops = applyPose(bare, pose({ scale: 2, wiggle: 5, bob: 3, mouth: "M0 0", showY: true }), false);
    }).not.toThrow();
    expect(loops).toEqual([]);
    expect(g.state.tweens).toHaveLength(0);
    expect(g.state.sets).toHaveLength(0);
  });

  it("avatar-behavior-050 body scale and rotation (plus spin turns) tween as one tween about the pivot", () => {
    const r = makeRig();
    applyPose(r.rig, pose({ scale: 1.2, rotation: 10, spinTurns: 1, dur: 0.4, ease: "power3.out" }), false);
    const body = tweensOn(r.body);
    expect(body).toHaveLength(1);
    expect(body[0]!.vars).toMatchObject({ scale: 1.2, rotation: 370, svgOrigin: "160 50", overwrite: "auto" });
    // With spinTurns the entry whirl takes a fixed 0.9s on power3.inOut.
    expect(body[0]!.vars).toMatchObject({ duration: 0.9, ease: "power3.inOut" });
  });

  it("avatar-behavior-051 a lively pose sways each antenna at swayLively, out of phase", () => {
    const r = makeRig();
    const loops = applyPose(r.rig, pose({ wiggle: 5 }), false, { calm: 8, lively: 18 });
    expect(setsOn(r.antL)).toContainEqual({ attr: { d: "left:-18" } });
    expect(setsOn(r.antR)).toContainEqual({ attr: { d: "right:18" } });
    const left = tweensOn(r.antL, (v) => v.repeat === -1)[0]!;
    const right = tweensOn(r.antR, (v) => v.repeat === -1)[0]!;
    expect(left.vars).toMatchObject({ morphSVG: "left:18", yoyo: true, duration: 0.3 });
    expect(right.vars).toMatchObject({ morphSVG: "right:-18", yoyo: true, duration: 0.36 });
    expect(loops).toContain(left);
    expect(loops).toContain(right);
    // A calm pose uses swayCalm instead.
    const calm = makeRig();
    applyPose(calm.rig, pose(), false, { calm: 8, lively: 18 });
    expect(setsOn(calm.antL)).toContainEqual({ attr: { d: "left:-8" } });
  });

  it("avatar-behavior-052 eyesShut settles the antennae to a neutral bend and runs no sway loop", () => {
    const r = makeRig();
    const loops = applyPose(r.rig, pose({ wiggle: 5 }), true);
    expect(tweensOn(r.antL, (v) => v.morphSVG === "left:0")).toHaveLength(1);
    expect(tweensOn(r.antR, (v) => v.morphSVG === "right:0")).toHaveLength(1);
    expect(tweensOn(r.antL, (v) => v.repeat === -1)).toHaveLength(0);
    expect(tweensOn(r.antR, (v) => v.repeat === -1)).toHaveLength(0);
    expect(loops.filter((l) => (l as unknown as FakeTween).target === r.antL)).toHaveLength(0);
  });

  it("avatar-behavior-053 showY morphs the descender to logoPath with no tail-flick loop", () => {
    const r = makeRig();
    applyPose(r.rig, pose({ showY: true, wiggle: 0 }), false);
    expect(tweensOn(r.desc, (v) => v.morphSVG === "LOGO")).toHaveLength(1);
    expect(tweensOn(r.desc, (v) => v.repeat === -1)).toHaveLength(0);
    expect(tweensOn(r.desc, (v) => v.rotation === 0)).toHaveLength(1);
  });

  it("avatar-behavior-054 not showY morphs to plainPath and a lively wiggle loops a ±9° tail-flick", () => {
    const r = makeRig();
    applyPose(r.rig, pose({ showY: false, wiggle: 5 }), false);
    expect(tweensOn(r.desc, (v) => v.morphSVG === "PLAIN")).toHaveLength(1);
    expect(setsOn(r.desc)).toContainEqual({ rotation: -9, svgOrigin: "160 85" });
    const flick = tweensOn(r.desc, (v) => v.repeat === -1);
    expect(flick).toHaveLength(1);
    expect(flick[0]!.vars).toMatchObject({ rotation: 9, yoyo: true });
  });

  it("avatar-behavior-055 bob 0 and wiggle 0 settle the face to y 0 / rotation 0 with no loop", () => {
    const r = makeRig();
    const loops = applyPose(r.rig, pose({ bob: 0, wiggle: 0 }), false);
    expect(tweensOn(r.face, (v) => v.y === 0)).toHaveLength(1);
    expect(tweensOn(r.face, (v) => v.rotation === 0)).toHaveLength(1);
    expect(tweensOn(r.face, (v) => v.repeat === -1)).toHaveLength(0);
    expect(loops.filter((l) => (l as unknown as FakeTween).target === r.face)).toHaveLength(0);
  });

  it("avatar-behavior-057 a per-expression effect's cleanup runs before the next mood's pose is applied", () => {
    const r = makeRig();
    const cleanup = vi.fn();
    const effect = vi.fn(() => cleanup);
    const { rerender } = engine(r, { expression: "sleepy", perExpressionEffects: { sleepy: effect } });
    expect(effect).toHaveBeenCalledWith(r.rig);
    expect(cleanup).not.toHaveBeenCalled();
    rerender({ expression: "angry", perExpressionEffects: { sleepy: effect } });
    expect(cleanup).toHaveBeenCalledTimes(1);
    const angryBody = tweensOn(r.body, (v) => v.scale === 1.2)[0]!;
    const toCalls = g.gsap.to.mock.calls;
    const bodyCallIndex = toCalls.findIndex((c) => c[0] === r.body && (c[1] as Record<string, unknown>).scale === 1.2);
    expect(angryBody).toBeDefined();
    expect(cleanup.mock.invocationCallOrder[0]!).toBeLessThan(g.gsap.to.mock.invocationCallOrder[bodyCallIndex]!);
  });

  it("avatar-behavior-058 unmounting kills a surviving looping antenna-sway tween", () => {
    const r = makeRig();
    const { unmount } = engine(r, { expression: "angry" });
    const sway = tweensOn(r.antL, (v) => v.repeat === -1);
    expect(sway).toHaveLength(1);
    expect(sway[0]!.killed).toBe(false);
    unmount();
    expect(sway[0]!.killed).toBe(true);
    for (const t of g.state.tweens.filter((x) => x.vars.repeat === -1 && x.target !== r.idle)) {
      expect(t.killed).toBe(true);
    }
  });

  it("avatar-behavior-059 importing the engine without a window does not register the MorphSVG plugin", async () => {
    vi.resetModules();
    g.gsap.registerPlugin.mockClear();
    vi.stubGlobal("window", undefined);
    let threw: unknown;
    try {
      await import("./engine");
    } catch (e) {
      threw = e;
    }
    expect(threw).toBeUndefined();
    expect(g.gsap.registerPlugin).not.toHaveBeenCalled();

    // Control: with a window the plugin is registered at import.
    vi.unstubAllGlobals();
    vi.resetModules();
    await import("./engine");
    expect(g.gsap.registerPlugin).toHaveBeenCalledTimes(1);
    expect(g.gsap.registerPlugin).toHaveBeenCalledWith({ name: "MorphSVGPlugin" });
  });
});

// ── speech bubble ───────────────────────────────────────────────────────────
describe("speech bubble", () => {
  it("avatar-behavior-060 pops (0.22s) then drifts (1.3s after a 0.5s hold) within ±55° of straight up", () => {
    randomIs(0.5); // angle exactly straight up, dist 65
    const speechRef = ref<SVGTextElement>("speech");
    renderHook(() => useSpeechBubble(speechRef, { text: "hi", id: 1 }));
    expect(g.gsap.killTweensOf).toHaveBeenCalledWith(speechRef.current);
    expect(g.state.timelines).toHaveLength(1);
    const [pop, drift] = g.state.timelines[0]!.steps;
    expect(pop!.kind).toBe("fromTo");
    expect(pop!.a).toMatchObject({ opacity: 0, scale: 0.7 });
    expect(pop!.b).toMatchObject({ opacity: 0.7, scale: 1, duration: 0.22 });
    expect(drift!.kind).toBe("to");
    expect(drift!.a).toMatchObject({ opacity: 0, duration: 1.3, delay: 0.5 });
    expect(drift!.a.x as number).toBeCloseTo(0, 5);
    expect(drift!.a.y as number).toBeCloseTo(-4 - 65, 5);

    // Extremes of the random angle stay within ±55° of vertical (upward).
    for (const v of [0, 1]) {
      randomIs(v);
      g.state.timelines.length = 0;
      const ref2 = ref<SVGTextElement>("speech2");
      renderHook(() => useSpeechBubble(ref2, { text: "hi", id: 1 }));
      const step = g.state.timelines[0]!.steps[1]!.a;
      const dist = 40 + v * 50;
      const dx = step.x as number;
      const dy = (step.y as number) + 4;
      expect(Math.hypot(dx, dy)).toBeCloseTo(dist, 5);
      expect(dy).toBeLessThan(0);
      expect(Math.abs(dx / dist)).toBeLessThanOrEqual(Math.sin((55 * Math.PI) / 180) + 1e-9);
    }
  });

  it("avatar-behavior-061 speech null (or no ref) starts no timeline", () => {
    const speechRef = ref<SVGTextElement>("speech");
    renderHook(() => useSpeechBubble(speechRef, null));
    renderHook(() => useSpeechBubble(undefined, { text: "hi", id: 1 }));
    expect(g.state.timelines).toHaveLength(0);
    expect(g.gsap.killTweensOf).not.toHaveBeenCalled();
  });
});

// ── morph point counts ──────────────────────────────────────────────────────
describe("morph targets", () => {
  it("avatar-behavior-062 mouth paths with different point counts are passed through unchecked", () => {
    const r = makeRig();
    const threePoints = "M0 0 L10 0 L10 10";
    const fivePoints = "M0 0 L10 0 L10 10 L0 10 L0 5";
    expect(() => {
      applyPose(r.rig, pose({ mouth: threePoints }), false);
      applyPose(r.rig, pose({ mouth: fivePoints }), false);
    }).not.toThrow();
    const morphs = tweensOn(r.mouth).map((t) => t.vars.morphSVG);
    expect(morphs).toEqual([threePoints, fivePoints]);
  });
});
