
- **Role**: The trigger MUST be a button (`<button>` or `role="button"`).
- **Label**: The trigger MUST have accessible text from its label content (e.g., "Category").
- **Count Semantics**: The count in the trigger (e.g., "(3)") MUST be included in the accessible label to convey how many filters are active; see **stale-selection-values** for how it counts values no longer present in `options`, and #localization/facet.trigger_count for how the format must be produced.
- **Chevron Icon**: The chevron-down icon MUST be marked `aria-hidden="true"`. It is decoration only — the collapsible/expanded state is not conveyed by the label or the chevron, but by **trigger-expanded-state** (`aria-expanded`/`aria-haspopup` on the trigger itself).
- **Checkbox Labels**: Each checkbox MUST have an associated label via `<label>` wrapping. The label text is derived from the option value or the `labelOf` function; the base checkbox component points `aria-labelledby` at the wrapping `<label>` automatically.
- **Checkbox State**: Each checkbox MUST have `aria-checked` set to match the checked state (the checkbox is an ARIA-pattern control, not a native `<input type="checkbox">`, so this state is not implicit).
- **Popover Accessibility**: The popover MUST be exposed with `role="dialog"` (provided by the underlying Popover component) — a non-modal disclosure surface, not a menu. Focus SHOULD move to the first interactive element in the popover (per platform conventions).
- **Keyboard Navigation**: The popover MUST be navigable by keyboard (Tab moves between checkboxes and buttons; Enter or Space toggles a checkbox); the Escape key or clicking outside SHOULD close the popover without altering the selection (see **preserve-selection-state**).
- **Touch Target**: All interactive elements (trigger button, checkboxes, quick-select buttons) MUST have a touch target of at least 44×44px on touch-enabled platforms; on web with mouse/pointer input, 16×16px is acceptable for checkboxes if the associated label is large enough to encompass a 44×44px target.

