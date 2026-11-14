
`TextBubble` (`@adh-sdk/ui`) renders a string and runs a purely **cosmetic**
traveling-"distortion lens" over it: a soft lens glides along the text in reading
order, and each glyph under the lens is magnified, faintly blurred, and
colour-shifted from `colorFrom` toward `colorTo`. When the lens reaches the end
it restarts at the beginning (a forward loop), optionally parking for `pauseMs`
between sweeps.

A separate headless primitive, `@adh-sdk/textlens`
([adhsdk.ingredient.textlens](cookbook:441dd61d-3e76-499b-b45c-92869015eced)), sweeps a lens over per-character spans
that a caller has already built. `TextBubble` does its own splitting, owns its own
forward loop, and does not compose it.

The effect is decoration only — the real text content stays intact and legible:

- The element renders `text` as plain content first (crawlable, accessible), and
  the lens only splits it into per-glyph spans **while `active`**.
- While animating, an off-screen copy of the full string is kept for assistive
  tech, and the visible per-glyph copy is marked `aria-hidden`.
- On cleanup (or `active === false`) the original plain text is restored.

Two symbols ship from `@adh-sdk/ui/components/text-bubble`:

- `TextBubble` — the component: `<TextBubble text as className style {...options} />`.
- `useTextBubble(options)` — the underlying hook, returning a ref to attach to any
  real DOM element whose text the lens should ride over.

