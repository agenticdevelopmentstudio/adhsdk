
- **Value resolution** (see **resolves-committed-value**). If `value` equals some `items[i].value`, that item is the committed/checked row. Else if `allowOther` and `value` is non-null, Other is the committed row and its input prefills with `value`. Else nothing is checked.
- Free text identical to an item value resolves to the item; callers needing to distinguish should avoid colliding labels. The component does not correct the earlier `onChange`: it fires with the typed text and `isOther:true`, but once the caller passes that text back as `value`, the reopened menu checks the item row, not Other, and the Other input stays empty. A caller that stores `isOther` should re-derive it from `items` rather than trust the earlier flag.
- Empty `items` without `allowOther`: the surface shows no rows, and arrow keys and Enter do nothing (see **no-items-no-op-navigation**).
- ArrowUp from the Other input with no items: no effect; selection stays on Other and the input keeps focus.
- ArrowDown while Other is already the selection: stays on Other (clamped) and re-focuses the input.
- Pointer click on the Other row's label text: no effect (see **other-row-label-inert**).
- Opening when the committed value is Other free text: Other is highlighted and active, and the input is prefilled and focused.
- Enter, ArrowUp and ArrowDown while the Other input is focused but a list item is selected: see **keys-act-on-selection**.
- `value = null` → nothing is checked.
- `allowOther = false` with no matching item → nothing is checked.

