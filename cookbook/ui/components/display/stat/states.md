
| State | Appearance change |
|---|---|
| `neutral` (default) | value takes the neutral tone class (see **tints-value-by-tone**) |
| `muted`, `accent`, `blue`, `orange`, `success`, `error` | value takes that tone's class from the same table; `muted` is the de-emphasized figure |
| `valueClassName` override | value hue replaced by the supplied class (wins over tone) |
| Row form (`StatRow`) | label left, value right, shared baseline |
| Column form (`Stat`) | value over label, right-aligned |
| Column form, `align="start"` | value over label, left-aligned |
| `StatStrip` | `Stat`s in a wrapping, left-aligned row |

No interactive states — the primitive is not focusable, hoverable, or disable-able.

