
- **headline**: Component MUST render the `headline` prop as an `<h1>` element.
- **subheading**: Component MUST render the `sub` prop as a `<p>` element with class `lp-hero-sub`.
- **mark**: Component MUST render the `mark` prop (a ReactNode) without modification, allowing the host to supply its own `<Image>` or `<img>` element. When `mark` is `undefined`, nothing renders in its place: no wrapper element and no placeholder.
- **actions-container**: Component MUST render `children` prop wrapped in a `<div>` with class `lp-hero-actions` when `children` is not `undefined`. This includes `null` and `""`, which render an empty container. Component MUST NOT render the actions container when `children` is `undefined`.
- **actions-bare-btn**: Hosts SHOULD pass `children` as bare `Btn` elements in their own order, never wrapped in a `Cta`: `.lp-hero-actions` is already the centered, wrapping flex row, so a `Cta` inside it nests a second row whose own gap wins and leaves the hero's spacing inert. This is a rule for the host; the component does not enforce it.
- **meta-paragraph**: Component MUST render the `meta` prop as a `<p>` element with class `lp-hero-meta` when `meta` is not `undefined`. This includes `null` and `""`, which render an empty paragraph. Component MUST NOT render the metadata paragraph when `meta` is `undefined`.
- **shot-container**: Component MUST render the `shot` prop within a `<div>` with class `lp-hero-shot` wrapped in the `Wrap` component ([adhsdk.ingredient.landing.deck.wrap](cookbook:51d3b1ba-ced7-4c08-8a63-c83094d91299)) when `shot` is not `undefined`. This includes `null`, which renders an empty container. Component MUST NOT render the shot container when `shot` is `undefined`.
- **id**: Component MUST accept and render an optional `id` prop on the root `<div>`.
- **root-element**: Component MUST render a root `<div>` element with class `lp-hero-flow`.
- **child-order**: Within the root `<div>`, a single `Wrap` MUST contain, in order, `mark`, the headline `<h1>`, `sub`, the actions container (when `children` is provided), and the metadata paragraph (when `meta` is provided); the `shot` container (when provided) MUST render after that `Wrap`, inside its own separate `Wrap`.
- **single-per-page**: A page SHOULD contain at most one `FlowHero`, since the component always renders `headline` as an `<h1>`; a second instance produces two top-level headings and breaks the page's heading outline.

