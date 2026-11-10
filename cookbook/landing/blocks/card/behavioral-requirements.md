
- **render-title**: Component MUST render the `title` prop as an `<h3>` heading.
- **render-children**: Component MUST render the `children` prop as the card's content, immediately after the title.
- **support-optional-kicker**: Component MUST accept an optional `kicker` prop and render it only when defined (not `undefined`).
- **render-kicker-before-title**: When `kicker` is provided, it MUST render before the `<h3>` title in the DOM.
- **use-card-class**: The root element MUST have the class name `lp-card`.
- **use-kicker-class**: When rendered, the kicker element MUST have the class name `lp-card__kicker`.
- **accept-react-nodes**: The `kicker`, `title`, and `children` props MUST accept any React `ReactNode` (elements, strings, numbers, fragments, etc.), not only strings.
- **tolerate-nullish-title**: Component MUST NOT crash when `title` is `null` or `undefined`; it renders an empty `<h3>` in that case.
- **tolerate-nullish-children**: Component MUST NOT crash when `children` is `null` or `undefined`; it renders the card with an empty content area in that case.

