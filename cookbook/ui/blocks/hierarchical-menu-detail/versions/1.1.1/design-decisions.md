
1. **Decision**: Surface state (autoHide, pins, hover reveal, detail hold) is stored outside per-render component state, keyed by the root level's id, so it survives the remount that a selection causes.
   **Rationale**: Storing this in ordinary component state would lose pins, hover reveal, and the held detail on every selection, because selecting a row is a route change that remounts the component subtree. Keying by the root level's id keeps the state stable across navigations within one surface; a page reload starts fresh, which is the correct seam for a deliberate fresh start.
   **Approved**: pending

2. **Decision**: Three disclosure styles — minimized (icon strips), covered (layered stacks), cascading (stepped nested-menu) — cover different screen sizes and interaction patterns.
   **Rationale**: Minimized suits phones with a Back button; covered maximizes list visibility without a Back button; cascading mimics native nested-menu hover-reveal behavior.
   **Approved**: pending

3. **Decision**: Per-list pins persist in the same outside-of-component surface state as autoHide, not in component state.
   **Rationale**: Selecting a row is a route change that remounts the component, so pins stored in component state would reset on every selection; storing them in the persisted surface state lets a pin survive across selections without fighting the user.
   **Approved**: pending

4. **Decision**: A level's `defaultSelectedId` fires as `onSelect(id, { replace: true })`.
   **Rationale**: Without `replace: true`, the Back gesture would land on the bare parent, which would immediately re-apply the default and bounce forward, costing two Back presses to escape instead of one.
   **Approved**: pending

5. **Decision**: The unsaved-changes guard runs on breadcrumb-up navigation (deselecting shallower levels), sibling swaps at the deepest selected level, breadcrumb-up clicks on a shallower row, and re-clicking a selected row (deselect) — any selection change that would clear or replace the open leaf editor.
   **Rationale**: Each of these can discard in-progress work in the detail pane, so each must be able to raise the unsaved-changes alert before proceeding.
   **Approved**: pending

6. **Decision**: Selection connectors are measured on demand (via a resize observer) and re-measured on a short loop (400ms default) while animations play, rather than computed on every render.
   **Rationale**: This avoids computing paths for connectors that are off-screen or not rendered, and keeps the selection chain in sync while the lists slide.
   **Approved**: pending

7. **Decision**: The frontier is the first level with no selection, or the last level if every level has a selection; only the frontier and the levels above it render.
   **Rationale**: This keeps the render cost and the layout math to exactly the levels the user can see or is choosing from.
   **Approved**: pending

8. **Decision**: No transition in this component is gated on the `prefers-reduced-motion` system preference.
   **Rationale**: Standing instruction from the component's owner to ignore that preference until it is lifted; it is not a claim that the preference doesn't matter, only that this component doesn't yet act on it.
   **Approved**: pending

