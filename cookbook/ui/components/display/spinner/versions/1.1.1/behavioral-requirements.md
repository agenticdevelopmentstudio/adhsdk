
- **render-indicator**: Component MUST render a circular indeterminate loading indicator (the React/Web reference implementation uses Lucide's `Loader2` icon — see Platform Notes).
- **spin-animation**: Component MUST apply a continuous spinning animation to the icon; the component does not itself query `prefers-reduced-motion` (see Accessibility Options — Reduce Motion, and Edge Cases).
- **accept-classname**: Component MUST accept and apply a custom `className` prop that overrides or extends the default styling.
- **accept-props**: Component MUST accept and forward all valid React props accepted by the underlying Lucide `Loader2` component.
- **aria-label**: Component MUST set `aria-label="Loading"` to communicate the spinner's purpose to assistive technology. The label is a fixed English string, not a configurable prop (see Localization, Design Decisions).
- **status-role**: Component MUST set `role="status"` to indicate this is a live status region that announces loading state.
- **default-size**: Component MUST default to 1rem (16px) size unless `className` supplies a size-overriding utility.
- **default-color**: Component MUST default to the muted-foreground text color token unless `className` supplies a color-overriding utility (the React/Web reference implementation uses `text-apt-text-muted` — see Platform Notes).

