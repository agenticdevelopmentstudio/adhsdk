---
id: 441dd61d-3e76-499b-b45c-92869015eced
title: Text Lens
domain: adhsdk://recipes/text-lens
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-09-25
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Headless text-magnification effect (createLens, useTextLens) that sweeps a lens across per-character spans, scaling, blurring and tinting each glyph."
platforms:
- typescript
- web
tags:
- animation
- typography
- color
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Text Lens

## Overview

Text Lens (`@adh-sdk/textlens`) is a headless, framework-light
effect that sweeps a soft focal point back and forth along a line of text.
Each character the lens passes over swells, blurs and tints toward an accent
colour, then settles back as the lens moves on. It has three cooperating
pieces:

- **`color.ts`** parses a hex or `rgb()`/`rgba()` colour string into three
  numeric channels (`parseColor`) and resolves a lens colour — literal or a
  CSS custom property name — against a live element's computed style
  (`resolveColor`).
- **`lens.ts`** owns the effect itself. `createLens(elements, options)`
  destructively splits each target element's text into one `<span>` per
  character, then returns a `Lens` (`start`/`stop`/`destroy`) that drives a
  `requestAnimationFrame` loop writing `transform`, `filter` and `color`
  inline styles onto the character spans that fall within `radius` of the
  travelling centre.
- **`useTextLens.ts`** is the React binding: one `useEffect` that builds a
  lens over the elements matching `selector` inside a container ref, starts
  it (optionally after `startDelay`), and destroys it on cleanup or when
  `enabled` becomes `false`.

`createLens` has no dependency on React and no rendered surface of its own —
it mutates inline styles on elements the caller already rendered. A port to
another platform is translation work: the colour parsing, the per-frame
sweep math, and the lifecycle rules below apply identically wherever a host
can attach per-character views and drive a per-frame callback.

## Behavioral Requirements

**Colour parsing (`parseColor`)**

- **hex-parsing**: `parseColor` MUST read a string beginning `#` as a hex
  colour of 3, 4, 6, or 8 hex digits (after the `#`); any other digit count
  MUST make `parseHex` return `null`.
- **short-hex-digit-doubling**: For a 3- or 4-digit hex string, `parseHex`
  MUST double each of the first three digits (`e93` → `ee9933`) to form the
  three channel values; the fourth digit (alpha), when present, MUST be
  ignored.
- **long-hex-alpha-dropped**: For a 6- or 8-digit hex string, `parseHex` MUST
  read the first six digits as three two-digit channel values and MUST
  ignore any seventh/eighth digit (alpha).
- **rgb-function-parsing**: `parseColor` MUST read a string matching
  `rgba?(...)` (case-insensitive) by extracting its first three numeric
  arguments as the channel values, accepting either comma- or
  whitespace-separated arguments, and MUST ignore a fourth (alpha) argument
  when present.
- **whitespace-tolerance**: `parseColor` MUST trim leading and trailing
  whitespace from its input before classifying it as hex or `rgb()`.
- **unreadable-input-returns-null**: `parseColor` MUST return `null` — never
  throw — for input that is empty, a named colour (`rebeccapurple`), an
  `hsl()`/`color()` function, a hex string of any digit count other than 3,
  4, 6, or 8, a hex string containing a non-hex-digit character, or an
  `rgb()`/`rgba()` call whose first three arguments do not all parse as
  numbers.

**Colour resolution (`resolveColor`)**

- **literal-passthrough**: `resolveColor(value, element)` MUST parse `value`
  directly with `parseColor` when `value` (trimmed) does not begin with
  `--`.
- **custom-property-resolution**: `resolveColor(value, element)` MUST read
  `value` off `element`'s computed style (`getComputedStyle(element)
  .getPropertyValue(value).trim()`) when `value` (trimmed) begins with `--`,
  and MUST parse the resulting string with `parseColor`.
- **resolve-throws-on-unreadable-color**: `resolveColor` MUST throw an
  `Error` — never return a default colour — when the value to parse (the
  literal, or the custom property's computed value) is the empty string or
  fails `parseColor`.
- **resolve-error-names-both-forms**: the thrown `Error`'s message MUST
  include the original, trimmed `value` (via `JSON.stringify`) and, only
  when a custom property was read (`value !== literal`), MUST also include
  the resolved literal string it read from the computed style, in the form
  `cannot read "<value>" (resolved to "<literal>") as a colour`; when no
  custom property was involved, the `(resolved to ...)` clause MUST be
  omitted.

**Lens configuration and construction (`createLens`)**

- **default-tuning**: `createLens` MUST apply `radius = 55`, `duration =
  8000`, `scale = 0.25`, `blur = 0.35`, and `respectReducedMotion = true`
  for any option the caller omits.
- **colour-ramp-pairing**: `createLens`'s options MUST accept `fromColor`
  and `toColor` together or omit both; `resolveRamp` MUST throw an `Error`
  (`"textlens: fromColor and toColor go together — give both, or
  neither."`) when exactly one is supplied, and MUST return `null` (no
  tinting) when neither is supplied.
- **idempotent-character-split**: `createLens` MUST replace each target
  element's text with one `<span>` per character exactly once per element,
  guarded by a `textlensSplit` dataset flag; calling `createLens` again over
  an element that already carries that flag MUST leave its existing spans
  untouched rather than re-splitting them.
- **destructive-split**: the character split MUST read the element's
  `textContent` and clear the element's content (`element.textContent =
  ''`) before repopulating it with per-character spans, which discards any
  existing child element structure the target held (only its text survives
  the split).
- **space-preservation**: a plain space character MUST be rendered as a
  non-breaking space (` `) in its character span, so the span does not
  collapse to zero width under `display: inline-block`.
- **frozen-glyph-width**: after every character span for an element is
  appended to the document, each span's `width` style MUST be set to its
  measured `getBoundingClientRect().width` (one decimal place, `px`), and
  its `text-align` MUST be set to `center`, so scaling a glyph does not
  reflow its neighbours.
- **pointer-pause-registration**: `createLens` MUST attach a `pointerenter`
  listener that pauses the sweep and a `pointerleave` listener that resumes
  it to every target element, independent of whether the lens has been
  started.
- **standalone-usage**: a consumer MAY call `createLens` directly (outside
  `useTextLens`) and drive `start`/`stop`/`destroy` itself.

**Starting and stopping (`Lens.start` / `Lens.stop` / `Lens.destroy`)**

- **start-is-idempotent**: `start()` MUST be a no-op when the lens is
  already running; calling it repeatedly MUST NOT schedule more than one
  outstanding animation frame.
- **reduced-motion-gate**: `start()` MUST return without scheduling any
  animation frame when `respectReducedMotion` is `true` (the default) and
  `window.matchMedia('(prefers-reduced-motion: reduce)').matches` is `true`.
- **reduced-motion-opt-out**: `start()` MUST schedule the sweep normally,
  ignoring the reduced-motion media query, when `respectReducedMotion` is
  `false`.
- **matchmedia-unavailable-defaults-to-false**: when `window.matchMedia` is
  not a function, `prefersReducedMotion()` MUST return `false` (treat
  reduced motion as not requested) rather than throwing.
- **remeasure-on-start**: every call to `start()` MUST re-run
  `measureChars` over the current target elements' character spans,
  recomputing each span's horizontal centre from a fresh
  `getBoundingClientRect()` read, so a `start()` after a reflow sweeps over
  the text's current layout rather than a stale one.
- **empty-target-no-op**: `start()` MUST return without scheduling a frame,
  without throwing, and without resolving a colour ramp, when the
  re-measured character list is empty (no target elements, or every target
  element has no characters).
- **ramp-resolved-against-first-glyph**: when `start()` does proceed, it
  MUST resolve `fromColor`/`toColor` (when configured) via `resolveColor`
  against the first character span's element, once per `start()` call.
- **stop-cancels-and-rests**: `stop()` MUST clear the running flag, clear
  the paused flag, cancel any pending animation frame
  (`cancelAnimationFrame`), and reset every currently-measured character
  span's `transform`, `color`, and `filter` inline styles to the empty
  string.
- **stop-before-start-is-safe**: calling `stop()` on a lens that was never
  started MUST NOT throw; it rests an empty character list and cancels no
  frame.
- **destroy-tears-down-and-stops**: `destroy()` MUST call `stop()` and MUST
  remove the `pointerenter`/`pointerleave` listeners `createLens` attached
  to every target element.
- **destroy-leaves-the-split-in-place**: `destroy()` MUST NOT undo the
  character split; the target elements remain split into per-character
  spans after `destroy()` returns.

**The per-frame sweep (`apply`)**

- **radius-cutoff**: for a character span whose measured centre is more than
  `radius` CSS pixels from the current sweep centre, `apply` MUST clear that
  span's `transform`, `color`, and `filter` inline styles (rest appearance).
- **smoothstep-easing**: for a character span within `radius`, `apply` MUST
  compute `t` as the smoothstep of `1 - distance / radius` (`t = linear² ×
  (3 − 2 × linear)`), so a glyph eases into the lens rather than snapping in
  at the edge of `radius`.
- **scale-formula**: `apply` MUST set the span's `transform` to `scale(1 +
  t × scale)`, formatted to three decimal places, where `scale` is the
  configured (or default) scale depth.
- **blur-floor**: `apply` MUST compute `blur = t × blurDepth` and MUST set
  the span's `filter` to `blur(<blur to two decimal places>px)` only when
  that computed `blur` exceeds `0.03`; otherwise it MUST clear `filter` to
  the empty string, even though `t` is nonzero.
- **colour-interpolation**: when a colour ramp is resolved, `apply` MUST set
  the span's `color` to `rgb(r, g, b)` where each channel is `Math.round`
  of the linear interpolation `from + (to − from) × t` between the ramp's
  `from` and `to` channel values.
- **no-ramp-leaves-colour-untouched**: when no colour ramp is configured
  (`fromColor`/`toColor` both omitted), `apply` MUST NOT write the span's
  `color` style at all — it is left at whatever value a previous call (or
  none) left it at, aside from the rest-state clear applied outside
  `radius`.
- **leg-direction-alternation**: the sweep MUST alternate direction by
  whole legs of `duration` milliseconds: `leg = floor(elapsed / duration)`;
  an even leg MUST sweep the centre from `leftEdge` toward `rightEdge`, and
  an odd leg MUST sweep it from `rightEdge` back toward `leftEdge`, where
  `leftEdge = firstGlyphCentre − radius` and `rightEdge = lastGlyphCentre +
  radius`.
- **cubic-ease-in-out**: within a leg, the fractional progress `elapsed %
  duration / duration` MUST be eased with a cubic ease-in-out (`4p³` for `p
  < 0.5`, `1 − (−2p + 2)³ / 2` otherwise) before being applied to the
  `leftEdge`–`rightEdge` span, so the centre slows at each end of a leg
  rather than reversing abruptly.
- **continuous-until-stopped**: the sweep MUST keep scheduling a new
  animation frame and advancing `leg`/`progress` indefinitely — there is no
  configured number of passes or elapsed-time limit — until `stop()` or
  `destroy()` is called.
- **pause-rests-without-resetting-the-clock**: while `paused` is `true`,
  each scheduled frame MUST call `restChars` (rest appearance for every
  measured span) and MUST return without calling `apply`, but MUST still
  reschedule the next animation frame; the sweep's `elapsed` clock (measured
  from `start()`'s captured `startedAt`) is NOT paused — it continues to
  advance for the duration of the pause.

**React binding (`useTextLens`)**

- **selector-scoped-to-container**: `useTextLens` MUST query `selector`
  only among descendants of `containerRef.current` (via
  `querySelectorAll`), building the lens over exactly the matched elements.
- **disabled-or-missing-container-no-op**: the effect MUST do nothing
  (build no lens) when `containerRef.current` is `null` or `enabled` is
  `false`.
- **no-elements-no-op**: the effect MUST do nothing (build no lens) when
  `selector` matches zero elements inside the container.
- **effect-owns-the-full-lifecycle**: the same effect that builds a lens
  MUST be the one that starts it (after the computed delay) and destroys it
  in its cleanup; `enabled` toggling MUST be the only path a caller needs to
  stop and restart the effect.
- **destructured-effect-dependencies**: the effect's dependency list MUST be
  every individual option (`containerRef`, `selector`, `enabled`,
  `startDelay`, `radius`, `duration`, `scale`, `blur`, `fromColor`,
  `toColor`, `respectReducedMotion`) rather than the caller's `options`
  object as a whole, so a fresh options literal on every render does not by
  itself tear down and rebuild the lens.
- **deferred-first-sweep**: the effect MUST delay the lens's first `start()`
  by `startDelay` milliseconds (via `window.setTimeout`), defaulting to `0`.
- **resweep-is-immediate-after-the-first**: once the ref-tracked `swept`
  flag has been set to `true` by an earlier run of this hook instance, a
  later effect run (e.g. `enabled` toggled back to `true`) MUST start the
  lens with `0` delay rather than `startDelay` again.
- **cleanup-clears-the-pending-timer-and-destroys**: the effect's cleanup
  MUST clear the pending `setTimeout` (so a lens that never got to `start()`
  never does) and MUST call `lens.destroy()` unconditionally.

**Ordering, concurrency, and side effects**

- **single-caller-main-thread-only**: the given sources declare no locking,
  actor isolation, or `Sendable`-equivalent annotation; `createLens`,
  `Lens.start/stop/destroy`, and the DOM they mutate are usable only from
  the single JavaScript main thread they run on — there is no concurrency
  concern beyond the ordinary single-threaded browser event loop.
- **independent-lens-instances**: two `Lens` instances created over
  overlapping elements run fully independently, each with its own
  `requestAnimationFrame` chain and closed-over state; the source performs
  no coordination between instances, so overlapping lenses write
  conflicting inline styles to the same spans rather than one yielding to
  the other.
- **no-persistence-or-caching**: neither `createLens` nor `useTextLens`
  persists any state across page loads or between `Lens` instances; all
  state (`chars`, `ramp`, `frameId`, `running`, `paused`, `swept`) lives only
  in memory for the instance's lifetime.
- **side-effects-are-dom-only**: the only side effects performed are:
  mutating the DOM (splitting text into spans, writing inline styles),
  reading computed style (`getComputedStyle`, `getBoundingClientRect`), and
  scheduling/cancelling timers (`requestAnimationFrame`,
  `cancelAnimationFrame`, `setTimeout`, `clearTimeout`). There is no network,
  file, process, or storage I/O anywhere in the given sources.

## Appearance

Not applicable — this is a headless DOM-mutation effect with no rendered
surface, corner radius, padding, or font of its own; it writes inline
`transform`/`color`/`filter` styles onto character spans the caller already
rendered (see **scale-formula**, **blur-floor**, and **colour-interpolation**
under Behavioral Requirements for the exact values it writes).

## States

Not applicable — this is a headless effect, not a visual component with a
visual-state table; its runtime states (not-yet-split, running, paused,
stopped, destroyed) are covered as lifecycle requirements under Behavioral
Requirements above.

## Accessibility

Not applicable — the component renders no interactive control, role, or
label of its own; it only re-styles existing text glyphs the caller already
rendered. Its one accessibility-relevant behavior, honoring
`prefers-reduced-motion`, is covered under Accessibility Options below
rather than here.

## Conformance Test Vectors

Vectors 1–10 are traced to `color.test.ts`; vectors 11–20 to `lens.test.ts`.
Vectors 21–23 are derived directly from the `apply` arithmetic in `lens.ts`
and have no dedicated assertion in the given test files.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| text-lens-001 | hex-parsing | `parseColor('#c4a35a')` | `[196, 163, 90]` (`reads six-digit hex`) |
| text-lens-002 | short-hex-digit-doubling | `parseColor('#e93')` | `[238, 153, 51]` (`doubles the digits of short hex`) |
| text-lens-003 | long-hex-alpha-dropped | `parseColor('#c4a35a80')` | `[196, 163, 90]` (`drops the alpha channel from hex`) |
| text-lens-004 | short-hex-digit-doubling, long-hex-alpha-dropped | `parseColor('#e93f')` | `[238, 153, 51]` (`drops the alpha channel from hex`) |
| text-lens-005 | rgb-function-parsing | `parseColor('rgb(138, 138, 154)')`, `parseColor('rgb(138 138 154)')`, `parseColor('rgba(138, 138, 154, 0.5)')` | all three equal `[138, 138, 154]` (`reads rgb() and rgba(), comma- or space-separated`) |
| text-lens-006 | whitespace-tolerance | `parseColor('  #c4a35a\n')` | `[196, 163, 90]` (`tolerates surrounding whitespace`) |
| text-lens-007 | unreadable-input-returns-null | `parseColor('rebeccapurple')`, `parseColor('hsl(40 50% 50%)')`, `parseColor('#12345')`, `parseColor('#gggggg')`, `parseColor('')` | all `null` (`rejects anything it cannot read as three channels`) |
| text-lens-008 | literal-passthrough | `resolveColor('#c4a35a', div)` | `[196, 163, 90]` (`passes a literal colour straight through`) |
| text-lens-009 | custom-property-resolution | element with `--accent: #e8a33d` set; `resolveColor('--accent', el)` | `[232, 163, 61]` (`reads a custom property off the element`) |
| text-lens-010 | resolve-throws-on-unreadable-color, resolve-error-names-both-forms | `resolveColor('--missing', el)` where `--missing` is unset | throws with message containing `"--missing"` (`throws naming the property when it is not set`) |
| text-lens-011 | resolve-error-names-both-forms | element with `--accent: rebeccapurple`; `resolveColor('--accent', el)` | throws with message containing `resolved to "rebeccapurple"` (`throws showing what an unreadable property resolved to`) |
| text-lens-012 | idempotent-character-split, space-preservation | `createLens([element])` where `element.textContent === 'abc'` | 3 child `<span>`s with text `['a', 'b', 'c']` (`splits the text into one span per character`) |
| text-lens-013 | space-preservation | `createLens([element])` where `element.textContent === 'a b'` | the middle span's `textContent` is `' '` (`keeps spaces from collapsing`) |
| text-lens-014 | idempotent-character-split | `createLens([element])` called twice on the same already-split element | still 3 spans; `element.firstChild` is the same node both times (`leaves an already-split element alone`) |
| text-lens-015 | reduced-motion-gate | `matchMedia` stubbed to `{ matches: true }`; `createLens([el]).start()` | `requestAnimationFrame` is never called (`schedules no frames when the user prefers reduced motion`) |
| text-lens-016 | reduced-motion-opt-out | same stub; `createLens([el], { respectReducedMotion: false }).start()` | `requestAnimationFrame` IS called (`sweeps anyway when the caller opts out of that check`) |
| text-lens-017 | start-is-idempotent | `lens.start(); lens.start();` | `requestAnimationFrame` called exactly once (`starts once however many times it is started`) |
| text-lens-018 | destroy-tears-down-and-stops, stop-cancels-and-rests | `lens.start(); glyph.style.transform = 'scale(1.2)'; lens.destroy();` | `cancelAnimationFrame` called with the pending frame id; `glyph.style.transform === ''` (`cancels its pending frame and rests the glyphs when destroyed`) |
| text-lens-019 | destroy-tears-down-and-stops | `lens.destroy(); element.dispatchEvent(new Event('pointerenter')); lens.start();` | `requestAnimationFrame` called exactly once for the post-destroy `start()` — the pointer event after `destroy()` has no bound listener left to affect it (`stops pausing on hover once destroyed`) |
| text-lens-020 | colour-ramp-pairing | `createLens([el], { fromColor: '#8a8a9a' }).start()` (no `toColor`) | throws matching `/fromColor and toColor/` (`refuses one end of the colour ramp without the other`) |
| text-lens-021 | colour-ramp-pairing, ramp-resolved-against-first-glyph | `document.body` has `--from`/`--to` custom properties set; `createLens([el], { fromColor: '--from', toColor: '--to' }).start()` | does not throw (`reads both ends of the ramp from custom properties`) |
| text-lens-022 | radius-cutoff, smoothstep-easing, scale-formula | sweep centre exactly `radius` px from a glyph's centre (`distance === radius`) | `linear = 0`, `t = 0`; `transform` is `scale(1.000)` (no growth), `filter` is cleared (no dedicated test — derived from `apply`'s formula) |
| text-lens-023 | blur-floor | default `blur: 0.35`, glyph at the sweep centre (`distance = 0`, `t = 1`) | computed `blur = 0.35`; since `0.35 > 0.03`, `filter` is set to `blur(0.35px)` (no dedicated test — derived from `apply`'s formula) |
| text-lens-024 | leg-direction-alternation, cubic-ease-in-out | `elapsed === duration` exactly (leg boundary) | `leg = 1` (odd), `progress = 0`, `eased = 0`; the sweep centre is exactly `rightEdge` at that instant, having just switched to the return leg (no dedicated test — derived from `apply`/`step`'s formula) |

## Edge Cases

- **Null/empty input — unparseable colour string**: `parseColor` MUST return
  `null` (never throw) for `''`, a named colour, `hsl()`/`color()`, or a
  malformed hex/`rgb()` string (see **unreadable-input-returns-null**).
- **Null/empty input — no target elements or empty text**: `createLens([])`
  or `createLens` over elements whose text is empty produces zero character
  spans; a subsequent `start()` MUST return with no scheduled frame and no
  thrown error (see **empty-target-no-op**).
- **Null/empty input — selector matches nothing**: `useTextLens` MUST build
  no `Lens` at all when `selector` matches zero elements inside the
  container (see **no-elements-no-op**) — not a `Lens` that then no-ops on
  `start()`.
- **Boundary value — single-character text**: with exactly one character
  span, `firstGlyphCentre === lastGlyphCentre`, so `leftEdge`/`rightEdge`
  still diverge by `radius` on each side (`span = 2 × radius`) and the sweep
  still travels a nonzero distance across that one glyph rather than
  collapsing to a fixed point.
- **Boundary value — `blur: 0`**: with `blur` configured to `0`, the
  computed `blur` at every distance is `0`, which never exceeds the `0.03`
  floor, so `filter` is cleared unconditionally — matching the documented
  meaning of `blur: 0` ("disables it"), even though the code path is the
  same floor check every other `blur` value goes through.
- **Boundary value — `scale: 0`**: with `scale` configured to `0`,
  `transform` is written as `scale(1.000)` (a numerically neutral, but
  still-written, inline style) at every distance within `radius` — scale is
  not skipped, only rendered inert.
- **Concurrent access — overlapping lenses**: two `Lens` instances created
  over the same or overlapping elements run independently and both write
  inline styles to shared spans every frame with no coordination or
  precedence rule (see **independent-lens-instances**); the source
  documents this as the caller's responsibility (start at most one at a
  time), not a bug to be fixed internally.
- **Error state — mismatched colour ramp**: `createLens`'s `start()` throws
  synchronously when exactly one of `fromColor`/`toColor` is given (see
  **colour-ramp-pairing**). Called directly, this is a normal, catchable
  synchronous throw. Called through `useTextLens`, the same throw happens
  inside the deferred `window.setTimeout` callback that invokes
  `lens.start()`, which makes it an uncaught exception in that timer's own
  callback rather than one a `try`/`catch` around the hook call, or a React
  error boundary around the component, can intercept.
- **Error state — unreadable colour**: `resolveColor` throws for an empty or
  unparseable literal or custom-property value (see
  **resolve-throws-on-unreadable-color**); this reaches the caller through
  the same deferred-`setTimeout` path as the mismatched-ramp case when
  driven through `useTextLens`.
- **Cancellation — pause outlives the clock**: pausing (pointer-enter) rests
  every glyph immediately, but the sweep's `elapsed` clock is not paused
  (see **pause-rests-without-resetting-the-clock**); a long pause SHOULD be
  expected to make the sweep resume mid-leg (or on a different leg
  entirely) rather than resuming smoothly from the visual position it held
  when paused, because no accumulated-pause-duration bookkeeping exists in
  the source to compensate for it.
- **Cancellation — destroy while a `startDelay` timer is pending**: when
  `useTextLens`'s cleanup runs before the deferred `start()` timer has
  fired, `clearTimeout` prevents that `start()` from ever running, and
  `lens.destroy()` still runs (calling `stop()` on a lens whose `chars` is
  still `[]`, which is a no-op — see **stop-before-start-is-safe**).
- **Offline/disconnected state**: not applicable — the given sources make
  no network request of any kind (see **side-effects-are-dom-only**).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `elements` (`createLens`'s first argument) | `readonly HTMLElement[]` | — (required) | The text-bearing elements to split and sweep. |
| `options.radius` | `number` (CSS px) | `55` | Half-width of the lens; glyphs whose measured centre is farther than this from the sweep centre are left at rest. |
| `options.duration` | `number` (ms) | `8000` | Time for one pass across the text in one direction; the return pass takes the same duration again. |
| `options.scale` | `number` | `0.25` | Extra scale applied at the dead centre of the lens (`0.25` means `125%`). |
| `options.blur` | `number` (CSS px) | `0.35` | Blur applied at the dead centre of the lens; `0` disables it (see **blur-floor**). |
| `options.fromColor` | `string \| undefined` | `undefined` | Colour a glyph holds at rest: a hex/`rgb()` literal or a `--custom-property` name read off the element. Must be given together with `toColor` or omitted (see **colour-ramp-pairing**). |
| `options.toColor` | `string \| undefined` | `undefined` | Colour a glyph reaches at the dead centre of the lens; same forms and pairing rule as `fromColor`. |
| `options.respectReducedMotion` | `boolean` | `true` | When `true`, `prefers-reduced-motion: reduce` makes `start()` a no-op (see **reduced-motion-gate**). |
| `useTextLens`'s `containerRef` | `RefObject<HTMLElement \| null>` | — (required) | The container whose descendants are searched for `selector`. |
| `useTextLens`'s `selector` | `string` | — (required) | CSS selector (relative to the container) for the elements to split and sweep, e.g. `'.tag'`. |
| `useTextLens`'s `enabled` | `boolean` | `true` | `false` destroys the lens and returns its glyphs to rest; `true` (re)builds and starts it. |
| `useTextLens`'s `startDelay` | `number` (ms) | `0` | Delay before the FIRST sweep only; re-enabling later starts immediately (see **resweep-is-immediate-after-the-first**). |

## Deep Linking

Not applicable: the given sources contain no URL, route, or deep-link
handling of any kind.

## Localization

Not applicable: the three thrown error messages
(`"textlens: cannot read ... as a colour. ..."`,
`"textlens: fromColor and toColor go together — give both, or neither."`)
are fixed, non-localized diagnostic strings aimed at the developer who
misconfigured the lens, not user-facing text; the source performs no
locale-aware formatting or string lookup anywhere.

## Accessibility Options

`respectReducedMotion` (default `true`) is the one accessibility-driven
behavior in this component: when `true` and the browser reports
`prefers-reduced-motion: reduce`, `start()` never schedules a single
animation frame, so the character spans stay at rest and the sweep never
runs (see **reduced-motion-gate**). Setting `respectReducedMotion: false`
makes the sweep run regardless of that OS/browser setting (see
**reduced-motion-opt-out**). The character split itself (turning the text
into per-character spans) still happens even when reduced motion suppresses
the sweep — `createLens` does not gate the split on this setting, only the
frame-scheduling in `start()`. No other accessibility display option
(contrast, larger text, differentiate-without-color) is read anywhere in
the given sources.

## Feature Flags

Not applicable: the given sources read no feature-flag or remote-config
value; every branch is driven only by the caller's `LensOptions`/
`UseTextLensOptions` and the browser's own `matchMedia` reduced-motion
query.

## Analytics

Not applicable: the given sources contain no analytics, telemetry, or usage
event calls.

## Privacy

Not applicable: this component collects no user data. It reads text
characters and CSS custom property values that are already present in the
DOM/stylesheet the caller controls, holds them only in memory for the
`Lens` instance's lifetime, and never persists or transmits anything.

## Logging

Not applicable: the given sources contain no logging or console calls; the
only diagnostic output is the two thrown `Error` messages described above.

## Platform Notes

- **React/Web**: implemented in `packages/web/packages/textlens/src/color.ts`
  (`parseColor`, `resolveColor`), `lens.ts` (`createLens`, `Lens`,
  `LensOptions`), and `useTextLens.ts` (`useTextLens`,
  `UseTextLensOptions`), re-exported from `index.ts`. `useTextLens.ts` is
  marked `'use client'` for Next.js/RSC boundaries. There is no CSS to
  import — the effect writes inline `transform`/`color`/`filter` styles
  only, and any colour ramp is expected to live in the stylesheet as CSS
  custom properties the lens reads via `getComputedStyle`.
- **SwiftUI**: there is no per-glyph inline-style equivalent; build the
  sweep as a `TimelineView`- or `CADisplayLink`-driven per-character `Text`
  layout (an `HStack` of single-character `Text` views, each carrying its
  own `.scaleEffect`/`.blur`/`.foregroundStyle` derived from its distance to
  a `@State` sweep-centre value), with the colour ramp resolved once at
  start from `Color(nsColor/uiColor:)` or a design-token asset rather than a
  raw CSS custom property.
- **Compose**: lay the text out as a `Row` of single-character
  `Text`/`BasicText` composables inside a `Layout` that reports each
  child's centre, drive the sweep centre from a
  `withInfiniteAnimationFrameMillis`/`Animatable` value, and apply
  `Modifier.graphicsLayer { scaleX = ...; scaleY = ... }` plus a
  `renderEffect`/`BlurEffect` for the blur and `Modifier.drawWithContent` or
  a `Color` lerp for the tint — Compose's reduced-motion signal is
  `LocalAccessibilityManager`/the platform's "remove animations"
  accessibility setting rather than a CSS media query.
- **AppKit / UIKit**: split the label into one `NSTextField`/`UILabel` (or
  `CATextLayer`) per character, frozen at its measured width in an
  `NSStackView`/`UIStackView` (or manual frame layout) the same way the web
  split freezes span widths, and drive `transform`/`shadowRadius`/
  `textColor` per frame from a `CADisplayLink`; gate the sweep on
  `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (AppKit) or
  `UIAccessibility.isReduceMotionEnabled` (UIKit) in place of the web's
  `prefers-reduced-motion` query.
- **WinUI 3**: split the text into one `TextBlock` per character inside a
  `StackPanel Orientation="Horizontal"` (or a custom `Panel` that reports
  each child's centre), and drive the sweep from a per-frame
  `CompositionTarget.Rendering` handler (the closest analogue to
  `requestAnimationFrame`) writing each `TextBlock`'s `ScaleTransform`,
  a `Composition` `GaussianBlurEffect` via Win2D, and `Foreground` from a
  linear channel interpolation matching **colour-interpolation**. Gate the
  sweep on `Windows.UI.ViewManagement.UISettings.AnimationsEnabled` (the
  Windows equivalent of `prefers-reduced-motion`) in place of the web's
  media query, and resolve the colour ramp from an
  `Application.Current.Resources` brush lookup rather than a CSS custom
  property, since WinUI has no per-element computed-style read equivalent
  to `getComputedStyle`.

## Design Decisions

- **Decision**: the character split (`splitIntoChars`) is destructive and
  one-way: it replaces an element's `textContent` with per-character spans
  once, and neither `stop()` nor `destroy()` ever restores the original
  text node.
  **Rationale**: re-splitting on every `start()` would re-measure every
  glyph and visibly jitter the line for what the source's own doc comment
  calls "short static labels" — text that is not expected to change once
  split. The `textlensSplit` dataset flag makes the split idempotent so
  overlapping `createLens` calls over the same element are harmless, but
  the caller is responsible for not asking React to re-render text inside
  an already-split element (see the **Behaviour worth knowing** section of
  the package's own `README.md`).
  **Approved**: pending
- **Decision**: overlapping `Lens` instances are not coordinated — there is
  no module-level "active lens" registry, and two lenses over the same
  elements will both run and fight over the same inline styles.
  **Rationale**: the source's own doc comment on `createLens` states the
  alternative directly: a module-level "current lens" would silently stop
  whichever instance it decided was stale, from a place the caller cannot
  see or control. Requiring the caller to start at most one lens at a time
  makes that a visible decision at the call site (`useTextLens`'s `enabled`
  flag) instead of a hidden one inside the library.
  **Approved**: pending
- **Decision**: `resolveColor` throws rather than falling back to a default
  colour when a value cannot be read.
  **Rationale**: the source's own doc comment states this is deliberate — a
  lens that silently tints toward the wrong colour because of a typo'd
  custom-property name is exactly the class of bug likely to survive code
  review unnoticed, so an unresolvable colour is made to fail loudly, on
  the first frame, instead.
  **Approved**: pending
- **Decision**: pausing the sweep (via `pointerenter`) rests every glyph
  immediately but does not adjust the sweep's `startedAt` reference, so
  `elapsed` keeps advancing in real time for the whole duration of the
  pause.
  **Rationale**: not stated in the source — the pause's own comment
  addresses only that a glyph being read or about to be clicked should not
  keep swelling and blurring, and says nothing about whether resuming
  should catch up or continue smoothly. Compensating for paused time would
  require tracking accumulated pause duration, which the source does not
  do; the observable consequence is that a long hover can make the sweep
  resume mid-leg, or on a different leg entirely, rather than where it
  visually left off. This is carried here as a documented, deliberate-or-not
  fact about the current implementation (see the Edge Cases entry "pause
  outlives the clock"), not as a claim that it is the intended behavior.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | passed | Accessibility |
| [animation-frame-rate](agenticdevelopercookbook://compliance/performance#animation-frame-rate) | passed | Performance |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | partial | Performance |

`separation-of-concerns` is passed: colour parsing/resolution (`color.ts`),
the DOM/animation engine (`lens.ts`), and the React binding
(`useTextLens.ts`) are three separate modules with a one-directional import
graph (`useTextLens.ts` → `lens.ts` → `color.ts`) and no circular
dependency. `unit-test-coverage` is partial: `color.test.ts` and
`lens.test.ts` cover `parseColor`, `resolveColor`, and `createLens`'s
splitting, idempotency, reduced-motion gating, start-idempotency, teardown,
and colour-ramp validation, but the package has no test file for
`useTextLens.ts`, its React entry point. `explicit-error-handling` is
passed: `resolveColor` and `resolveRamp` both throw descriptive, traceable
`Error` messages naming the offending value rather than silently falling
back or swallowing bad input. `reduced-motion` is passed:
`respectReducedMotion` defaults to `true` and gates every scheduled frame
behind the `prefers-reduced-motion` media query. `animation-frame-rate` is
passed: the sweep is driven entirely by `requestAnimationFrame`, one frame
scheduled per callback, so it tracks the display's own refresh rate rather
than a fixed-interval timer. `main-thread-freedom` is partial: `apply()`
iterates and writes three inline styles to every measured character span,
on the main thread, once per animation frame, with no windowing or upper
bound on character count — a very long line of split text costs
proportionally more per-frame main-thread work, and the source has no
mechanism to limit or virtualize it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
