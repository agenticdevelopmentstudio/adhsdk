
- **renders-anchor**: Component MUST render as an HTML anchor (`<a>`) element.
- **supports-href**: Component MUST accept an `href` prop of type `string` and pass it to the anchor element's `href` attribute.
- **supports-children**: Component MUST render the `children` prop as the link text content.
- **supports-variant-prop**: Component MUST accept a `variant` prop with values `'primary'` or `'ghost'`.
- **default-variant**: Component MUST default the `variant` prop to `'primary'` when not specified.
- **applies-btn-class**: Component MUST apply the CSS class `lp-btn` to the anchor element.
- **applies-variant-class**: Component MUST apply the CSS class `lp-btn--{variant}` corresponding to the selected variant.
- **no-extra-props**: Component MUST NOT accept or forward any props beyond `href`, `variant`, and `children`.

