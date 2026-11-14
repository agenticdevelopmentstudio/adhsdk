
- **Empty list to prose** (MUST): `prose([])` returns an empty list; a Card, Closer or Faq answer with no paragraphs gets no children.
- **Null and empty block fields** (MUST pass through): a `Cards` block with an empty `items` list renders a Cards element with no Card children; a `Roadmap` with empty `children` renders an empty Roadmap. Neither is guarded by the source.
- **Shot without a screenshot** (MUST): no `src` leaves `media` out so the placeholder is reachable. An unconditional `<img>` would have made it unreachable, because the kit renders the placeholder only when `media` is absent.
- **Card without an icon** (MUST): `icon` is `undefined`, not an empty path, so no broken `/icons/undefined.svg` is requested.
- **Unknown kind at runtime** (MUST, as documented): the block value is returned as-is, and a plain object is not a valid React child, so React raises a render error when the value is placed in the tree. Only the compile-time check protects against this, and this module raises nothing itself.
- **Nested roadmap depth** (MUST recurse): Roadmap children are rendered recursively with no depth limit; a Roadmap inside a Roadmap renders.
- **Boundary values** (MUST pass through): a `Table` with no rows, or a `Cta` with no buttons, is passed through as given; the source sets no minimum or maximum count anywhere.
- **Concurrent access**: Not applicable: the functions are pure and share no mutable state, so any number of renders can run at once.
- **Error states and offline**: Not applicable: no network, file system or dependency is touched, and the module throws nothing of its own. The image it names is fetched by the browser, not by this module; a missing image file shows as a broken image, which the module does nothing about.
- **Page with no sections** (MUST): `indexRows` returns an empty list.

