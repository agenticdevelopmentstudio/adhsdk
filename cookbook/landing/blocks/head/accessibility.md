
- The title is rendered as an `h2` element, providing semantic structure for document outline and screen reader navigation. On native platforms, the equivalent element MUST carry the platform's heading trait/semantics (see Platform Notes) since there is no HTML tag to carry it implicitly.
- The eyebrow is rendered as a `span` without semantic role, as a sibling of the `h2` rather than nested inside it. When the eyebrow content is important to a reader who lands directly on the section (for example, it is the label a drawer link used to get here), callers SHOULD link the two elements with `aria-describedby` — give the eyebrow `span` an `id` and reference it from the `h2` — rather than relying on visual adjacency alone.
- Child content inherits accessibility characteristics from its own implementation; the component does not alter or wrap accessibility properties of children.

