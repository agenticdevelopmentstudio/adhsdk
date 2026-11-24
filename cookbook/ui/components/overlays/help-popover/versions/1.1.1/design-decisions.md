
**Decision**: The flavor icon is marked decorative to assistive technology (`aria-hidden="true"`); flavor is conveyed through the popover panel's accessible name instead.
**Rationale**: This simplifies the accessible name and avoids the flavor being announced twice — once for the icon and once for the panel.
**Approved**: pending

**Decision**: The popover panel width is fixed at 320px.
**Rationale**: Prevents overly wide content and ensures readability; the width matches common content widths in the design system and accommodates most help text without requiring horizontal scroll.
**Approved**: pending

**Decision**: Title is optional and visually emphasized when present.
**Rationale**: When a title is present, `font-medium` weight distinguishes it from body text and provides visual hierarchy. When absent, the component renders only body text without empty space, avoiding visual clutter.
**Approved**: pending

**Decision**: The default flavor is `"info"` when `entry.flavor` is not provided.
**Rationale**: This is the most neutral and widely applicable flavor for general help content.
**Approved**: pending

**Decision**: Default positioning is `side="bottom"`, `align="start"`.
**Rationale**: This positions the popover below the trigger control and aligned to its left edge, a common popover placement that does not obscure the trigger or surrounding content in most contexts.
**Approved**: pending

**Decision**: Text colors are applied via design system tokens (`apt-text`, `apt-text-muted`) rather than hardcoded values.
**Rationale**: This ensures consistency with the application's color scheme and supports light/dark mode switching via token overrides.
**Approved**: pending

