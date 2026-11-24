
The stat family in `@adh-sdk/ui` renders one label/value figure in the shared
dashboard grammar: a micro **uppercase mono** caption paired with a big, bold, mono
**value** tinted by a status tone. Three exports ship the grammar:

- `StatRow` — label left, big value right on a shared baseline. The dashboard-card
  form (a stack of these fills an `InfoPanel`).
- `Stat` — the value stacked over its label, right-aligned by default (`align`
  switches it to left-aligned). The hero-strip form.
- `StatStrip` — a left-aligned, wrapping row of `Stat`s: a card's headline figures.

`StatRow` takes `StatProps` (`label`, `value`, `tone`, `valueClassName`,
`className`); `Stat` takes `StatColumnProps`, which is `StatProps` plus `align`.
Both share one cva, `statValueVariants`, whose `tone` picks the value's color from
the family status tokens (`neutral`, `muted`, `accent`, `blue`, `orange`, `success`,
`error`). The tone-to-class table is the single shared `TONE_TEXT_CLASS` in
`lib/tone.ts`, which `StatusDot` also reads. The type `StatTone` is also exported. The label always uses the
micro-caption treatment — smaller and dimmer than the form-field caption, because it
is a display label under/beside a figure, not a field name.

It is a pure presentational primitive: no `"use client"`, no state, no interactivity
— `label` and `value` are `ReactNode`, so the host supplies whatever content each
holds. Extracted from the status board so every site's dashboard figures share one look.

