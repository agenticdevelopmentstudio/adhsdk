
1. **Decision**: `href` takes precedence over `onClick` — when both props are provided, the component renders as an anchor and executes `onClick` before navigation.
   **Rationale**: This prioritizes semantic HTML and browser affordances (middle-click, ⌘-click, history, status bar URL preview) while allowing side effects (analytics, state mutation) to occur first.
   **Approved**: pending

2. **Decision**: `div[role="button"]` is used for the `onClick` root instead of a native `<button>`.
   **Rationale**: The card's flow content (paragraph `<p>` for description, div for meta) is not valid inside a native button element. A div allows arbitrary children and is semantically correct when paired with `role="button"` and keyboard handlers.
   **Approved**: pending

3. **Decision**: The `LinkComponent` prop accepts a wrapper component (e.g. Next.js Link or React Router Link) instead of hard-coding a router dependency, and follows the `to` naming convention rather than `href`.
   **Rationale**: This matches the shared `DocLinkComponent` injection pattern (`packages/web/packages/ui/src/blocks/doc-types.ts`), used by every block in this family that accepts a router component (e.g. `doc-nav`, `doc-breadcrumbs`), so a host writes one adapter for all of them.
   **Approved**: pending

4. **Decision**: Hover, focus, and cursor-pointer styling are applied only when `href` or `onClick` is provided.
   **Rationale**: This avoids misleading static cards into appearing interactive and prevents unnecessary state management.
   **Approved**: pending

5. **Decision**: No built-in `aria-label` or `aria-description`.
   **Rationale**: The component relies on its rendered content (title, identifier, description) to be self-describing. Implementers should ensure context makes the purpose of each field clear or add aria-attributes at the parent level if more explicit labeling is needed.
   **Approved**: pending

