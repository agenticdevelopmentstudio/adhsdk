
- **Semantic markup**: The component uses the semantic `<dl>`, `<dt>`, and `<dd>` elements, which are properly interpreted by screen readers as a definition list structure.
- **Content accessibility**: The accessibility of the term and detail content depends on what is passed as `ReactNode` values. If terms and details contain text, they are announced by screen readers. If they contain interactive elements or images, those elements' own accessibility properties apply.
- **No labels or roles required**: The component itself requires no additional ARIA attributes, roles, or labels; semantic HTML provides sufficient structure.
- **Minimum tap target**: Not applicable — Rule contains no interactive controls and thus no touch targets.

