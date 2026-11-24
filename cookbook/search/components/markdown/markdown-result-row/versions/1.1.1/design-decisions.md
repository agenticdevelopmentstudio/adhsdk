
- **Decision**: The `active` prop supports three states (`true`, `false`, `undefined`).
  **Rationale**: This allows the component to integrate seamlessly into managed lists (where `active` controls the tabindex) and also render standalone (where `undefined` preserves natural tab order), avoiding forcing list context on every use case.
  **Approved**: pending

- **Decision**: Badge variant and snippet source are resolved via the `kindRendererFor(hit.kind)` registry rather than hard-coded per kind.
  **Rationale**: This allows new document kinds to be added by registering a renderer without modifying the component itself.
  **Approved**: pending

- **Decision**: Highlights are applied via semantic `<mark>` elements and React node children, never `dangerouslySetInnerHTML`.
  **Rationale**: Ensures that user-controlled text from `hit.title`, snippet, and `hit.tags` cannot introduce XSS vulnerabilities.
  **Approved**: pending

- **Decision**: The "View paper" link's visible text stays at 12px while its clickable area is enlarged to a 24px-tall zone using an invisible `::after` overlay.
  **Rationale**: This preserves the visual design while meeting WCAG 2.2 SC 2.5.8 and follows the idiom already used by the active-filter chip's × button.
  **Approved**: pending

- **Decision**: The select button and "View paper" link are rendered as sibling elements (button followed by link in the footer), not nested.
  **Rationale**: Preserves valid DOM structure and allows independent keyboard focus and interaction, avoiding the complexity of nested interactive controls.
  **Approved**: pending

- **Decision**: `kindRendererFor(hit.kind).rowSnippet(hit).trim()` is called to remove leading/trailing whitespace from the per-kind snippet.
  **Rationale**: Ensures consistent rendering regardless of formatter output.
  **Approved**: pending

- **Decision**: When `hit.title` is null or empty, the component renders "Untitled" as a fallback label.
  **Rationale**: Ensures that every row has a visible title, making the list navigable even for documents with missing or empty titles.
  **Approved**: pending

- **Decision**: The row's select control uses `aria-pressed` (a toggle-button pattern) rather than `role="option"` / `aria-selected` (a listbox pattern) to convey selection.
  **Rationale**: Each row is an independently focusable `<button>` whose tabindex is managed externally by roving-tabindex, not a native `listbox`/`option` structure; `aria-pressed` reflects the button's two-state toggle semantics without requiring the containing list to implement full listbox role and keyboard conventions.
  **Approved**: pending

