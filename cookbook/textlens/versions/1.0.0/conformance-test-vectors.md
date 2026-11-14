
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

