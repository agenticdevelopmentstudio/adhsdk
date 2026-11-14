
- Input: `role="combobox"` with `aria-expanded`, `aria-controls` (the listbox), and `aria-activedescendant` (the active option) — all supplied by Base UI's `Autocomplete.Input`. `ariaLabel` is required and always renders as `aria-label` on the input; a non-empty `aria-label` outranks an external `<label htmlFor>` in accessible-name computation, so pairing an `id` with an external label does not make `ariaLabel` optional or change which text wins as the accessible name.
- Popup list: `role="listbox"`; each suggestion `role="option"` with `data-highlighted` on the active row.
- Keyboard: ArrowDown / ArrowUp move the active option, Enter picks it, Esc closes — handled by the primitive.
- Focus stays in the input throughout (the active option is tracked via `aria-activedescendant`, not DOM focus).

