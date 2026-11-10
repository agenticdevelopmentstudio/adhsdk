
- **render-as-div**: Component MUST render a `<div>` element.
- **aria-hidden**: Component MUST set `aria-hidden="true"` on the rendered element.
- **classname-prop**: Component MUST accept an optional `className` prop (`string | undefined`).
- **base-class**: Component MUST always apply the `lp-glow` class to the rendered element.
- **combine-classnames**: The rendered element's class list MUST equal `lp-glow` plus the tokens of `className`, with no empty tokens.

