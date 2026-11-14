
- **Empty fields array**: Component returns `null`; no DOM render occurs.
- **Null or undefined values**: The component passes `field.value` straight through with no special-casing (see **scalar-values-direct**); a `null` or `undefined` value therefore renders as an empty `<dd>` — React's normal behavior for a nullish child, not an unhandled error path.
- **ReactNode values in arrays**: Array items are rendered as React fragments; any valid ReactNode (strings, components, elements) render correctly.
- **Special characters and markup in values**: Scalar values render as text; markup is escaped. Array item values depend on ReactNode content; if a value is a React element, it renders as intended by the host.
- **Very long labels or values**: The component applies no truncation or text overflow handling; content wraps or overflows according to the browser's default behavior and the parent container's width.
- **Dynamic field changes**: The component is stateless; re-rendering with new fields updates the DOM.

