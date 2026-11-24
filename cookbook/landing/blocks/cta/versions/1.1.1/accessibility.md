
- **Role**: Generic container (implicit `div` role)
- **Semantics**: The `lp-cta` class does not alter semantic meaning; children determine accessibility tree structure
- **Keyboard navigation**: Not applicable; container is not interactive; keyboard navigation depends on child elements (buttons, links)
- **Screen reader**: Children are exposed directly in the accessibility tree with their own labels and roles
- **Grouping semantics**: `Cta` adds no `role="group"` or `aria-label` of its own — see Design Decisions.

