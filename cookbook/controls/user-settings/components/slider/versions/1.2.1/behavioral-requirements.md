
- **range-input**: Component MUST render an HTML5 `<input type="range">` element with the specified `value`, `min`, `max`, and `step` attributes.
- **accept-value**: Component MUST accept a controlled `value` prop (number) and reflect it in the input element.
- **change-callback**: Component MUST call the `onChange` callback with the new value converted to a number (`Number(event.target.value)`) when the user interacts with the range input.
- **optional-label**: Component MUST render an optional `<label>` element when the `label` prop is provided; the label MUST have an `htmlFor` attribute pointing to the input's ID.
- **optional-hint**: Component MUST render an optional hint text element when the `hint` prop is provided, positioned below the slider.
- **optional-caption**: Component MUST render an optional caption element when the `caption` prop is provided; if `caption` is a function, the component MUST call it with the current `value` and render the result.
- **disabled-state**: Component MUST disable the input element when the `disabled` prop is `true`.
- **default-min**: Component MUST use a default `min` value of `0` when the `min` prop is not provided.
- **default-max**: Component MUST use a default `max` value of `100` when the `max` prop is not provided.
- **default-step**: Component MUST use a default `step` value of `1` when the `step` prop is not provided.
- **generate-id**: Component MUST generate a unique ID for the input when the `id` prop is not provided, using React's `useId` hook.
- **label-association**: Component MUST use the same ID (either provided or generated) for both the input's `id` attribute and the label's `htmlFor` attribute to ensure proper semantic association.
- **apply-classes**: Component MUST apply the CSS classes `aws-field` and `aws-field--slider` to the wrapper element, and MUST append any `className` prop provided.

