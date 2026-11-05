# @adh-sdk/textlens

A travelling lens for a line of text. A soft focal point drifts back and forth
along the line; each character it passes swells slightly, blurs slightly, and
tints toward an accent colour, then settles back as the lens moves on.

## Why

The effect only reads as a *lens* if the glyphs deform individually, which means
per-character elements and a per-frame write to each one. Doing that by hand
tends to produce three problems, and this package exists to have already solved
them:

- **The colour ramp goes stale.** The obvious implementation hardcodes the two
  endpoint colours in JavaScript, where the next theme change silently misses
  them. `fromColor` / `toColor` accept CSS custom property names, so the ramp
  stays in the stylesheet with the rest of the palette.
- **The line reflows.** Scaling a glyph in normal flow shoves its neighbours
  around. Each character span is frozen at its measured width, so the lens
  distorts the text without moving it.
- **The animation outlives the component.** A raw `requestAnimationFrame` loop
  keeps running, and keeps writing to detached nodes, long after React has
  moved on. `useTextLens` builds and destroys the lens in one effect.

## Usage

```tsx
'use client'

import { useRef } from 'react'
import { useTextLens } from '@adh-sdk/textlens'

export function TagRow({ tags, anyPanelOpen }) {
  const rowRef = useRef<HTMLDivElement>(null)

  useTextLens(rowRef, {
    selector: '.tag',
    enabled: !anyPanelOpen,
    startDelay: 2000,
    fromColor: '--text-muted',
    toColor: '--accent',
  })

  return (
    <div ref={rowRef}>
      {tags.map((tag) => (
        <span className="tag" key={tag}>{tag}</span>
      ))}
    </div>
  )
}
```

Outside React, drive it directly:

```ts
import { createLens } from '@adh-sdk/textlens'

const lens = createLens([...document.querySelectorAll<HTMLElement>('.tag')], {
  fromColor: '--text-muted',
  toColor: '--accent',
})

lens.start()
// later
lens.destroy()
```

There is no CSS to import. The lens writes inline styles only.

## Options

Shared by `createLens` and `useTextLens`:

| Option | Default | Meaning |
| --- | --- | --- |
| `radius` | `55` | Half-width of the lens in CSS pixels. Glyphs beyond it are untouched. |
| `duration` | `8000` | Milliseconds for one pass. The return trip takes the same again. |
| `scale` | `0.25` | Extra scale dead centre — `0.25` is 125%. |
| `blur` | `0.35` | Blur in pixels dead centre. `0` disables it. |
| `fromColor` | — | Colour at rest. Hex, `rgb()`, or a `--custom-property` read off the text. |
| `toColor` | — | Colour dead centre, same forms. |
| `respectReducedMotion` | `true` | Honour `prefers-reduced-motion: reduce` by never starting. |

`fromColor` and `toColor` go together: give both to tint, or neither to leave
colour alone. One without the other throws rather than guessing at the missing
end. An unreadable colour throws too — a lens tinting toward the wrong colour is
the kind of bug that survives review.

`useTextLens` adds:

| Option | Default | Meaning |
| --- | --- | --- |
| `selector` | — | Required. Selects the text elements inside the ref'd container. |
| `enabled` | `true` | False destroys the lens and returns the glyphs to rest. |
| `startDelay` | `0` | Milliseconds before the first sweep. Re-enabling later starts at once. |

## API

| Export | Shape |
| --- | --- |
| `createLens(elements, options?)` | Returns a `Lens` — `{ start, stop, destroy }`. |
| `useTextLens(ref, options)` | Runs one lens over `ref`'s matching descendants. |
| `parseColor(value)` | `Rgb \| null` — hex or `rgb()`/`rgba()`, alpha dropped. |
| `resolveColor(value, element)` | `Rgb`, resolving `--custom-property` against `element`. Throws otherwise. |

`start()` re-measures before each sweep, so it is safe to call after a reflow,
and is a no-op while already running. `stop()` returns every glyph to rest and
can be started again. `destroy()` also releases the hover listeners.

## Behaviour worth knowing

**The character split is one-way.** The first `createLens` over an element
replaces its text node with one `<span>` per character and leaves them there —
including after `destroy()`. Re-splitting on every start would re-measure every
glyph and visibly jitter the line. The consequence is that React must not expect
to re-render that text: give the element static content, or key it so React
replaces the node outright rather than patching the text it thinks is inside.

**The lens holds still under the pointer.** Pointer-enter on a target pauses the
sweep and rests its glyphs; pointer-leave resumes. Text you are reading, or
about to click, should not be swelling and blurring while you decide.

**Lenses do not coordinate.** Each one owns its own frame loop and its own
state. Two lenses over the same text will both run and fight over the inline
styles. That is deliberate: the alternative is a module-level "current lens"
that silently stops whichever one it decides is stale, from a place the caller
cannot see. Start one at a time — `enabled` makes that a visible decision at the
call site.
