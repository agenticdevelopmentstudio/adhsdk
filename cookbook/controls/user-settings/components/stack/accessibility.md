
- **Role**: Stack renders a plain `<div>` with the implicit `generic` role and no explicit ARIA role. Stack does not forward `role` or other rest props (see #requirements/no-rest-prop-forwarding), so consuming code cannot set a role through Stack itself.
- **Keyboard navigation**: Not applicable; Stack is a layout primitive and does not handle keyboard interaction. Child elements within the Stack maintain their native keyboard behavior.
- **Screen reader**: Stack does not obscure the semantic meaning of child elements. The root `div` has the implicit `generic` role and adds no landmark or name, and its children remain exposed (see #requirements/render-non-semantic-div).
- **Labels**: Not applicable; Stack is a layout container and carries no label. Child interactive elements within the Stack MUST maintain their own labels.
- **Semantic structure**: Stack is transparent to the document outline because the root `div` adds no landmark or name (see #requirements/render-non-semantic-div). Child elements MUST maintain their semantic value (headings, buttons, etc.).

