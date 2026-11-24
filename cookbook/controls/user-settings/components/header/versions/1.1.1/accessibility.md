
- **Role**: Implicit `heading` role via native `<h2>` element (heading level 2).
- **Label**: Content passed via `children` prop serves as the heading label; it MUST be meaningful and descriptive of the section it introduces.
- **Semantic structure**: By rendering a native `<h2>` element, the component provides proper outline nesting for screen readers and document outline tools.
- **Announcements**: Screen readers automatically announce this element as a heading at level 2; no additional state announcement is needed.
- **Keyboard navigation**: Not applicable; the component is non-interactive and does not receive focus.

