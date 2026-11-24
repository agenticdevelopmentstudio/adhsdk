
- **Decision**: Render a `<div>` (not a `<section>`) as `FlowHero`'s root element.
  **Rationale**: A `<section>` here would create an unlabeled landmark region at the top of every screen reader's outline; the bands below the hero are the page's semantic landmarks. [adhsdk.ingredient.landing.hero](cookbook:fae23662-e69b-4472-9c7d-049feadf1211) makes the same call for the deck's `Hero` component for the same reason.
  **Approved**: pending

- **Decision**: Accept `mark` as a `ReactNode`, not an `<img>`/`<Image>` element.
  **Rationale**: This lets the host supply its own image element with full control over alt text, sizing, and optimization, decoupling the component from image-rendering logic.
  **Approved**: pending

- **Decision**: Gate the `children`, `meta`, and `shot` containers on `!== undefined`.
  **Rationale**: Only `undefined` suppresses a section's container. Passing `null` or an empty string still renders the (empty) container, since neither is excluded by `!== undefined`. Hosts must omit the prop, or pass `undefined` explicitly, to hide a section. This is the one canonical statement of the gating; Edge Cases and Platform Notes point here.
  **Approved**: pending

- **Decision**: Uppercase the `meta` text via CSS `text-transform`, not JavaScript.
  **Rationale**: The source text stays intact in the DOM, so copy and paste, screen readers and locale-aware casing all see what the host wrote, and the transform follows the document's language. Hosts cannot override that transform on the `<p>` element itself, since the component renders it, not the host. A host needing non-uppercase content (e.g. a product name, which Apple's guidelines forbid setting in all caps) wraps that content in its own child element with an inline style resetting `text-transform`, because the property is inherited and a descendant element can override it. This is the one canonical statement of the opt-out; Accessibility, Edge Cases and Localization point here.
  **Approved**: pending

