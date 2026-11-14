
- **range-input**: Component MUST render an HTML5 `<input type="range">` element with the specified `value`, `min`, `max`, and `step` attributes.
- **accept-value**: Component MUST accept a controlled `value` prop (number) and reflect it in the input element.
- **change-callback**: Component MUST call the `onChange` callback with the new value converted to a number (`Number(event.target.value)`) when the user interacts with the range input.
- **optional-label**: Component MUST render a `<label>` element if and only if the `label` prop is truthy. The ID wiring is specified in #requirements/label-association.
- **optional-hint**: Component MUST render a hint text element, positioned below the slider, if and only if the `hint` prop is truthy.
- **static-caption**: When `caption` is provided and is not a function, Component MUST render it in the caption element (`aws-slider__caption`). The caption is omitted only when it is `undefined`, so `caption={0}` renders "0".
- **function-caption**: When `caption` is a function, Component MUST call it with the current `value` and render the result in the caption element.
- **disabled-state**: Component MUST disable the input element when the `disabled` prop is `true`.
- **default-min**: Component MUST use a default `min` value of `0` when the `min` prop is not provided.
- **default-max**: Component MUST use a default `max` value of `100` when the `max` prop is not provided.
- **default-disabled**: Component MUST leave the input enabled (no `disabled` attribute) when the `disabled` prop is not provided; the default is `false`.
- **default-step**: Component MUST use a default `step` value of `1` when the `step` prop is not provided.
- **generate-id**: Component MUST give the input a unique, non-empty `id` that is stable across re-renders when the `id` prop is not provided, and the label MUST share it.
- **label-association**: Component MUST use the same ID (either provided or generated) for both the input's `id` attribute and the label's `htmlFor` attribute to ensure proper semantic association; the label's `htmlFor` MUST point at the input's ID.
- **apply-classes**: Component MUST apply the CSS classes `aws-field` and `aws-field--slider` to the wrapper element, and MUST append any `className` prop provided.

