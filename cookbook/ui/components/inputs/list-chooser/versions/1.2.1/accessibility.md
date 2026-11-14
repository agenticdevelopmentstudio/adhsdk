
- **Trigger**: `<button>` with `aria-haspopup="listbox"`, `aria-expanded={open}`, `aria-label={ariaLabel}`. Must be keyboard accessible (Enter, Space to open).
- **Filter/Add field**: `<input>` with `role="combobox"` (completes WAI-ARIA combobox pattern). Labeled by `aria-label={inputLabel ?? ariaLabel}`. Has `aria-controls={listId}` pointing to the list container, `aria-autocomplete="list"`, and `aria-activedescendant` pointing to the currently highlighted option (or undefined if no highlight).
- **List container**: `<div role="listbox">` with `aria-label={ariaLabel}`. Scrollable area with `max-height` constraint.
- **List rows**: Each row is a `<button role="option">`. Has `aria-selected="true"` on the committed row (when its value matches), `aria-selected="false"` on all others. The roving highlight is not expressed via `aria-selected`, only via `aria-activedescendant` on the combobox field. Create row is also `role="option"` with `aria-selected="false"`.
- **Focus management**: Focus moves to the field when the popover opens. On close, focus returns to the trigger.
- **Touch target size**: Rows and buttons SHOULD aim for a 44×44pt target size (11×11 units at the 4px scale) per WCAG 2.5.5 and platform HIG guidance. The current implementation is smaller than that: the trigger is a fixed 36px (`h-9`, 9 units) and list rows are `py-1.5 px-2` (6px vertical padding around 14px text, roughly 26–30px tall).
- **Keyboard paths**: All interactions (open, filter, navigate, accept, dismiss) are fully keyboard-accessible without requiring a mouse.
- **Icon labeling**: Decorative icons (chevrons, check, plus) have `aria-hidden="true"`.

