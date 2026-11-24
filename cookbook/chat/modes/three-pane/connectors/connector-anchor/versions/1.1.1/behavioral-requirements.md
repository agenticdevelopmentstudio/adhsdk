
- **render-as-span**: Component MUST render as an HTML `<span>` element.
- **accept-id**: Component MUST accept a required string `id` prop that uniquely identifies the anchor point.
- **register-with-registry**: Component MUST register its DOM reference with the connector registry using the provided `id` when the component mounts.
- **return-null-if-no-registry**: Component MUST render nothing (return null) when the connector registry is not available.
- **set-data-connector-anchor**: Component MUST set a `data-connector-anchor` HTML attribute with the value of the `id` prop.
- **be-aria-hidden**: Component MUST set `aria-hidden="true"` on the rendered element to hide it from assistive technologies.
- **accept-classname**: Component SHOULD accept an optional `className` prop to allow consumers to apply additional CSS classes.
- **support-class-composition**: Component SHOULD concatenate the base class `pc-connector-anchor` with any provided `className` when both are present.
- **unregister-on-unmount**: Component MUST unregister from the connector registry when the component unmounts or when dependencies change. The registry's `register` call always returns a cleanup function, so unregistration is unconditional.
- **re-register-on-id-change**: Component MUST re-register with the connector registry when the `id` prop changes, unregistering the previous `id` before registering the new one.

