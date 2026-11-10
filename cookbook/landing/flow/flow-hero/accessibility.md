
- **Semantic structure**: Uses `<h1>` for headline (main page heading) and `<p>` for subheading and metadata. The root is a `<div>`, not a `<section>`, to avoid creating an unlabeled landmark region in screen reader outlines (see **Design Decisions**).
- **Headline labeling**: Host-supplied `headline` content is expected to describe the product's claim or purpose meaningfully, since it renders as the page's `<h1>` (see **single-per-page**).
- **Subheading relationship**: The `<p>` with class `lp-hero-sub` provides supplementary information; position immediately after the headline creates a logical reading order (see **render-order**).
- **Action buttons**: `children` are expected to be bare, properly labeled `Btn` elements (see [adhsdk.ingredient.landing.blocks.btn](cookbook:1675b18e-34d5-4d8e-987f-92697539a5e6)); the parent `<div class="lp-hero-actions">` is a non-semantic container for layout only.
- **Image alt text**: The `mark` prop is supplied as a ReactNode by the host; the host is responsible for providing appropriate alt text if the mark contains an image.
- **Metadata styling**: Text is uppercased by CSS `text-transform` on the `<p>` the component renders. Hosts cannot override that transform from outside; a host needing non-uppercase content (e.g. a product name) wraps that content in its own child element with an inline style resetting `text-transform`, since the property is inherited and a descendant element can override it.

