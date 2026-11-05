# @adh-sdk/avatar

A headless avatar **behavior + animation engine**. You bring an SVG face and a
table of poses; the engine gives it reflexes (blink, idle ladder, gaze, speech)
and an expression-driven pose loop. It's persona-agnostic — no face's anatomy or
mood names are baked in.

## The split

- **This package** owns *behavior*: the `useAvatarEngine` hook + the reflex/pose
  pieces it composes.
- **An avatar package** (e.g. `@olylo/avatar`) owns *identity*: the SVG it draws,
  its `Pose` data, its palette, and any choreographed one-shots. It calls
  `useAvatarEngine` and renders.

The public puppet contract a driver sets — `{ expression, gaze, onSpeak, mute }`
(`AvatarDriverProps`) — is the same for every avatar.

## Optional channels

The engine animates a fixed vocabulary of **optional** channels. Wire only the
ones your avatar has; absent channels are skipped by every effect:

| Channel | What it animates |
|---|---|
| `body` | whole-glyph emotional scale / rotation / entry spin |
| `eyes` | eye open/size scale, spread, per-eye squint, + blink groups |
| `iris` | steerable pupils (gaze) + dilation |
| `antennae` | bendy feelers (rotation/y + an always-on bend/wiggle) |
| `brows` | eyebrow raise/swing |
| `mouth` | a morphing mouth path |
| `descender` | a tail that morphs between a "logo" and "plain" path |
| `face` | chameleon color + bob/wiggle loops |

Avatar geometry (the central `pivot`, brow/antenna pivots, the antenna `bend`
curve, the descender paths) is supplied via the rig, so the engine stays pure
mechanism. Reflex timings live in `Tuning` (override per avatar; see
`DEFAULT_TUNING`).

## Minimal avatar (eyes + brows only)

```tsx
"use client";
import { useRef } from "react";
import { useAvatarEngine, type AvatarRig, type Pose } from "@adh-sdk/avatar";

type Mood = "idle" | "happy" | "sad" | "asleep";

const POSES: Record<Mood, Pose> = {
  idle:   { dur: 0.45, ease: "power3.out", eye: { scaleX: 1, scaleY: 1 }, browLeft: { y: 0, rotation: -7 }, browRight: { y: 0, rotation: 7 }, sayings: ["hi."] },
  happy:  { dur: 0.3,  ease: "back.out(1.7)", eye: { scaleX: 1.1, scaleY: 1.1 }, browLeft: { y: -5, rotation: -15 }, browRight: { y: -5, rotation: 15 } },
  sad:    { dur: 0.7,  ease: "sine.out", eye: { scaleX: 1, scaleY: 0.6 }, browLeft: { y: -3, rotation: -8 }, browRight: { y: -3, rotation: 8 } },
  asleep: { dur: 0.75, ease: "sine.out", eye: { scaleX: 1, scaleY: 0.07 }, browLeft: { y: 9, rotation: -12 }, browRight: { y: 9, rotation: 12 }, sayings: ["zzz"] },
};

export function Face() {
  const svg = useRef<SVGSVGElement>(null);
  const leftEye = useRef<SVGGElement>(null);
  const rightEye = useRef<SVGGElement>(null);
  const leftBrow = useRef<SVGGElement>(null);
  const rightBrow = useRef<SVGGElement>(null);

  const rig: AvatarRig = {
    svg,
    pivot: "50 50",
    eyes: { leftRef: leftEye, rightRef: rightEye },
    brows: { leftRef: leftBrow, rightRef: rightBrow, leftOrigin: "30 50", rightOrigin: "70 50" },
    // no iris / antennae / mouth / descender / body / face → those channels are skipped
  };

  const { poke } = useAvatarEngine<Mood>({
    poses: POSES,
    rig,
    moods: { idle: "idle", asleep: "asleep" }, // bored falls back to idle
  });

  return (
    <svg ref={svg} viewBox="0 0 100 100" onClick={poke}>
      {/* draw your eyes (leftEye/rightEye) and brows (leftBrow/rightBrow) here */}
    </svg>
  );
}
```

To add a choreographed one-shot (like olylo's yawn), pass `choreography` (a map
of expression → a function returning a GSAP timeline). To add incidental per-mood
motion, pass `perExpressionEffects`. See `@olylo/avatar` for a fully-wired example.
