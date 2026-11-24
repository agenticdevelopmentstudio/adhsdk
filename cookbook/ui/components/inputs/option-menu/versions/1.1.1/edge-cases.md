
- **Value resolution** (see **resolves-committed-value**). If `value` equals some `items[i].value`, that item is the committed/checked row. Else if `allowOther` and `value` is non-null, Other is the committed row and its input prefills with `value`. Else nothing is checked.
- Free text identical to an item value resolves to the item; callers needing to distinguish should avoid colliding labels.
- `value = null` → nothing is checked.
- `allowOther = false` with no matching item → nothing is checked.

