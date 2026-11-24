
- **indicate-selection**: RadioGroupItem MUST display a visual indicator (filled dot) when selected.
- **hide-indicator-when-unselected**: The inner indicator MUST NOT be visible when the radio button is unselected.
- **single-selection**: Within a RadioGroup, selecting one RadioGroupItem MUST deselect any previously selected item, so at most one item in the group is selected at a time.
- **disabled-state**: RadioGroupItem MUST be disableable; a disabled item MUST ignore pointer clicks and keyboard input (Space/Enter). Because Base UI's `RadioPrimitive.Root` renders as a `<span role="radio">` rather than a native button, the disabled state is exposed via `aria-disabled`/`data-disabled` and `tabindex="-1"`, not the native `disabled` attribute, so the wrapper's `disabled:` opacity/cursor utilities never match and the control is not visually dimmed.
- **focus-visible**: RadioGroupItem MUST display a focus-visible border and ring styling when focused via keyboard navigation.
- **space-selects**: RadioGroupItem MUST become selected when it has keyboard focus and the user presses Space.
- **theme-token-styling**: RadioGroupItem MUST use the toolkit's border, background, and accent theme tokens to visually distinguish its default, checked, and focused states.
- **color-transitions**: RadioGroupItem MUST transition color changes smoothly rather than switching state colors abruptly.

