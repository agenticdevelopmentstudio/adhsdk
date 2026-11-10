
- **render-as-div**: Component MUST render as a single `<div>` element.
- **base-class**: Component MUST apply the `lp-cards` class to the rendered element.
- **pass-children**: Component MUST render all provided children within the container.
- **pair-layout**: When `pair` prop is `true`, component MUST apply the `lp-cards--pair` class to enable two-column layout.
- **trio-layout**: When `trio` prop is `true`, component MUST apply the `lp-cards--trio` class to enable three-column layout.
- **reject-conflicting-props**: Component MUST throw an error with message `"Cards: \`pair\` and \`trio\` set the same column track — pass at most one"` when both `pair` and `trio` are `true`.
- **classname-prop**: Component MUST accept an optional `className` prop and include it in the rendered element's class list.
- **combine-classes**: Component MUST combine all applicable classes with single space separators and filter out empty strings.

