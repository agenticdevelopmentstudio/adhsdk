
**Decision**: Use a generic `div` rather than a `<nav>` or `<section>` element for the container.
**Rationale**: Preserves flexibility for the parent component (Hero, Closer) to determine the semantic context in which the CTA group appears, rather than imposing landmark semantics that may not fit every placement.
**Approved**: pending

**Decision**: The container does not accept a `className` prop and always renders exactly `className="lp-cta"`; consumers cannot merge in their own classes.
**Rationale**: `Cta` (`packages/web/packages/landing/src/blocks/Cta.tsx`) only accepts a `children` prop; there is no `className` merging in the source, matching the component's minimal, styling-owned-by-the-block design.
**Approved**: pending

**Decision**: Grouping semantics for the CTA row (for example `role="group"` with `aria-label`) are left to the parent (`Hero`, `Closer`), not applied by `Cta` itself.
**Rationale**: `Cta` renders a plain `div` with no `role` or `aria-*` attributes; the parent knows the label appropriate to its own tagline and is best positioned to add grouping semantics if one is needed.
**Approved**: pending

