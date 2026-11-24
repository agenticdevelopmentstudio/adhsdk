
- **Null children**: When `children` is `null`, the component MUST render its root element with no child content.
- **Empty children array**: When `children` is an empty array, the component MUST render its root element with no child elements.
- **Multiple children**: The component MUST render all children in the order provided.
- **clip prop is undefined**: When `clip` is not provided, the component MUST default to `true` and MUST NOT apply the `vp-shell--open` class.
- **className with whitespace**: A whitespace-only `className` (e.g. `"  "`) MUST NOT be trimmed or rejected — `Array.prototype.filter(Boolean)` only removes falsy values, so it is joined into the class list as-is, alongside `viewport-shell`.
- **Rapid clip prop changes**: When `clip` changes between `true` and `false` across renders, the component MUST update its class list and computed overflow synchronously, and MUST preserve `children` without remounting them.

