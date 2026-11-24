
- **render-headline**: Component MUST render the `headline` prop as the primary claim statement within an `<h1>` element.
- **render-tagline**: Component MUST render the `tagline` prop as supporting text within a `<p>` element with class `lp-tag`.
- **accept-mark**: Component MUST accept an optional `mark` prop as a `ReactNode`, allowing the host to supply its own `<Image>` or `<img>` element before the headline.
- **accept-children**: Component MUST accept optional `children` as a `ReactNode` to compose call-to-action, trust, and status pill components below the tagline.
- **support-glow**: Component MUST support a `glow` prop (default `true`) that controls the glow effect on the Screen container.
- **support-id**: Component MUST accept an optional `id` prop to set the HTML `id` attribute for semantic identification.
- **center-content**: Component MUST center all content horizontally and render as a centered Screen (align="center").
- **render-as-div**: Component MUST render the Screen container with `as="div"` to output a non-semantic container, deferring any landmark role to the host — see **root-is-non-semantic** under Design Decisions.
- **hero-styling-class**: Component MUST render with the `lp-hero` class alongside Screen's own `lp-screen` class, so the hero-specific rules in `css/blocks.css` (padding-inline, headline/tagline type) apply.

