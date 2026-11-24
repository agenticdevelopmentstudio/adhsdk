
- `label` and `value` are `ReactNode`: a value of `0` renders as "0" (not treated as
  falsy/blank), and either slot MAY hold a fragment, number, or icon+text.
- `valueClassName` that sets a `text-*` color wins over the tone token because `cn()`
  runs `tailwind-merge`, which drops the earlier conflicting `text-*` class instead of
  leaving both in the string; a class touching only non-color properties leaves the
  tone hue untouched.
- With `tone` left `undefined`, the cva default applies (`neutral`). `StatTone` is a
  closed union of the seven tones, so passing any other string is a compile-time type
  error, not a runtime fallback.
- No truncation or wrapping is imposed — a very long value in `StatRow` competes with
  the label across `justify-between`; the host sizes the container.
- The two forms are separate exports on one grammar: pick `StatRow` inside cards,
  `Stat` for a right-aligned hero strip; there is no orientation prop.

