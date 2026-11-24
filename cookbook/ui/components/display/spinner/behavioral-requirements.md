
- **render-indicator**: Component MUST render a circular indeterminate loading indicator (see Platform Notes for the icon each platform uses).
- **spin-animation**: Component MUST apply a continuous spinning animation to the icon; the component does not itself query `prefers-reduced-motion` (see Accessibility Options — Reduce Motion, and Edge Cases).
- **accept-classname**: Component MUST allow callers to override or extend the default styling (size, color).
- **accept-props**: Component MUST forward any additional attributes the caller supplies to the rendered indicator element (see Platform Notes).
- **aria-label**: Component MUST expose the accessible name "Loading" to communicate the spinner's purpose to assistive technology (on web, `aria-label="Loading"`). The label is a fixed English string, not a configurable prop (see Localization, Design Decisions).
- **status-role**: Component MUST expose a status/progress semantic role to indicate this is a live status region that announces loading state (on web, `role="status"`).
- **default-size**: Component MUST default to 1rem (16px) size unless the caller overrides the size.
- **default-color**: Component MUST default to the muted-foreground text color token unless the caller overrides the color (see Appearance and Platform Notes for the token).

