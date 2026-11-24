
- **render-children**: Component MUST render its children.
- **render-semantic-element**: Component MUST render as either `<section>` (landmark) or `<div>` (non-landmark) based on the `as` prop.
- **apply-base-class**: Component MUST apply the `lp-screen` class to the root element.
- **center-alignment**: Component MUST apply the `lp-screen--center` class when `align` is set to `'center'`.
- **merge-classname**: Component MUST merge the optional `className` prop with the base classes (`lp-screen`, and `lp-screen--center` when applicable) by concatenation; it does not deduplicate, so a `className` that repeats a base class produces a class list with that token twice.
- **render-glow**: Component MUST render a `<Glow />` component as the first child when `glow` is `true`, and MUST NOT render it when `glow` is `false` or omitted.
- **accept-id**: Component MUST apply the optional `id` prop to the root element when provided.
- **snap-point-viewport-height**: Component MUST establish itself as a full-viewport-height scroll-snap point via the `lp-screen` class, which sets `min-height: 100vh` and `scroll-snap-align: start` (`css/base.css`).

