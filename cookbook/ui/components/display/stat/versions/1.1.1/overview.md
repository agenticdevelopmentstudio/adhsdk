
The stat family in `@adh-sdk/ui` renders one label/value figure in the shared
dashboard grammar: a micro **uppercase mono** caption paired with a big, bold, mono
**value** tinted by a status tone. Two exports ship the same grammar in two shapes:

- `StatRow` — label left, big value right on a shared baseline. The dashboard-card
  form (a stack of these fills an `InfoPanel`).
- `Stat` — the value stacked over its label, right-aligned. The hero-strip form.

Both take the same `StatProps` (`label`, `value`, `tone`, `valueClassName`,
`className`) and share one cva, `statValueVariants`, whose `tone` picks the value's
color from the family status tokens (`neutral`, `muted`, `accent`, `blue`, `orange`,
`success`, `error`). The type `StatTone` is also exported. The label always uses the
micro-caption treatment — smaller and dimmer than the form-field caption, because it
is a display label under/beside a figure, not a field name.

It is a pure presentational primitive: no `"use client"`, no state, no interactivity
— `label` and `value` are `ReactNode`, so the host supplies whatever content each
holds. Extracted from the status board so every site's dashboard figures share one look.

