
- **list-element**: Component MUST render `<ul>` when `ordered` is false (default) or omitted, and MUST render `<ol>` when `ordered` is true.
- **list-items**: Component MUST render one `<li>` element for each entry in the `entries` array.
- **content-span**: Each list item content MUST be wrapped in a single `<span>` element to enforce grid layout structure (two-column: marker and content).
- **term-bold**: When an entry has a `term` property, Component MUST render it as `<b>{term}</b>`.
- **detail-text**: Component MUST render the `detail` property of each entry as ReactNode content.
- **term-detail-spacing**: When both `term` and `detail` are present, Component MUST render a space character between them.
- **term-omission**: When an entry has no `term` property, Component MUST NOT render a `<b>` element or space separator.
- **base-class**: Component MUST apply the CSS class `lp-points` to the root list element.
- **ordered-class**: Component MUST apply the CSS class `lp-points--ordered` to the root element when `ordered` is true.
- **ordered-class-exclusion**: Component MUST NOT apply `lp-points--ordered` class when `ordered` is false.
- **empty-entries**: Component MUST accept an empty `entries` array and render an empty list element with no items.

