
- **Container element**: `<div>`
- **Display**: `flex` (set by the `aws-stack` rule; see #requirements/stack-css-rules)
- **Gap**: Customizable via `gap` prop; when the prop is unset, no inline `gap` is written and the class rule applies (`0.6rem` for both directions)
- **Alignment**: Customizable via `align` prop (maps to `alignItems`); when unset, no inline value is written (HStack's class rule gives `center`)
- **Justification**: Customizable via `justify` prop (maps to `justifyContent`); defaults to `undefined`
- **Direction**: VStack uses column; HStack uses row (set by the `aws-stack--v` or `aws-stack--h` rule; see #requirements/stack-css-rules)
- **Padding**: None by default; customizable via inline `style` prop

