
- **accept-numeric-value**: Component MUST accept an initial numeric value via the `value` prop.
- **call-onchange-handler**: Component MUST invoke the provided `onChange` handler with the new numeric value when the user increments, decrements, or directly edits the input.
- **clamp-to-bounds**: Component MUST clamp all values to the specified `min` and `max` bounds; values outside the range MUST be automatically adjusted to the nearest boundary.
- **respect-step-size**: Component MUST increment and decrement by the specified `step` amount (default 1).
- **keyboard-arrow-step**: While the input has focus, ArrowUp and ArrowDown MUST adjust the value by `step`, via the native `<input type="number">` spin behavior; the component adds no custom key handling beyond what the browser provides for numeric inputs.
- **disable-decrement-at-min**: Decrement button MUST be disabled when the current value is less than or equal to `min`.
- **disable-increment-at-max**: Increment button MUST be disabled when the current value is greater than or equal to `max`.
- **disable-all-controls-when-disabled**: When the `disabled` prop is `true`, all interactive elements (buttons and input) MUST be disabled and MUST NOT respond to user interaction.
- **support-direct-input**: Component MUST accept direct numeric input via an input field; non-numeric entries MUST be rejected or ignored.
- **support-optional-label**: Component MUST render an optional label element associated with the input field via `htmlFor` attribute when `label` prop is provided.
- **support-optional-hint**: Component MUST render an optional hint or help text below the control when `hint` prop is provided.
- **custom-classname**: Component MAY accept a custom CSS class name via the `className` prop for styling overrides.
- **custom-id**: Component MAY accept a custom element ID via the `id` prop; if not provided, a unique ID MUST be generated automatically.

