
- **semantic-role**: Where the platform has a separator role or element, the component MUST expose separator semantics to assistive technology (on web, `role="separator"`). On a platform with no such role, see its Platform Note for what is exposed instead.
- **horizontal-orientation**: The component MUST render as a horizontal dividing line by default when orientation is not specified, or when it is set to `"horizontal"`.
- **vertical-orientation**: The component MUST render as a vertical dividing line when orientation is set to `"vertical"`.
- **orientation-sync**: For a supported orientation value, the component MUST communicate its current orientation to assistive technology (on web, via `aria-orientation`) so it always matches the orientation the component is rendering.
- **orientation-values**: Callers MUST pass only `"horizontal"` or `"vertical"` as the orientation (on web, enforced only by the TypeScript type). The component does not validate or fall back; the result of any other value is described in **Edge Cases** and is not part of the conformance contract.
- **custom-style-override**: The component MUST accept a mechanism for platform-appropriate style overrides (on web, a `className` prop) and merge it with the component's base styling rather than replacing it.
- **forwarded-props**: The component MUST accept and forward standard platform element properties/attributes to the underlying rendered element (on web, via `...props` spread onto the root element).

