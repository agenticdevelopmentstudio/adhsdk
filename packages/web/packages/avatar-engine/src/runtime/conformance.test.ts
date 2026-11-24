import { describe, expect, it } from "vitest";
import { createChannels, snaps } from "./channels";
import { createScheduler } from "./scheduler";
import { createTweens } from "./tween";

// One test per conformance vector in cookbook/avatar-animation-engine/runtime/conformance-test-vectors.md.
const near = (a: number, b: number, eps = 1e-9): void =>
  expect(Math.abs(a - b)).toBeLessThan(eps);

const POLY = "M189,235L200,235L211,235";
const CLOSED = "M200,233.6C207.18,233.6 213,234.37 213,235C213,235.63 207.18,236.4 200,236.4C192.82,236.4 187,235.63 187,235C187,234.37 192.82,233.6 200,233.6Z";
const SMALL = "M200,225C204.97,225 209,229.97 209,236C209,242.03 204.97,247 200,247C195.03,247 191,242.03 191,236C191,229.97 195.03,225 200,225Z";

const damp = (_c: string, v: number | string): number | string =>
  typeof v === "number" && v > 0 ? v * 0.72 : v;

describe("avatar-engine runtime conformance vectors: channels and scheduler", () => {
  it("aer-001: names() is sorted, not in insertion order", () => {
    const ch = createChannels({ m: 1, z: 2, a: 3 });
    ch.set("c", 4);
    expect(ch.names()).toEqual(["a", "c", "m", "z"]);
  });

  it("aer-002: a repeating event fires once per interval", () => {
    const s = createScheduler();
    const fires: number[] = [];
    s.every(0.1, (t) => fires.push(t), { first: 0.1 });
    for (let t = 0; t <= 0.55; t += 1 / 60) s.tick(t);
    expect(fires).toHaveLength(5);
  });

  it("aer-003: one long frame catches up every missed interval", () => {
    const s = createScheduler();
    let n = 0;
    s.every(0.1, () => { n += 1; }, { first: 0.1 });
    s.tick(0);
    s.tick(0.55);
    expect(n).toBe(5);
  });

  it("aer-004: the fire count is frame-rate independent", () => {
    const count = (step: number): number => {
      const s = createScheduler();
      let n = 0;
      s.every(0.1, () => { n += 1; }, { first: 0.1 });
      for (let t = 0; t <= 2 + 1e-12; t += step) s.tick(t);
      s.tick(2);
      return n;
    };
    expect(count(1 / 60)).toBe(count(1 / 240));
  });

  it("aer-005: a one-shot runs once and cancelling it afterwards is harmless", () => {
    const s = createScheduler();
    let n = 0;
    const id = s.once(0.5, () => { n += 1; });
    s.tick(1);
    s.tick(2);
    expect(n).toBe(1);
    expect(() => s.cancel(id)).not.toThrow();
  });

  it("aer-006: a late one-shot receives its own deadline, not now", () => {
    const s = createScheduler();
    const got: number[] = [];
    s.once(0.5, (t) => got.push(t));
    s.tick(1);
    expect(got).toEqual([0.5]);
  });

  it("aer-007: a re-arming one-shot chain fires once per tick with its true deadline (no stale clamp on the web)", () => {
    const s = createScheduler();
    const got: number[] = [];
    const arm = (at: number): void => {
      s.once(at, (t) => { got.push(t); arm(t + 5); });
    };
    arm(5);
    s.tick(5);
    s.tick(3600);
    // The re-armed entry is not in the tick's snapshot, so one fire per tick,
    // and the deadline handed over is the true one (10), unclamped.
    expect(got).toEqual([5, 10]);
    s.tick(3600 + 1 / 60);
    expect(got).toEqual([5, 10, 15]);
  });

  it("aer-008: cancel stops a repeater", () => {
    const s = createScheduler();
    let n = 0;
    const id = s.every(0.1, () => { n += 1; }, { first: 0.1 });
    s.tick(0.25);
    s.cancel(id);
    s.tick(5);
    expect(n).toBe(2);
  });

  it("aer-023: the catch-up guard stops at 1001 fires and re-bases the next due time", () => {
    const s = createScheduler();
    let n = 0;
    s.every(1, () => { n += 1; }, { first: 1 });
    s.tick(100000);
    expect(n).toBe(1001);
    s.tick(100000.5);
    expect(n).toBe(1001);
    s.tick(100001);
    expect(n).toBe(1002);
  });

  it("aer-024: snaps() classifies channels by their exact pivotX/pivotY suffix", () => {
    expect(snaps("body.pivotX")).toBe(true);
    expect(snaps("body.pivotY")).toBe(true);
    expect(snaps("a.b.pivotX")).toBe(true);
    expect(snaps("pivotX")).toBe(false);
    expect(snaps("body.pivotXY")).toBe(false);
  });

  it("aer-025: a tick runs a snapshot in id order, skipping entries cancelled mid-tick", () => {
    const s = createScheduler();
    const ran: string[] = [];
    let bId = 0;
    s.once(1, () => {
      ran.push("A");
      s.cancel(bId);
      s.once(1, () => ran.push("C"));
    });
    bId = s.once(1, () => ran.push("B"));
    s.tick(1);
    expect(ran).toEqual(["A"]);
    s.tick(1);
    expect(ran).toEqual(["A", "C"]);
  });

  it("aer-026: a repeater that cancels itself on its second fire runs exactly twice", () => {
    const s = createScheduler();
    let n = 0;
    const id = s.every(1, () => {
      n += 1;
      if (n === 2) s.cancel(id);
    }, { first: 1 });
    s.tick(10);
    expect(n).toBe(2);
  });

  it("aer-027: every() without first waits one full interval", () => {
    const s = createScheduler();
    let n = 0;
    s.every(0.5, () => { n += 1; });
    s.tick(0.4);
    expect(n).toBe(0);
    s.tick(0.5);
    expect(n).toBe(1);
  });
});

describe("avatar-engine runtime conformance vectors: tweens", () => {
  it("aer-009: interpolates a number over absolute time", () => {
    const ch = createChannels({ "eye.scaleY": 1 });
    const tw = createTweens(ch);
    tw.add({ channel: "eye.scaleY", to: 0.1, duration: 0.4, ease: "none" }, 10);
    tw.tick(10);
    near(ch.get("eye.scaleY") as number, 1);
    tw.tick(10.2);
    near(ch.get("eye.scaleY") as number, 0.55);
    tw.tick(10.4);
    near(ch.get("eye.scaleY") as number, 0.1);
    expect(tw.active()).toBe(0);
  });

  it("aer-010: a pivot snaps to its target at add time whatever duration is given", () => {
    const ch = createChannels({ "body.pivotY": 50 });
    const tw = createTweens(ch);
    tw.add({ channel: "body.pivotY", to: 74, duration: 0.9 }, 0);
    expect(ch.get("body.pivotY")).toBe(74);
    expect(tw.active()).toBe(0);
  });

  it("aer-011: a pivot still waits out its delay and then jumps", () => {
    const ch = createChannels({ "body.pivotX": 50 });
    const tw = createTweens(ch);
    tw.add({ channel: "body.pivotX", to: 80, duration: 0.9, delay: 0.2 }, 0);
    tw.tick(0.1);
    expect(ch.get("body.pivotX")).toBe(50);
    tw.tick(0.2);
    expect(ch.get("body.pivotX")).toBe(80);
  });

  it("aer-012: an explicit from replaces the channel's current value", () => {
    const ch = createChannels({ x: 5 });
    const tw = createTweens(ch);
    tw.add({ channel: "x", from: 0, to: 10, duration: 1, ease: "none" }, 0);
    tw.tick(0.5);
    near(ch.get("x") as number, 5);
    tw.tick(1);
    near(ch.get("x") as number, 10);
  });

  it("aer-013: a newer tween cancels the older one on the same channel", () => {
    const ch = createChannels({ x: 0 });
    const tw = createTweens(ch);
    tw.add({ channel: "x", to: 100, duration: 1, ease: "none" }, 0);
    tw.tick(0.5);
    tw.add({ channel: "x", to: 0, duration: 1, ease: "none" }, 0.5);
    expect(tw.active()).toBe(1);
    tw.tick(1);
    near(ch.get("x") as number, 25);
  });

  it("aer-014: colours and same-kind paths land exactly on their targets", () => {
    const ch = createChannels({ "body.ink": "#00ff41", "mouth.shape": "M187,233L200,246L213,233" });
    const tw = createTweens(ch);
    tw.add({ channel: "body.ink", to: "#ff2d2d", duration: 1, ease: "none" }, 0);
    tw.add({ channel: "mouth.shape", to: "M189,235L200,235L211,235", duration: 1, ease: "none" }, 0);
    tw.tick(1);
    expect(ch.get("body.ink")).toBe("#ff2d2d");
    expect(ch.get("mouth.shape")).toBe("M189,235L200,235L211,235");
  });

  it("aer-015: respond maps an endpoint once and the tween lerps in the mapped space", () => {
    const ch = createChannels({ "antennaLeft.bend": 0 });
    const tw = createTweens(ch, damp);
    tw.add({ channel: "antennaLeft.bend", to: -10.64, duration: 0 }, 0);
    near(ch.get("antennaLeft.bend") as number, -10.64);
    tw.add({ channel: "antennaLeft.bend", to: 10.64, duration: 1, ease: "none" }, 0);
    tw.tick(0.5);
    near(ch.get("antennaLeft.bend") as number, (-10.64 + 10.64 * 0.72) / 2);
    tw.tick(1);
    near(ch.get("antennaLeft.bend") as number, 10.64 * 0.72);
  });

  it("aer-016: an unmixable colour pair holds, then snaps at the end", () => {
    for (const bad of ["#０0ff41", "#abcd"]) {
      const ch = createChannels({ "body.ink": bad });
      const tw = createTweens(ch);
      tw.add({ channel: "body.ink", to: "#ff2d2d", duration: 1, ease: "none" }, 0);
      expect(() => tw.tick(0.5)).not.toThrow();
      expect(ch.get("body.ink")).toBe(bad);
      tw.tick(1);
      expect(ch.get("body.ink")).toBe("#ff2d2d");
    }
  });

  it("aer-017: a zero-duration tween applies at add time", () => {
    const ch = createChannels({ "mouth.family": "mouth" });
    const tw = createTweens(ch);
    tw.add({ channel: "mouth.family", to: "mouthO", duration: 0 }, 3);
    expect(ch.get("mouth.family")).toBe("mouthO");
    expect(tw.active()).toBe(0);
    tw.tick(3);
    expect(ch.get("mouth.family")).toBe("mouthO");
  });

  it("aer-018: a same-instant family snap survives the morph that supersedes it", () => {
    const ch = createChannels({ "mouth.shape": POLY });
    const tw = createTweens(ch);
    tw.add({ channel: "mouth.shape", to: CLOSED, duration: 0 }, 0);
    expect(ch.get("mouth.shape")).toBe(CLOSED);
    tw.add({ channel: "mouth.shape", to: SMALL, duration: 0.85, ease: "none" }, 0);
    expect(tw.active()).toBe(1);
    tw.tick(0.425);
    expect(ch.get("mouth.shape")).toBe(
      "M200,229.3C206.075,229.3,211,232.17,211,235.5C211,238.83,206.075,241.7,200,241.7C193.925,241.7,189,238.83,189,235.5C189,232.17,193.925,229.3,200,229.3Z",
    );
    tw.tick(0.85);
    expect(tw.active()).toBe(0);
  });

  it("aer-019: a cross-family path snaps on the first tick, in both directions", () => {
    const ch = createChannels({ "mouth.shape": SMALL });
    const tw = createTweens(ch);
    tw.add({ channel: "mouth.shape", to: POLY, duration: 0.3, ease: "none" }, 0);
    expect(() => tw.tick(0.1)).not.toThrow();
    expect(ch.get("mouth.shape")).toBe(POLY);
    tw.tick(0.3);
    tw.add({ channel: "mouth.shape", to: SMALL, duration: 0.3, ease: "none" }, 0.3);
    expect(() => tw.tick(0.4)).not.toThrow();
    expect(ch.get("mouth.shape")).toBe(SMALL);
  });

  it("aer-020: the replaced tween settles at the instant of the handoff", () => {
    const ch = createChannels({ x: 0 });
    const tw = createTweens(ch);
    tw.add({ channel: "x", to: 10, duration: 1, ease: "none" }, 0);
    tw.tick(0.5);
    tw.add({ channel: "x", to: 0, duration: 1, ease: "none" }, 0.75);
    near(ch.get("x") as number, 7.5);
    tw.tick(1.25);
    near(ch.get("x") as number, 3.75);
  });

  it("aer-021: an interrupted handoff lands on the same value at 60, 240 and 1000 fps", () => {
    const at = (fps: number): number => {
      const ch = createChannels({ x: 0 });
      const tw = createTweens(ch);
      tw.add({ channel: "x", to: 10, duration: 1, ease: "power2.in" }, 0);
      for (let t = 0; t < 0.41; t += 1 / fps) tw.tick(t);
      tw.add({ channel: "x", to: 0, duration: 1, ease: "none" }, 0.41);
      for (let t = 0.41; t <= 0.6; t += 1 / fps) tw.tick(t);
      tw.tick(0.6);
      return ch.get("x") as number;
    };
    near(at(60), 0.5582601);
    near(at(240), at(60));
    near(at(1000), at(60));
  });

  it("aer-022: an unknown ease is not rejected at add; resolveEase throws on the first sample", () => {
    const ch = createChannels({ x: 0 });
    const tw = createTweens(ch);
    expect(() => tw.add({ channel: "x", to: 1, duration: 1, ease: "elastic.out" }, 0)).not.toThrow();
    expect(() => tw.tick(0.5)).toThrow(/unknown ease/);
  });

  it("aer-028: cancel(channel) drops the live tween and ignores a channel with none", () => {
    const ch = createChannels({ x: 0 });
    const tw = createTweens(ch);
    tw.add({ channel: "x", to: 10, duration: 1, ease: "none" }, 0);
    tw.cancel("x");
    expect(tw.active()).toBe(0);
    expect(() => tw.cancel("y")).not.toThrow();
    tw.tick(1);
    expect(ch.get("x")).toBe(0);
  });

  it("aer-029: a future-start tween writes nothing and caches its resolved from", () => {
    const ch = createChannels({ x: 5 });
    const tw = createTweens(ch);
    tw.add({ channel: "x", to: 10, duration: 1, delay: 2, ease: "none" }, 0);
    tw.tick(1);
    expect(ch.get("x")).toBe(5);
    ch.set("x", 7);
    tw.tick(2);
    ch.set("x", 99);
    tw.tick(2.5);
    near(ch.get("x") as number, 8.5);
  });

  it("aer-030: with no stored value the starting value is the target", () => {
    const ch = createChannels();
    const tw = createTweens(ch);
    tw.add({ channel: "y", to: 10, duration: 1, ease: "none" }, 0);
    tw.tick(0.5);
    expect(ch.get("y")).toBe(10);
  });

  it("aer-031: the default ease is power3.out and the default delay is zero", () => {
    const ch = createChannels({ x: 0 });
    const tw = createTweens(ch);
    tw.add({ channel: "x", to: 1, duration: 1 }, 0);
    tw.tick(0.5);
    near(ch.get("x") as number, 0.9375);
  });

  it.skip("aer-032: ChannelValue JSON encode/decode (Apple only; the web has no ChannelValue codec)", () => {});
});
