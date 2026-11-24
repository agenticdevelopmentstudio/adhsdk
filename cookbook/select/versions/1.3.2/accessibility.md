
- **Role**: A single-select `<select>` element with no `size` attribute (as used here) maps to the implicit ARIA role `combobox`; no custom role is required.
- **Label requirement**: The `label` prop is optional. When provided, it MUST be associated to the select via the `htmlFor` attribute on the `<label>` element, matching the select's `id` (see **label-association**). No fallback ARIA properties (`aria-label`, `aria-labelledby`) are implemented; when `label` is omitted, the control has no accessible name from the component itself.
- **Keyboard navigation**: Native select supports keyboard navigation; users can open the dropdown with Space or Enter, navigate with arrow keys, and select with Enter. This is provided by the browser and requires no component implementation.
- **Minimum touch target**: The control's visual height is 36px (`h-9`), which falls short of the 44×44pt minimum touch target (WCAG 2.1 SC 2.5.5 Target Size, Enhanced).
- **Hint association**: The hint text renders as a sibling `<p>` element; the select has no `aria-describedby` attribute referencing it (see **hint-described-by**), so screen readers do not announce the hint as descriptive text for the control.
- **Disabled state announcement**: Native select announces disabled state to assistive technologies automatically; the component applies no additional ARIA attributes.

