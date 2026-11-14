
**Decision**: The `aria-hidden="true"` attribute is fixed and non-configurable.
**Rationale**: The component has no semantic purpose for assistive technology; there is no case where it should be exposed to the accessibility tree.
**Approved**: pending

**Decision**: Visual appearance is delegated entirely to CSS (base class `lp-glow` plus an optional caller-supplied `className`) rather than exposed through component props.
**Rationale**: Decouples visual design from component logic, allowing design changes without code modification.
**Approved**: pending

**Decision**: Inside a hero, the glow's vertical offset is computed from the hero's own `--lp-hero-pad-top` / `--lp-hero-pad-bottom` custom properties rather than a hardcoded constant.
**Rationale**: Keeps the glow visually aligned with the hero's content as hero padding changes, so the two measurements cannot drift apart.
**Approved**: pending

