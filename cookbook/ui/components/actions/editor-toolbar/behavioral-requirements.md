
- **toolbar-role**: Component MUST render a `div` element with `role="toolbar"` to identify itself to assistive technology as a toolbar region.
- **aria-label-prop**: Component MUST accept an `ariaLabel` prop that is passed directly to the `aria-label` attribute of the rendered element.
- **aria-label-default**: Component MUST use the default aria-label value `"Editor toolbar"` when the `ariaLabel` prop is not provided.
- **render-children**: Component MUST render the `children` prop without modification or filtering.
- **class-name-merge**: Component MUST accept a `className` prop and merge it with the component's default layout classes so that a caller's classes can override the defaults.
- **flex-layout**: Component MUST render with `display: flex` to establish flexbox layout for its children.
- **vertical-center**: Component MUST use flexbox alignment to center children vertically (`align-items: center`).
- **child-gap**: Component MUST apply a consistent horizontal gap of `0.375rem` (6 pixels) between direct child elements.

