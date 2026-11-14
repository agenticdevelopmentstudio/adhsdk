
**Decision**: The `sites` array is treated as read-only, and `currentSite` is external state; the component does not manage navigation or page state itself.
**Rationale**: Each site is a simple data object (`url`, `name`, `emoji`, `iconGradient`) supplied by the caller, so keeping the component stateless keeps it composable with any router or state layer.
**Approved**: pending

**Decision**: Current-page links use `aria-current="page"`.
**Rationale**: This follows WCAG best practices for marking the active page within a navigation landmark.
**Approved**: pending

**Decision**: The emoji span and the current-page indicator span are marked `aria-hidden="true"`.
**Rationale**: Both are purely visual reinforcement of information already conveyed by the link's `aria-label` and `href`; announcing them again would be redundant.
**Approved**: pending

**Decision**: The site name span carries `role="tooltip"`.
**Rationale**: The role signals that the span is contextual, hover-revealed help text, though the source does not associate it with the link via `aria-describedby`, so assistive technology receives the site name only through the link's `aria-label`, not through the tooltip role itself.
**Approved**: pending

