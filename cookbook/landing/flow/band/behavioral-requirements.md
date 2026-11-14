
- **render-section**: Band MUST render as an HTML `<section>` element.
- **accept-id**: Band MUST accept an optional `id` prop that is forwarded to the rendered section; when omitted, the section renders without an `id` attribute.
- **support-three-tones**: Band MUST support three tone values: `'dark'`, `'soft'`, and `'paper'`.
- **default-dark-tone**: Band MUST default to tone `'dark'` if the `tone` prop is not specified.
- **seam-prop**: Band MUST accept an optional `seam` prop, defaulting to `true`, that controls whether the diagonal cut is rendered along the top edge.
- **apply-seam-when-true**: When `seam` is `true`, Band MUST render the diagonal cut along the top edge using CSS `clip-path` and a negative top margin, both derived from the `--lp-seam` CSS variable (default `4.5vw`): `clip-path: polygon(0 var(--lp-seam), 100% 0, 100% 100%, 0 100%)` and `margin-top: calc(var(--lp-seam) * -1)`.
- **omit-seam-when-false**: When `seam` is `false`, Band MUST NOT apply the diagonal cut to the top edge; the `lp-band--seam` class is withheld.
- **paper-cuts-foot**: When `tone` is `'paper'`, Band MUST render a diagonal cut along the bottom edge independent of the `seam` prop, using `clip-path: polygon(0 0, 100% 0, 100% 100%, 0 calc(100% - var(--lp-seam)))` and `margin-bottom: calc(var(--lp-seam) * -1)`. When `seam` is also `true`, the top edge is cut in addition, not instead: the two cuts MUST be one combined declaration, because two separate `clip-path` declarations would override each other, namely `clip-path: polygon(0 var(--lp-seam), 100% 0, 100% 100%, 0 calc(100% - var(--lp-seam)))` (see **paper-and-seam-combined**).
- **paper-and-seam-combined**: When `tone` is `'paper'` and `seam` is `true`, Band MUST apply a single `clip-path: polygon(0 var(--lp-seam), 100% 0, 100% 100%, 0 calc(100% - var(--lp-seam)))` together with `margin-top: calc(var(--lp-seam) * -1)`, matching the `.lp-band--paper.lp-band--seam` rule, which outweighs both the bare paper rule and the bare seam rule by specificity.
- **stacking-order**: Band MUST establish a stacking context (`position: relative`, `z-index: 1`) so a later sibling's top seam paints over it through document order alone. The `paper` tone MUST raise this to `z-index: 2` so its own bottom cut paints above the band that follows it in the DOM.
- **dock-clear-last-band**: The last band in a flow, selected by `.lp-band:last-child` (and `.lp-band--paper:last-child` for the paper tone, which keeps its foot-cut allowance), MUST add `--lp-dock-clear` (default `0px`) to its bottom padding. No other band adds it, so only the tail of the document reserves room for a host's fixed dock.
- **tone-tokens**: Each tone MUST read its colors from tokens, with the fallbacks shown under **Appearance**: `dark` from `--lp-ground` and `--lp-ink`, `soft` from `--lp-tone-soft` and `--lp-ink`, and `paper` from `--lp-tone-paper` and `--lp-paper-ink`, with `--lp-ink-dim` overridden from `--lp-paper-dim`.
- **wrap-children**: Band MUST wrap its children with the `Wrap` component ([adhsdk.ingredient.landing.deck.wrap](cookbook:51d3b1ba-ced7-4c08-8a63-c83094d91299)).
- **accept-classname**: Band MUST accept an optional `className` prop.
- **apply-tone-class**: Band MUST apply a CSS class matching the pattern `lp-band--{tone}` corresponding to the tone prop.
- **band-base-class**: Band MUST apply the CSS class `lp-band` to the section.
- **seam-class-when-true**: When `seam` is `true`, Band MUST apply the CSS class `lp-band--seam` to the section.

