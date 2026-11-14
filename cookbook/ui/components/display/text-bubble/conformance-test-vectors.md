
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-plain-text + decorative-when-inactive | `active={false}` | host `textContent` equals `text`; no glyph spans |
| T2 | animate-lens-when-active | `active={true}`, wait a frame | host contains per-glyph `<span>`s with inline `transform` on some |
| T3 | scale-and-blur-under-lens (Playwright) | active, sample styles over frames | at least one glyph shows `scale(>1)` and a `blur()` filter near the lens |
| T4 | color-shift-under-lens | `colorFrom` ≠ `colorTo`, active | an in-lens glyph carries an inline `color: color-mix(...)` |
| T5 | preserve-accessible-text | active | an off-screen span holds the full string; the visible copy is `aria-hidden="true"` |
| T6 | restore-on-cleanup | active → `active={false}` (or unmount) | host `textContent` equals original `text`; no spans/inline transforms |
| T7 | skip-cursive-scripts | `text` = Arabic string, active | text unchanged; no per-character spans created |
| T8 | not-break-words-at-wrap | multi-word text, active | each word wrapped in an `inline-block; white-space:nowrap` span |
| T9 | follow-text-direction | `dir="rtl"` host, active | reading order sorts right-to-left within each line |
| T10 | remeasure-on-resize (Playwright) | active, resize host to rewrap | glyph centres are re-measured, so each glyph's lens centre equals its current `offsetLeft + offsetWidth / 2`, `offsetTop + offsetHeight / 2` |
| T11 | noop-on-empty-text | empty/whitespace `text`, active | no spans built; nothing animates |
| T12 | idle-hold-before-sweep | active, `pauseMs=500` | for the first 500ms of each cycle (give or take one animation frame) every glyph is cleared (plain) before the sweep begins; with `pauseMs=0` the first sweep starts immediately |
| T13 | sweep-duration | active, 3-character `text`, default `minDuration` (4500ms) | the sweep across the string takes 4500ms, since `max(4500, 3 × 48)` is the floor; a 200-character string takes `200 × 48` = 9600ms |
| T14 | splitting unit (edge case) | active, `text` = `"e\u0301 \u{1F468}\u200D\u{1F469}"` | one span per code point: `e`, the combining mark, the two emoji and the ZWJ are each their own span |
