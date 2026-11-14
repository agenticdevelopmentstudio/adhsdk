
- **renders-children**: Component MUST render all child elements passed to it.
- **root-class**: Component MUST apply the `lp-split` class to its root element.
- **merges-classname**: Component MUST merge the `lp-split` class with any additional `className` prop provided, applying both to the root element with no empty or duplicate class tokens.
- **responsive-breakpoint**: Component MUST lay out children as a single-column CSS Grid below the breakpoint and switch to a two-column CSS Grid at and above it, using the layout, breakpoint and gap values stated once in `#appearance/layout`, `#appearance/breakpoint` and `#appearance/gap`.
- **preserves-reading-order**: Component MUST NOT reorder its children visually relative to DOM order (no CSS `order` or `row-reverse`), and the root element MUST carry no ARIA role, per WCAG 1.3.2 (Meaningful Sequence).

