
- **Trigger**: `<button>` with `aria-haspopup="listbox"`, `aria-expanded={open}`, `aria-label={ariaLabel}`. MUST be keyboard accessible (Enter, Space to open).
- **Filter/Add field**: `<input>` with `role="combobox"` (completes WAI-ARIA combobox pattern). MUST be labeled by `aria-label={inputLabel ?? ariaLabel}`, MUST have `aria-controls={listId}` pointing to the list container and `aria-autocomplete="list"`, and MUST set `aria-activedescendant` to the currently highlighted option (or leave it unset if no highlight).
- **List container**: `<div role="listbox">` with `aria-label={ariaLabel}`. Scrollable area with `max-height` constraint.
- **List rows**: Each row is a `<button role="option">`. The committed row MUST have `aria-selected="true"` (when its value matches) and all others MUST have `aria-selected="false"`. The roving highlight is not expressed via `aria-selected`, only via `aria-activedescendant` on the combobox field. Create row is also `role="option"` with `aria-selected="false"`.
- **Focus management**: Focus moves to the field when the popover opens. On close, focus returns to the trigger.
- **Touch target size**: Rows and buttons MUST meet the WCAG 2.2 AA minimum target size of 24×24 CSS px (2.5.8) and SHOULD aim for 44×44pt (11×11 units at the 4px scale) per WCAG 2.5.5 and platform HIG guidance. The current implementation meets the 24px floor but is smaller than 44: the trigger is a fixed 36px (`h-9`, 9 units) and list rows are `py-1.5 px-2` (6px vertical padding around 14px text, roughly 26–30px tall).
- **Keyboard paths**: All interactions (open, filter, navigate, accept, dismiss) are fully keyboard-accessible without requiring a mouse.
- **Icon labeling**: Decorative icons (chevrons, check, plus) MUST have `aria-hidden="true"`.

