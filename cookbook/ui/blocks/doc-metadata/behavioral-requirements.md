
- **dl-root**: Component MUST render as an HTML `<dl>` (definition list) element.
- **label-value-pairs**: Component MUST render each field as a label (`<dt>`) paired with its value (`<dd>`).
- **empty-renders-nothing**: Component MUST return `null` when the `fields` prop is an empty array.
- **array-values-wrap**: Component MUST detect when a field value is an array and render array items wrapped in a `<span>` element with flex layout properties.
- **scalar-values-direct**: Component MUST render non-array field values as-is without additional wrapping.
- **style-override-merge**: Component MUST merge a host-supplied style override with its defaults.
- **attribute-passthrough**: Component MUST accept and apply additional HTML `<dl>` attributes via the `...rest` spread parameter.

