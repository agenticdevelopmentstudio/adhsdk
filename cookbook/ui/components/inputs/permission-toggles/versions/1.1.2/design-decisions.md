
**Decision**: The component does not validate or correct the `value` prop against `parent` on mount. Enforcement occurs only during user interaction via the `toggle()` function, and only for the capability being toggled (see **clamp-emitted-values**).
**Rationale**: If `value` violates `parent` on initial render, the button will appear off (due to the `on = value[key] && !blockedByParent` calculation) but the component does not emit a corrected value. This design assumes the caller is responsible for providing a valid initial state; a stricter design would validate on mount and call `onChange` with a corrected value, but this design trusts the caller.
**Approved**: pending

**Decision**: The button size is fixed at 28×28px rather than the 44×44pt (Apple HIG) / 48×48dp (Material Design 3) recommended minimum touch target.
**Rationale**: The component prioritizes space efficiency and density in permission matrices or settings panels where multiple toggles are presented in a compact grid (e.g., a settings table). This is acceptable in that context but not suitable for standalone buttons or contexts where users have dexterity limitations. Implementations should confirm this size against their own accessibility audit and use case.
**Approved**: pending

**Decision**: Blocked capabilities are rendered disabled and visually suppressed (opacity: 0.4) rather than hidden.
**Rationale**: This allows users to understand what permissions exist and why they cannot be enabled. Hiding blocked buttons would require less space but would sacrifice discoverability of the permission structure.
**Approved**: pending

**Decision**: The `onChange` callback is invoked synchronously during the click handler, with no debouncing, throttling, or asynchronous state updates.
**Rationale**: Rapid clicks generate rapid emissions by design; applications that need to batch or debounce permission changes should do so in their own state management, keeping this component simple and predictable.
**Approved**: pending

**Decision**: Capabilities are abbreviated to single-letter labels (C, R, U, D) rather than full words.
**Rationale**: This minimizes visual space and assumes the user understands CRUD as a standard concept in permission modeling. Full-text labels (Create, Read, Update, Delete) would require more space and, unlike the letters, would need translation.
**Approved**: pending

**Decision**: Unconditional color transition — the `transition-colors` class animates border, background, and text color on every state change, with no check of `prefers-reduced-motion` (or the platform equivalent).
**Rationale**: The transition is a color-only change with no motion or translation, which may already be acceptable under reduced-motion guidance; this has not been decided, and the source provides no mechanism to suppress the transition either way.
**Approved**: pending

