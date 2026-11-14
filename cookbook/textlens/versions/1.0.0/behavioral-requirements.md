
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

