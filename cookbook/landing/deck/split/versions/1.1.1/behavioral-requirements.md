
- **renders-children**: Component MUST render all child elements passed to it.
- **root-class**: Component MUST apply the `lp-split` class to its root element.
- **merges-classname**: Component MUST merge the `lp-split` class with any additional `className` prop provided, applying both to the root element with no empty or duplicate class tokens.
- **responsive-breakpoint**: Component MUST lay out children as a single-column CSS Grid (`2rem` gap) below a `62rem` (992px) viewport width, and switch to a two-column CSS Grid (`grid-template-columns: minmax(0, 5fr) minmax(0, 6fr)`, `3rem` gap) at and above that breakpoint, as defined in `packages/web/packages/landing/src/css/base.css`.
- **preserves-reading-order**: Component MUST NOT reorder its children visually relative to DOM order (no CSS `order` or `row-reverse`), and the root element MUST carry no ARIA role, per WCAG 1.3.2 (Meaningful Sequence).

