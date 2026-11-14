
- **Role**: Semantic `<ul>` and `<li>` establish list structure; screen readers announce list length and each item's position where the browser keeps list semantics. The component does not add `role="list"`, and the stylesheet sets `display: flex` on each `li`.
- **Label requirements**: Individual items SHOULD provide meaningful content; if items contain interactive controls, they MUST include accessible labels or descriptions.
- **Keyboard navigation**: No interactive behavior in the container; keyboard access is inherited from item content.

