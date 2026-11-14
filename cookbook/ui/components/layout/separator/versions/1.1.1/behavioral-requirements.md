
- **semantic-role**: The component MUST expose separator semantics to assistive technology (on web, `role="separator"`).
- **horizontal-orientation**: The component MUST render as a horizontal dividing line by default when orientation is not specified, or when it is set to `"horizontal"`.
- **vertical-orientation**: The component MUST render as a vertical dividing line when orientation is set to `"vertical"`.
- **orientation-sync**: The component MUST communicate its current orientation to assistive technology (on web, via `aria-orientation`) so it always matches the orientation the component is rendering.
- **custom-style-override**: The component MUST accept a mechanism for platform-appropriate style overrides (on web, a `className` prop) and merge it with the component's base styling rather than replacing it.
- **forwarded-props**: The component MUST accept and forward standard platform element properties/attributes to the underlying rendered element (on web, via `...props` spread onto the root element).

