
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
| T10 | remeasure-on-resize (Playwright) | active, resize host to rewrap | glyph centres re-measured; lens stays aligned |
| T11 | noop-on-empty-text | empty/whitespace `text`, active | no spans built; nothing animates |
| T12 | animate-lens-when-active | active, `pauseMs=500` | for the first ~500ms of each cycle every glyph is cleared (plain) before the sweep begins |
| T13 | animate-lens-when-active | active, 3-character `text`, default `minDuration` (4500ms) | the sweep across the string takes at least 4500ms (the duration floor applies) |

