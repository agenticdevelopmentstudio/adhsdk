
- **render-container**: Component MUST render a `div` element with class `lp-head`.
- **conditional-eyebrow**: Component MUST render a `span` element with class `lp-eyebrow` and the eyebrow content only when the `eyebrow` prop is defined (not `undefined`).
- **conditional-title**: Component MUST render an `h2` element containing the title content only when the `title` prop is defined (not `undefined`).
- **render-children**: Component MUST render the `children` prop content within the container when `children` is provided.
- **omit-absent-props**: A caller with no title or no eyebrow to show MUST omit the prop (pass `undefined`), never `null` or `""`. Those values still render an empty `h2` or `span`, and a blank `h2` reaches the screen-reader heading outline. See #design-decisions.
- **preserve-order**: Component MUST render child elements in the order: eyebrow (if present), title (if present), children (if present).

