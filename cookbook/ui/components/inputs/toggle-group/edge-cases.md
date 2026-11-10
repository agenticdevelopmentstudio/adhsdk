
- **Deselect guard (single-select):** clicking the already-pressed item makes Base UI
  emit an empty array; the single-select consumer reads `next[0]` and ignores the
  empty array so the control always keeps exactly one selection (see the demo).
- **Value not among items:** if `value` names a value no item carries, no item is
  pressed until a valid value is selected.
- **Multi-select:** setting `multiple` lets the value array hold several values; each
  matching item shows pressed independently.
- **Uncontrolled use:** passing `defaultValue` (instead of `value`) lets Base UI own
  the selection state internally.
- **All items disabled:** the group renders but nothing is operable.

