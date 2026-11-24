
**Decision**: The component is written without hooks or client-only APIs so it can be used within async React Server Components.
**Rationale**: This constraint is a feature, not a limitation — it allows async server-rendered document views to use this wrapper without client-side hydration overhead. Callers that need client-side behavior should wrap this component in a Client Component of their own.
**Approved**: pending

**Decision**: The component merges the caller's `className` with `adh-mv-content` via `cn`, rather than replacing one or the other.
**Rationale**: This allows callers to supply layout modifiers (sizing, borders, rounding) while preserving the theme-driven layout class. The `adh-mv-content` class is load-bearing for background, padding, and overflow — removing it would break readability.
**Approved**: pending

**Decision**: The component accepts `data-slot` as a prop rather than hardcoding a value like `"markdown-reading-palette"`.
**Rationale**: The component is a generic reading surface reused under different names by different hosts (e.g., `MarkdownDocumentEditor`'s preview pane uses `"markdown-preview"`, while a future caller might use something else). Taking the slot as a prop lets each host name it according to its context.
**Approved**: pending

**Decision**: The component calls `getThemeById(themeId)` at render time rather than caching or memoizing the lookup.
**Rationale**: This keeps the component simple and ensures it reflects the current `themeId` prop on each render, without introducing component state.
**Approved**: pending

**Decision**: The component does not validate `themeId` or wrap `getThemeById` in a try/catch of its own.
**Rationale**: `getThemeById` already handles an unrecognized id by falling back to the `DEFAULT_THEME_ID` theme instead of throwing, so a markdown reading surface never fails to render over a stale or unrecognized theme id. Because the fallback lives in `getThemeById`, the component needs no error-handling logic of its own.
**Approved**: pending

