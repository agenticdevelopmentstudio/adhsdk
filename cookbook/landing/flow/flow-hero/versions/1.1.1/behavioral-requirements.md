
- **render-headline**: Component MUST render the `headline` prop as an `<h1>` element.
- **render-subheading**: Component MUST render the `sub` prop as a `<p>` element with class `lp-hero-sub`.
- **render-mark**: Component MUST render the `mark` prop (a ReactNode) without modification, allowing the host to supply its own `<Image>` or `<img>` element.
- **render-actions-when-children-provided**: Component MUST render `children` prop wrapped in a `<div>` with class `lp-hero-actions` when `children` is not `undefined`.
- **not-render-actions-when-children-undefined**: Component MUST NOT render the actions container when `children` is `undefined`.
- **render-metadata-when-provided**: Component MUST render the `meta` prop as a `<p>` element with class `lp-hero-meta` when `meta` is not `undefined`.
- **not-render-metadata-when-undefined**: Component MUST NOT render the metadata paragraph when `meta` is `undefined`.
- **render-shot-when-provided**: Component MUST render the `shot` prop within a `<div>` with class `lp-hero-shot` wrapped in a `Wrap` component when `shot` is not `undefined`.
- **not-render-shot-when-undefined**: Component MUST NOT render the shot container when `shot` is `undefined`.
- **support-optional-id**: Component MUST accept and render an optional `id` prop on the root `<div>`.
- **render-root-element**: Component MUST render a root `<div>` element with class `lp-hero-flow`.
- **render-order**: Within the root `<div>`, a single `Wrap` MUST contain, in order, `mark`, the headline `<h1>`, `sub`, the actions container (when `children` is provided), and the metadata paragraph (when `meta` is provided); the `shot` container (when provided) MUST render after that `Wrap`, inside its own separate `Wrap`.
- **single-per-page**: A page SHOULD contain at most one `FlowHero`, since the component always renders `headline` as an `<h1>`; a second instance produces two top-level headings and breaks the page's heading outline.

