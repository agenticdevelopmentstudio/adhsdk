
- **message-text**: Component MUST render the message text provided via the `message` prop, or the default message `'Development Preview — Coming Soon!'` when `message` is `undefined` (including when the prop is omitted).
- **position-class**: Component MUST apply a CSS class reflecting the `position` prop value (`'fixed'` or `'static'`) to the container element.
- **default-position**: Component MUST default to `position: 'fixed'` when no `position` prop is provided.
- **base-class**: Component MUST always apply the base class `awt-dev-banner` to the container element, in addition to the position class and any `className` prop.
- **custom-class**: Component MUST accept and apply a `className` prop, which is appended to the component's CSS classes.
- **hidden-from-at**: Component MUST set `aria-hidden="true"` on the root element.

