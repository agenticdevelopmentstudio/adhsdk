
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


**Decision**: The three flavor labels ("Help", "Information", "What's new") stay hardcoded English in the `FLAVORS` table, with no localization option.
**Rationale**: The labels reach users only through the panel's accessible name, and the consuming sites are English-only today, so a localization hook would have no caller yet. The `no-hardcoded-strings` Compliance check records the debt as failed; the fix is to accept the three labels as a caller-supplied option when a second locale is needed.
**Approved**: pending

**Decision**: An out-of-union flavor throws rather than falling back to `"info"`.
**Rationale**: The type system already forbids the value, so reaching it means a caller bug, and a thrown error is easier to notice than a quietly wrong icon. The error is a plain `TypeError` from the table lookup and does not name the flavor.
**Approved**: pending
