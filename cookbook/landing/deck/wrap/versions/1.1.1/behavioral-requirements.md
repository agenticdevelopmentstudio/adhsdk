
- **render-children**: Component MUST render all child elements unchanged.
- **apply-lp-wrap-class**: Component MUST apply the class `lp-wrap` to the rendered div element.
- **class-composition**: Component MUST combine `lp-wrap` with an optional `className` prop, filtering out falsy values and joining the result with a space separator.
- **constrains-width**: Component MUST constrain its content to the smaller of the available width minus a fixed `2.5rem` gutter and the `--lp-measure` custom property (default `70rem`).
- **centers-horizontally**: Component MUST center itself horizontally within its containing block via `margin-inline: auto`.

