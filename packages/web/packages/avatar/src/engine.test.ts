import { describe, it, expect } from "vitest";
import * as Avatar from "./index";
import { DEFAULT_TUNING, type Tuning } from "./types";

// Smoke tests only: guard the public API surface + tuning contract. The engine is
// a GSAP-driven hook — its motion is verified in-app (it can't be asserted headless).
describe("@adh-sdk/avatar public API", () => {
  it("exports the engine hook and every reflex/pose piece", () => {
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
      "travelFrom",
    ]) {
      expect(typeof surface[name]).toBe("function");
    }
  });

  it("ships a complete default tuning (every field a number)", () => {
    const keys: (keyof Tuning)[] = [
      "gazeMax",
      "tiltMax",
      "leanMax",
      "wanderAfterMs",
      "wanderMinMs",
      "wanderMaxMs",
      "blinkDurationMs",
      "minBlinkMs",
      "maxBlinkMs",
      "boredAfterMs",
      "asleepAfterMs",
      "alertAfterTypingMs",
      "sleepMutterMs",
    ];
    for (const k of keys) expect(typeof DEFAULT_TUNING[k]).toBe("number");
  });
});
