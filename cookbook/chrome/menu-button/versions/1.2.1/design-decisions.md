
1. **Decision**: Render the bars as plain `<span>` elements rather than SVG.
   **Rationale**: `<span>` elements enable pixel-perfect alignment, color inheritance from the button's text color, and simpler animation via CSS transforms. SVG would require additional coordinate transformation logic and would not automatically inherit the button's color.
   **Approved**: pending

2. **Decision**: Derive the close icon from the two bars via CSS rotation rather than rendering separate markup for the X.
   **Rationale**: Rotating the existing bars keeps the component's JSX simpler and ensures that any change to bar geometry (thickness, spacing) automatically updates both the menu and close icons consistently.
   **Approved**: pending

3. **Decision**: Render bars conditionally — three in menu state, two in close state — rather than always rendering three and hiding one with CSS.
   **Rationale**: This is simpler than rendering three bars in both states and using CSS to hide one, and it matches the semantic difference between the two icons.
   **Approved**: pending

4. **Decision**: Keep all animation logic in CSS; the component renders static markup only.
   **Rationale**: This keeps the component lightweight and makes animations easy to customize or disable, e.g. for `prefers-reduced-motion` — which `css/base.css` does not currently implement (see **reduced-motion** in Compliance).
   **Approved**: pending

5. **Decision**: Require the `label` prop with no default value.
   **Rationale**: The button has no visible text, so an accessible name is necessary for the component to be usable by assistive technologies.
   **Approved**: pending

