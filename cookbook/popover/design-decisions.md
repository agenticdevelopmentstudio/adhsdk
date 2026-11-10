
1. **Decision**: The lightweight variant remains mounted in the DOM at all times and is hidden via CSS (`opacity`/`visibility`) rather than unmounting; the full-featured variant unmounts `PopoverContent` when closed (Base UI's default `keepMounted={false}`, not overridden by this wrapper).
   **Rationale**: For the lightweight variant, this ensures server-rendered HTML includes the full page structure, accessible to non-JavaScript clients and screen readers, and lets CSS transitions work smoothly. The full-featured variant instead relies on Base UI's own mount/unmount and animation-completion handling.
   **Approved**: pending

2. **Decision**: The `arrow` prop on `PopoverContent` defaults to `false`.
   **Rationale**: Maintains backward compatibility with existing consumers who were built before the arrow feature was added and do not expect it.
   **Approved**: pending

3. **Decision**: On web, `PopoverContent` renders in a React Portal.
   **Rationale**: Escapes stacking context and ensures correct z-index layering above other page content without relying on parent CSS properties.
   **Approved**: pending

4. **Decision**: Appearance is defined using `apt-*` design tokens (apt-surface, apt-border, apt-text) rather than hard-coded color values.
   **Rationale**: Allows theming via token override without duplicating CSS rules.
   **Approved**: pending

5. **Decision**: Default placement is `bottom` for the full-featured variant and `top` for the lightweight variant, with an 8px offset on the full-featured variant.
   **Rationale**: Conventional defaults for popover components, providing adequate visual separation from the trigger without excessive displacement.
   **Approved**: pending

6. **Decision**: The full-featured variant is non-modal by default and delegates its accessibility behavior (dialog role, non-modal focus handling, Escape, aria-expanded) to Base UI's Popover rather than re-implementing it; the lightweight variant implements no accessibility behavior at all.
   **Rationale**: Ensures consistency with Base UI's tested and maintained standards for the full-featured variant, while keeping the lightweight variant intentionally minimal for inline hover use.
   **Approved**: pending

