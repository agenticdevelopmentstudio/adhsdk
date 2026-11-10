
**Decision**: Use a dashed border as the visual marker for an empty or transitional state.
**Rationale**: This treatment replaces ad-hoc `border-dashed` utility classes scattered across the application, so every empty state signals absence of content the same way.
**Approved**: pending

**Decision**: Position the optional icon above the title rather than requiring it.
**Rationale**: Allows a visual cue (e.g., an empty folder icon) without forcing its inclusion, supporting everything from a minimal title-only state to a rich icon + title + description + action state.
**Approved**: pending

**Decision**: Fix the minimum height at 160px.
**Rationale**: Ensures the placeholder is substantial enough to be noticeable even when the title is brief; padding and gap values are tuned to this minimum.
**Approved**: pending

**Decision**: Accept `action` as an unconstrained `ReactNode` rather than a typed button/link.
**Rationale**: Lets consumers provide buttons, links, or other interactive elements appropriate to their context without the component dictating semantics.
**Approved**: pending

**Decision**: Delegate all color values to design tokens (`apt-border`, `apt-text-muted`, `apt-text-dim`) instead of hard-coded values.
**Rationale**: Keeps the component consistent with the design system and lets it follow theme switching automatically.
**Approved**: pending

