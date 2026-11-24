
- Both `label` and `value` render as plain text spans, so assistive tech announces
  them in DOM order: label-then-value for `StatRow`, and value-then-label for `Stat`
  (the value leads the column form visually and in the reading order).
- In the column form (`Stat`), that reading order means a screen reader hears the
  value before it has the label's context (e.g. "3" before "failures · 24h").
  Callers SHOULD group the two for assistive tech when that would be confusing on
  its own — e.g. an `aria-label` on the wrapper combining label and value, or the
  platform's accessibility-element-grouping equivalent — rather than relying on
  reading order alone.
- Tone is conveyed by color only — it carries no ARIA and adds no accessible name;
  the `label` is the sole textual meaning, so callers SHOULD keep the label
  descriptive (e.g. "failures · 24h") rather than leaning on the red tint alone.
- Purely presentational: no role, not focusable, not interactive.
- Color and contrast come from the `apt-*` theme tokens, consistent in light and dark.

