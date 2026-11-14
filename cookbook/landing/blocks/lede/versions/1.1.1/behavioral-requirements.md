
- **render-as-paragraph**: Component MUST render as an HTML `<p>` element.
- **render-children**: Component MUST render the provided `children` prop as the paragraph content.
- **apply-lede-class**: Component MUST apply the `lp-lede` CSS class to the rendered element.
- **accept-additional-class**: Component MUST accept an optional `className` prop that is concatenated with `lp-lede`.
- **clean-class-attribute**: The rendered `class` attribute MUST contain no `undefined` or empty-string tokens: falsy `className` values (`undefined`, `null`, `""`) are filtered out before the attribute is joined. A whitespace-only value is truthy and is therefore not filtered (see Edge Cases).
- **constrain-paragraph-measure**: Component MUST constrain the paragraph to a maximum measure of 72 characters (`max-width: 72ch`, defined by the `lp-lede` CSS rule) for readability.

