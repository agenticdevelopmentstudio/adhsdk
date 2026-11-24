
- **render-children**: Component MUST render all child elements unchanged.
- **apply-lp-wrap-class**: Component MUST apply the class `lp-wrap` to the rendered div element.
- **class-composition**: Component MUST combine `lp-wrap` with an optional `className` prop, filtering out falsy values and joining the result with a space separator.
- **constrains-width**: Component MUST constrain its content to the width derived in `#appearance`: the smaller of the available width minus the fixed gutter and the `--lp-measure` custom property.
- **centers-horizontally**: Component MUST center itself horizontally within its containing block via `margin-inline: auto`.

