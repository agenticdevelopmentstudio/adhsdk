
- **Reduce Motion**: Not applicable — `scrollIntoView` is called with `{ block: 'nearest' }` and no `behavior` option, so the browser positions the item instantly (the default `behavior: 'auto'`) rather than animating the scroll. There is no motion for a reduced-motion preference to suppress.
- **Increase Contrast**: Component inherits contrast from CSS classes (fl-input, fl-item--active, etc.); no specific component-level support.
- **Differentiate Without Color**: Component uses aria-selected and classes (fl-item--active) to indicate state; CSS implementation should not rely on color alone per WCAG 2.1 AA.

