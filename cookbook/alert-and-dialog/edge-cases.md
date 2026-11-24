
- When the two natural widths differ enough, the narrower button renders at its own natural width and the wider one absorbs the remaining share, capped at its own natural width, rather than both snapping to an equal split.
- A key mapped to a button that is not rendered is ignored.
- Escape always dismisses via cancel (or, in alert mode, via the action) whenever the keyboard policy is not `"none"` and the modal is not `busy`, even when the explicit map omits Escape or maps it to a different action, because Escape is routed by `onOpenChange` (`escape-routing`) and not by the key map.
- `destructive` overrides any supplied `keyboard` value (forced `"none"`) so a delete is always an explicit click.
- `busy` blocks all dismissal paths and hides the buttons behind a spinner.

