
**Decision**: Reuse the `@adh-sdk/ui` `Select` primitive (a styled native `<select>`) instead of building a custom dropdown.
**Rationale**: This ensures cross-browser consistency and automatic accessibility features (ARIA roles, keyboard navigation) without a custom implementation. A custom dropdown would offer more visual control but at the cost of re-implementing accessibility and keyboard behavior.
**Approved**: pending

**Decision**: Hardcode the "Theme" label text rather than accepting a label prop.
**Rationale**: This is intentional for a component in an English-primary environment, but it limits reuse in multilingual contexts; localizing it would require accepting a label prop or deriving it from context.
**Approved**: pending

**Decision**: Do not debounce the theme-change callback.
**Rationale**: Rapid theme changes trigger multiple callbacks (a re-selection of the current theme triggers none, because a native `<select>` sends no change event for it). This allows the parent to handle rapid changes as needed (e.g., for analytics or throttling) rather than constraining the behavior in the component. If rapid changes should be rejected, the parent should implement debouncing in the callback handler.
**Approved**: pending

**Decision**: Generate the selection element's id via `useId()` rather than requiring an id prop.
**Rationale**: This ensures unique ids without external coordination or props, which is crucial for multiple instances on the same page (e.g., multiple MarkdownViewer + MarkdownThemeSwitcher pairs). The approach is sound for SSR and client-side hydration.
**Approved**: pending

**Decision**: Accept the 32px control height (`h-8`) even though it is below the 44px touch target guideline.
**Rationale**: The control sits in a dense viewer toolbar next to other compact controls; growing it to 44px would crowd the toolbar. The adjacent label also focuses the control when clicked, which enlarges the effective hit area. The trade-off is recorded as a `failed` touch-target-size check in Compliance.
**Approved**: pending
