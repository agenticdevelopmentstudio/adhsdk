
- **render-section**: Band MUST render as an HTML `<section>` element.
- **accept-id**: Band MUST accept an optional `id` prop that is forwarded to the rendered section; when omitted, the section renders without an `id` attribute.
- **support-three-tones**: Band MUST support three tone values: `'dark'`, `'soft'`, and `'paper'`.
- **default-dark-tone**: Band MUST default to tone `'dark'` if the `tone` prop is not specified.
- **seam-prop**: Band MUST accept an optional `seam` prop, defaulting to `true`, that controls whether the diagonal cut is rendered along the top edge.
- **apply-seam-when-true**: When `seam` is `true`, Band MUST render the diagonal cut along the top edge using CSS `clip-path` and a negative top margin, both derived from the `--lp-seam` CSS variable (default `4.5vw`): `clip-path: polygon(0 var(--lp-seam), 100% 0, 100% 100%, 0 100%)` and `margin-top: calc(var(--lp-seam) * -1)`.
- **omit-seam-when-false**: When `seam` is `false`, Band MUST NOT apply the diagonal cut to the top edge; the `lp-band--seam` class is withheld.
- **paper-cuts-foot**: When `tone` is `'paper'`, Band MUST render a diagonal cut along the bottom edge independent of the `seam` prop, using `clip-path: polygon(0 0, 100% 0, 100% 100%, 0 calc(100% - var(--lp-seam)))` and `margin-bottom: calc(var(--lp-seam) * -1)`. When `seam` is also `true`, the top edge is cut in addition, not instead.
- **stacking-order**: Band MUST establish a stacking context (`position: relative`, `z-index: 1`) so a later sibling's top seam paints over it through document order alone. The `paper` tone MUST raise this to `z-index: 2` so its own bottom cut paints above the band that follows it in the DOM.
- **wrap-children**: Band MUST wrap its children with the `Wrap` component.
- **accept-classname**: Band MUST accept an optional `className` prop.
- **apply-tone-class**: Band MUST apply a CSS class matching the pattern `lp-band--{tone}` corresponding to the tone prop.
- **band-base-class**: Band MUST apply the CSS class `lp-band` to the section.
- **seam-class-when-true**: When `seam` is `true`, Band MUST apply the CSS class `lp-band--seam` to the section.

