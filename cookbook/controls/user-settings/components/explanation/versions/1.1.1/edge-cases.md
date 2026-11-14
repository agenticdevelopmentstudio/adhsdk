
- **Null or undefined children**: Component MUST render an empty paragraph element with class `aws-explanation` when children is null or undefined.
- **Empty children**: Component MUST render an empty paragraph element with class `aws-explanation` when children is an empty string or empty array.
- **Undefined className**: Component MUST treat undefined `className` as absent and render only the default class name.
- **Empty string className**: Component MUST filter out empty string `className` values and render only the default class name.
- **Whitespace-only className**: `filter-falsy-classnames` only removes values that are falsy (`""`, `undefined`, `null`, `false`); a whitespace-only string such as `"   "` is truthy, so it is NOT filtered or trimmed. It passes through untrimmed, and the resulting class attribute contains the default class followed by that whitespace (see explanation-011).
- **Multiple classes in className**: Component MUST preserve spacing between multiple classes provided in the `className` prop (e.g., `"class1 class2"` renders as `"aws-explanation class1 class2"`); internal whitespace within the provided string is not modified (see explanation-012).

