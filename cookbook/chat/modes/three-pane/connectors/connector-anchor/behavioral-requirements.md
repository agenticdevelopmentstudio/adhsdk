
- **render-as-span**: Component MUST render as an HTML `<span>` element.
- **accept-id**: Component MUST accept a required string `id` prop that identifies the anchor point. Ids are expected to be unique among mounted anchors; if two mounted anchors share an id, the registry keeps the most recently registered element for it (last-wins, per the registry contract). An empty string is an ordinary id and is registered like any other.
- **register-with-registry**: Component MUST register its DOM reference with the connector registry using the provided `id` when the component mounts.
- **return-null-if-no-registry**: Component MUST render nothing (return null) when the connector registry is not available.
- **set-data-connector-anchor**: Component MUST set a `data-connector-anchor` HTML attribute with the value of the `id` prop.
- **be-aria-hidden**: Component MUST set `aria-hidden="true"` on the rendered element to hide it from assistive technologies.
- **accept-classname**: Component SHOULD accept an optional `className` prop to allow consumers to apply additional CSS classes.
- **support-class-composition**: Component SHOULD concatenate the base class `pc-connector-anchor` with any provided `className` when both are present. A `className` that is `undefined` or an empty string adds nothing; any other value, including whitespace, is appended after a single space as given.
- **unregister-on-unmount**: Component MUST unregister from the connector registry when the component unmounts, when `id` changes, or when the registry instance changes. The registry's `register` call always returns a cleanup function, so unregistration is unconditional.
- **re-register-on-registry-change**: Component MUST unregister from the previous registry and register with the new one when the registry instance it resolves changes.
- **re-register-on-id-change**: Component MUST re-register with the connector registry when the `id` prop changes, unregistering the previous `id` before registering the new one.

