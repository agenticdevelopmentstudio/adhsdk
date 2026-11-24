
- **Role**: The input MUST have `role="spinbutton"` or be a native `<input type="number">` element (preferred). Buttons MUST be implemented as native `<button type="button">` elements; `role="button"` MUST NOT be reasserted via ARIA since it is already implicit on `<button>`.
- **Label**: When a label is provided, the input MUST be associated via `<label htmlFor>` attribute. If no label is provided but hint or context exists, the input SHOULD have an `aria-label` or `aria-labelledby`.
- **Button labels**: Decrement and increment buttons MUST have clear, descriptive `aria-label` attributes, sourced from the localized strings ("Decrement", "Increment"; see Localization). These labels are generic and do not incorporate the field's `label` (see Edge Cases).
- **Announce disabled state**: When a button is disabled, its `disabled` attribute MUST be set; screen readers announce this state automatically.
- **Minimum tap target**: Buttons MUST be at least 44×44pt on iOS and 48×48dp on Android; web buttons SHOULD be at least 44×44px.
- **Keyboard navigation**: Input MUST accept focus and allow direct number entry via keyboard. While focused, ArrowUp/ArrowDown MUST adjust the value by `step` (see **keyboard-arrow-step**); PageUp/PageDown and Home/End are not handled, since native `<input type="number">` elements do not provide that behavior and the component adds no custom key handling. Buttons MUST accept focus and respond to Enter or Space key presses (native `<button>` behavior).

