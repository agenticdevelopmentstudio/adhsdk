
- **list-structure**: Component MUST render the `items` array as a semantic unordered list: a `<ul>` container with each item wrapped in a distinct `<li>` element.
- **node-items**: Component MUST accept `items` as a `ReactNode[]` prop, supporting text, React elements, fragments, and null values; every entry maps to an `<li>` in order, including `null`/`undefined` entries, which render as an empty `<li>` rather than being skipped.
- **container-class**: Component MUST apply the className `lp-trust` to the rendered `<ul>` element.

