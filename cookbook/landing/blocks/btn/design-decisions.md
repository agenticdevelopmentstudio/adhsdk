
- **Decision**: Render a native `<a>` (anchor) element rather than a `<button>` with JavaScript navigation.
  **Rationale**: Preserves built-in browser affordances (context menus, link preview, history, keyboard shortcuts like Ctrl/Cmd+click, ability to copy or open in new tab) and maintains semantic correctness for screen readers and SEO.
  **Approved**: pending

- **Decision**: Manage appearance entirely via CSS classes (`lp-btn`, `lp-btn--{variant}`), never via component props or inline styles.
  **Rationale**: Decouples the component from color tokens, theme values, and spacing constants, keeping the component API minimal and letting styling live in centralized stylesheets that can be updated without changing component code.
  **Approved**: pending

- **Decision**: Require both `href` and `children` props, enforced by TypeScript.
  **Rationale**: Ensures every call site supplies a destination and content, catching missing-argument mistakes at compile time. This does not guarantee the content is meaningful or non-empty — `children` accepts `null`, `undefined`, or an empty string at runtime (see **supports-children** and Edge Cases); callers remain responsible for providing descriptive link text.
  **Approved**: pending

- **Decision**: Constrain the `variant` prop to the literal union `'primary' | 'ghost'` via TypeScript.
  **Rationale**: Prevents arbitrary class names and signals the available options clearly to consumers at the type level.
  **Approved**: pending

- **Decision**: Accept exactly three named props (`href`, `variant`, `children`), with no prop spreading or rest capture onto the anchor.
  **Rationale**: Keeps the rendered DOM fully predictable and prevents unvetted attributes (`onClick`, `target`, `rel`, `aria-*`, `className`) from leaking onto the anchor; consumers needing additional anchor behavior should get a dedicated variant or wrapper rather than an open prop surface.
  **Approved**: pending

