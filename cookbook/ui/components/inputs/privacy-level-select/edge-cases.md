
- **Null/undefined value**: The component assumes `value` is always a valid `PrivacyLevel` ('only-me', 'hub', or 'public'). No guard against undefined or invalid values is present; the caller MUST provide a valid initial value.
- **Rapid onChange calls**: If parent rapidly updates `value` while the popover is open, the component updates the cursor and trigger display immediately without additional validation.
- **Disabled to enabled transition**: When `disabled` prop changes from `true` to `false`, the component becomes interactive immediately; the popover will open on next trigger click without resetting internal state.
- **Rapid open/close**: If the user rapidly toggles the popover (click trigger, click again), state changes propagate correctly; cursor is reset to current value each time the popover opens.
- **Focus loss before commit**: If the user navigates with arrow keys, then clicks outside the popover before selecting an option, the popover closes without calling `onChange` and the cursor state is discarded.
- **ArrowDown on trigger with closed popover**: User presses ArrowDown on trigger button — popover opens (does not scroll page). Same for Space and Enter.
- **Empty string or whitespace ariaLabel**: If `ariaLabel` is an empty string or whitespace, it is used as-is (no fallback validation); the component will render with that empty/whitespace label.
- **Multiple instances on same page**: Each instance uses `React.useId()` to generate unique IDs; options from different instances will not conflict in ARIA linkage or in the DOM.
- **Disabled option interaction**: The "Team / Org" option is not keyboard-navigable (arrow keys skip it) and has `role="option"` + `aria-disabled="true"` but is a `<div>`, not a button, so it is not clickable (no onClick handler, no pointer events enabled).
- **Hover during keyboard navigation**: If the user navigates with arrow keys while hovering, the highlight state is shared (same `apt-highlight/15` background); the visual result is the same whether cursor or hover caused it.
- **Window resize during popover open**: The Popover component (not this component) handles repositioning; this component makes no special handling.
- **Keyboard navigation null cursor recovery**: The `move` function's null-cursor branch seeds index 0 and then applies the delta, so a hypothetical ArrowDown with a null cursor would land on index 1 ("hub"), and ArrowUp would land on index 0 ("only-me") — not "only-me" for both directions. This branch cannot run through the UI: the listbox surface only exists while the popover is open, and `cursor` is already `value` (never `null`) by the time the popover opens, set in the same synchronous update that sets `open` to `true` — see **initialize-null-cursor-to-first-option**.

