
**Decision**: When at the root (empty crumbs), the component returns null rather than showing a single "Home" link.
**Rationale**: This avoids redundant navigation UI pointing to the current page and keeps the breadcrumb visually useful only when there is an ancestor trail to show.
**Approved**: pending

**Decision**: The last crumb is always rendered as plain text instead of a link.
**Rationale**: This follows web breadcrumb conventions (e.g., WAI-ARIA examples) and prevents users from "clicking" to reload the current page.
**Approved**: pending

**Decision**: The component deliberately does not derive breadcrumbs from the URL or page slug; crumbs are caller-supplied.
**Rationale**: Each site has its own URL structure and labeling convention (e.g., cookbook's `slugToBreadcrumbs` title-cases domain segments; another site might look labels up in a manifest). Deriving them here would bake one site's URL convention into the toolkit. Responsibility for breadcrumb construction belongs to the host application.
**Approved**: pending

**Decision**: The component accepts a `LinkComponent` prop instead of hardcoding native `<a>` elements.
**Rationale**: This allows host applications to integrate their own router (Next.js Link, React Router, etc.) without the toolkit imposing a routing library dependency.
**Approved**: pending

**Decision**: Use `<nav>`, `<ol>`, and `<li>` elements with an ARIA label.
**Rationale**: Ensures breadcrumb navigation is properly announced and indexed by assistive technology and search engines.
**Approved**: pending

