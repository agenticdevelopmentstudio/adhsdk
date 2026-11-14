
1. **Decision**: Render the bars as plain `<span>` elements rather than SVG.
   **Rationale**: Plain DOM boxes let the bar geometry live in CSS custom properties (`--menu-bar-thickness`, `--menu-bar-gap`, `--menu-bar-width`) that a consumer can retune, and let the 0.25s transition and the rotation act on the same elements. Colour inheritance is not the differentiator, since SVG could also use `currentColor`. Unverified: the source does not record whether SVG was tried or measured.
   **Approved**: pending

2. **Decision**: Derive the close icon from the two bars via CSS rotation rather than rendering separate markup for the X.
   **Rationale**: Rotating the existing bars keeps the component's JSX simpler and ensures that any change to bar geometry (thickness, spacing) automatically updates both the menu and close icons consistently.
   **Approved**: pending

3. **Decision**: Render bars conditionally — three in menu state, two in close state — rather than always rendering three and hiding one with CSS.
   **Rationale**: No hidden DOM node is left behind: a CSS-hidden third bar would still occupy the grid and add a gap row unless `display: none` were also applied, and the close state's overlay of two bars in one grid cell relies on there being exactly two children.
   **Approved**: pending

4. **Decision**: Keep all animation logic in CSS; the component renders static markup only.
   **Rationale**: This keeps the component lightweight and makes animations easy to customize or disable, e.g. for `prefers-reduced-motion` — which `css/base.css` does not currently implement (see **reduced-motion** in Compliance).
   **Approved**: pending

5. **Decision**: Require the `label` prop with no default value.
   **Rationale**: The button has no visible text, so an accessible name is necessary for the component to be usable by assistive technologies.
   **Approved**: pending

6. **Decision**: Perform no runtime check on `label`; rely on the required TypeScript prop.
   **Rationale**: The source renders `aria-label={label}` directly, so a caller outside the type system that omits or empties `label` gets a button with no accessible name and no warning. The recipe records this as the current behavior, not an endorsement.
   **Approved**: pending
