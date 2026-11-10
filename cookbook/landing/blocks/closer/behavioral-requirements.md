
- **render-title**: The component MUST render the `title` prop as the first child within an h2 element.
- **render-children**: The component MUST render the `children` prop after the title element.
- **apply-lp-closer-class**: The component MUST apply the CSS class `lp-closer` to its root div element.
- **merge-optional-classname**: When a `className` prop is provided, the component MUST merge it with the base `lp-closer` class (base first) and MUST NOT emit leading, trailing, or doubled whitespace in the resulting className when `className` is empty or absent.

