
- Equal-width vs right-justified is governed by whether the row is too narrow for both buttons at their natural width, not by a fixed `2 × Wmax` multiple of the larger button; when the two natural widths differ enough, the narrower button can render at its own (smaller) natural width while the wider one absorbs the remaining share, capped at its own natural width, rather than both snapping to an equal split.
- A key mapped to a button that is not rendered is ignored.
- Escape always dismisses via cancel (or, in alert mode, via the action) whenever the keyboard policy is not `"none"`, even when the explicit map omits Escape or maps it to a different action — Base UI's built-in escape-key handling is independent of the key map and cannot be overridden by it.
- `destructive` overrides any supplied `keyboard` value (forced `"none"`) so a delete is always an explicit click.
- `busy` blocks all dismissal paths and hides the buttons behind a spinner.

