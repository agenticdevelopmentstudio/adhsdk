
- **No `trailing`**: the row is dot + label only (a bare status line); the trailing
  slot is omitted entirely.
- **Decorative dots**: the dot never carries an aria label — the row's own text
  (label + trailing) is the accessible content, so a screen reader reads the item
  once, not "status" twice, the same pattern StatusDot's own
  unlabeled-is-decorative ([adhsdk.ingredient.ui.components.display.status-dot](cookbook:1a044d34-d585-46b4-b703-dea3fb9b9642))
  requirement documents for an unlabeled dot.
- **`labelTitle` vs `label`**: pass the plain-text form as `labelTitle` so the native
  tooltip works even when `label` is rich `ReactNode`.
- **Multiple trailing bits**: wrap them in the `trailing` prop (a fragment); the
  block's trailing wrapper spaces them with a consistent gap (e.g. `24×` + a deep link).
- **`as` mismatch**: see **as-consistency** — neither component enforces the pairing,
  so a caller-side mistake renders without error but breaks list semantics.

