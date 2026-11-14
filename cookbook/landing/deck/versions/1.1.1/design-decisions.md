
**Decision**: Deck renders as a `<div>`, not a `<main>` element.
**Rationale**: Deck was initially rendered as a `<main>` element, but every consumer renders Deck as a page inside a host shell that already draws the page's `<main>` landmark, so the two nested landmarks were invalid HTML and announced two "main" regions to a screen reader with no way to tell which held the actual page content. Deck is now a `<div>` to avoid the duplication; a host that does not provide its own main landmark can apply one from outside Deck, which is the only context that knows whether one already exists.
**Approved**: pending

**Decision**: Deck sets `tabIndex={-1}` on its root element (focusable-not-tabbable).
**Rationale**: A click inside Deck focuses it, or a descendant, and keeps it out of the keyboard tab order; from that point, arrow keys and Page Down scroll the document rather than being trapped inside Deck, so the document remains the natural scroll container. See deck-011.
**Approved**: pending

