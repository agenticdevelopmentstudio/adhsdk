
- **renders-badge-body**: The component MUST render its `children` inside a `Badge` so the chip inherits the badge tone and pill styling.
- **renders-remove-button**: The component MUST render the ✕ affordance as a real `<button type="button">`, not a bare icon or a `<span>`.
- **remove-button-named**: The remove button MUST carry `removeLabel` as its accessible name (`aria-label`).
- **invokes-onremove-on-click**: Clicking the enabled remove button MUST invoke the `onRemove` callback.
- **stateless-removal**: The component MUST NOT mutate or remove itself; it only signals `onRemove`, leaving list state to the consumer.
- **applies-badge-variant**: The component MUST pass its `variant` through to the `Badge` (default `neutral`), so callers MAY tone the chip.
- **disabled-blocks-remove**: When `disabled`, the remove button MUST be a native disabled `<button>` and MUST NOT invoke `onRemove`.
- **remove-icon-decorative**: The ✕ glyph itself MUST be hidden from AT (`aria-hidden`), leaving the button's `aria-label` as the sole accessible name.
- **forwards-chip-props**: The component MUST forward arbitrary span props (`className`, `id`, `data-*`) onto the `Badge` body.
- **keyboard-operable**: The remove button MUST be activatable via keyboard (Enter or Space), invoking `onRemove`, because it is a native `<button>` rather than a non-focusable element with a click handler.

