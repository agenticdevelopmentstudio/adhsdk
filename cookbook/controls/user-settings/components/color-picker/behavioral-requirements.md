
- **render-label**: The component MUST render a label element associated to the input when a `label` prop is provided.
- **accept-value**: The component MUST accept a `value` prop containing a valid hex color string (e.g., `#ff0000`); the native color input normalizes any accepted value to a 6-digit lowercase hex string (`#rrggbb`).
- **fire-change**: The component MUST invoke the `onChange` callback with the new hex color string, as reported by the native input in lowercase `#rrggbb` form, when the user selects a color from the picker.
- **render-hex-display**: The component MUST display the `value` prop verbatim, as text adjacent to the picker; this text is not normalized by the native input — only the input element itself receives the browser's lowercase `#rrggbb` sanitization.
- **support-disabled**: The component MUST respect a `disabled` prop and prevent interaction when `true`.
- **render-hint**: The component MUST render hint text when a `hint` prop is provided.
- **generate-id**: The component MUST generate a unique `id` for the color input if no `id` prop is provided, and that generated id MUST be stable across server and client rendering (the reference implementation uses React `useId`).
- **hide-hex-from-assistive-tech**: The component SHOULD mark the hex value display with `aria-hidden="true"` to prevent duplicate announcements by screen readers. This rests on an unverified assumption (see Accessibility); a port MAY instead point `aria-describedby` on the input at the hex text.
- **accept-classname**: The component MAY accept a `className` prop to allow custom CSS classes to be applied to the field container.

