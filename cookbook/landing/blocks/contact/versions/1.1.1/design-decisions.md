
**Decision**: `Contact` composes the `Closer` component rather than duplicating its markup, appending the mailto link and then the optional colophon after the caller's `children`.
**Rationale**: Sharing `Closer`'s markup keeps both components' styling and behavioral semantics in sync. The rendered element carries both `lp-closer` and `lp-contact` classes (see **css-classes**) so the compound selector `.lp-closer.lp-contact` in `css/blocks.css` — which the stylesheet's own comment says must stay compound rather than being split into separate rules — continues to apply.
**Approved**: pending

