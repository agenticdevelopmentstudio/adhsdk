
- **dl-root**: Component MUST render as an HTML `<dl>` (definition list) element.
- **label-value-pairs**: Component MUST render each field as a label (`<dt>`) paired with its value (`<dd>`).
- **empty-renders-nothing**: Component MUST return `null` when the `fields` prop is an empty array.
- **array-values-wrap**: Component MUST detect when a field value is an array and render array items wrapped in a `<span>` element with flex layout properties.
- **scalar-values-direct**: Component MUST render non-array field values as-is without additional wrapping.
- **field-order**: Component MUST render rows in the order of the `fields` array, one row per field.
- **style-override-merge**: Component MUST merge the host-supplied `className` prop with its default classes using `cn()` (tailwind-merge); when a host class conflicts with a default class (for example `mb-0` against `mb-6`), the host class wins.
- **attribute-passthrough**: Component MUST accept and apply additional HTML `<dl>` attributes via the `...rest` spread parameter.

