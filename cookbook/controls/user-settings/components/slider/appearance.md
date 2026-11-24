
The component's visual presentation is controlled entirely by CSS. The component itself establishes the following class structure:

- **Wrapper**: `aws-field aws-field--slider` (plus optional custom `className`)
- **Label**: `aws-field__label` — applied to the `<label>` element when present
- **Slider container**: `aws-slider`
- **Input**: `aws-slider__input` — applied to the range input
- **Caption**: `aws-slider__caption` — applied to the caption span
- **Hint**: `aws-field__hint` — applied to the `<p>` element when present

DOM order: the `<label>` (if present) renders first, followed by the `.aws-slider` container (the range input and, if present, the caption `<span>` as siblings inside it), followed by the hint `<p>` (if present) as the last child of the wrapper.

The actual appearance (colors, spacing, dimensions, border radius, shadows) is defined by CSS rules for these classes and is outside the scope of this component's implementation.

