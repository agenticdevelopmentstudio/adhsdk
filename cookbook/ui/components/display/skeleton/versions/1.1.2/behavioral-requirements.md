
- **render-as-div**: Component MUST render as an HTML `<div>` element.
- **slot-attribute**: Component MUST render with a `data-slot="skeleton"` attribute.
- **pulsing-animation**: Component MUST apply a continuous pulsing opacity animation to signal a loading state.
- **rounded-corners**: Component MUST apply a medium corner radius.
- **surface-background**: Component MUST apply the secondary surface background color token.
- **class-merge**: Component MUST accept and merge a `className` prop with its built-in classes via a class composition utility (`cn()` in the source, backed by `clsx` and `tailwind-merge`).
- **html-passthrough**: Component MUST accept and forward standard HTML `div` attributes (`id`, `style`, `aria-*`, etc.) to the rendered element.
- **sized-by-props**: Component MAY accept sizing through the `className` prop or an inline `style` prop, allowing consumers to define width and height.
- **reduced-motion-support**: Component MUST allow the pulsing animation to be suppressed under the user's reduced-motion preference; a consumer supplies a variant-scoped override (e.g. `motion-reduce:animate-none`) through `className`, and class-merge (see **class-merge**) preserves it alongside the built-in `animate-pulse` class rather than stripping either.
- **aria-hidden-while-loading**: Component SHOULD be rendered with `aria-hidden="true"`, forwarded via html-passthrough (see **html-passthrough**), while a parent element carries `aria-busy="true"`, so assistive technology reads the container's busy state instead of the placeholder's empty markup.

