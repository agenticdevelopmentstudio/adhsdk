
**Decision**: Render as a headless, minimal wrapper — semantic HTML structure and flexbox layout only, with all visual styling deferred to the caller via `className`.
**Rationale**: This design allows the component to work in any visual context (light mode, dark mode, custom themes) without baking in colors or opinionated styling; its sole responsibility is correct toolbar semantics and consistent child spacing, leaving presentational concerns to the parent or a parent-provided theme.
**Approved**: pending

**Decision**: Use `role="toolbar"` for semantic grouping without implementing the WAI-ARIA toolbar keyboard pattern (roving tabindex, arrow-key navigation, Home/End); focus and keyboard handling are left entirely to child elements.
**Rationale**: The component composes arbitrary, caller-supplied children and cannot know their keyboard semantics in advance. It establishes the `toolbar` region for assistive technology without promising keyboard behavior it doesn't implement — see **keyboard-navigable** in Compliance for the resulting gap.
**Approved**: pending

