
- **Empty children**: Component MUST render a valid `<footer>` element even when children are empty or null.
- **Null className**: When `className` is `undefined` or not provided, component MUST apply only the `lp-site-foot` class; the `undefined` value is filtered out because it is falsy.
- **Whitespace-only className**: An empty string (`''`) is falsy, so it is filtered out, leaving only `lp-site-foot`. A whitespace-only string (e.g. `' '`) is truthy in JavaScript, so it is NOT filtered — it is joined into the class list as-is. The component only filters falsy values; it does not trim or validate whitespace, and performs no de-duplication.

