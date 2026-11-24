
**Decision**: Reuse the ATK UI `Select` primitive (a styled native `<select>`) instead of building a custom dropdown.
**Rationale**: This ensures cross-browser consistency and automatic accessibility features (ARIA roles, keyboard navigation) without a custom implementation. A custom dropdown would offer more visual control but at the cost of re-implementing accessibility and keyboard behavior.
**Approved**: pending

**Decision**: Hardcode the "Theme" label text rather than accepting a label prop.
**Rationale**: This is intentional for a component in an English-primary environment, but it limits reuse in multilingual contexts; localizing it would require accepting a label prop or deriving it from context.
**Approved**: pending

**Decision**: Do not debounce or deduplicate the theme-change callback.
**Rationale**: Rapid theme selections trigger multiple callbacks. This allows the parent to handle rapid changes as needed (e.g., for analytics or throttling) rather than constraining the behavior in the component. If rapid changes should be rejected, the parent should implement debouncing in the callback handler.
**Approved**: pending

**Decision**: Generate the selection element's id via `useId()` rather than requiring an id prop.
**Rationale**: This ensures unique ids without external coordination or props, which is crucial for multiple instances on the same page (e.g., multiple MarkdownViewer + MarkdownThemeSwitcher pairs). The approach is sound for SSR and client-side hydration.
**Approved**: pending

