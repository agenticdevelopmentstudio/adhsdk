
**Decision**: Title and eyebrow use a monospace font.
**Rationale**: Creates visual distinction and hierarchy, aligned with a technical/data-focused design system; reinforces the component's use in dashboards and structured content.
**Approved**: pending

**Decision**: The section title uses the `apt-gold` semantic color token.
**Rationale**: Gold conveys prominence and primary hierarchy, distinguishing the title from standard text.
**Approved**: pending

**Decision**: The help trigger uses `quietControlClass` for muted styling.
**Rationale**: Keeps the help button visually subordinate to content, preventing distraction while remaining discoverable for users who need it.
**Approved**: pending

**Decision**: The help popover has a fixed width of 288px (`w-72`).
**Rationale**: Ensures readability of help text without forcing unnecessary wrapping.
**Approved**: pending

**Decision**: The help popover is positioned below and aligned to the end (right edge) of the trigger.
**Rationale**: Follows standard popover conventions, avoids overlap with the title, and keeps the trigger button visible.
**Approved**: pending

**Decision**: The root container uses `justify-between` to left-justify the title area and right-justify actions/help.
**Rationale**: Creates a clear visual separation between content (left) and controls (right).
**Approved**: pending

**Decision**: `title` is a required prop.
**Rationale**: Title is not optional because the component's purpose is to introduce a section; a section header without a title is meaningless.
**Approved**: pending

**Decision**: `eyebrow`, `help`, and `actions` are optional.
**Rationale**: Accommodates simple use cases (title-only headers) without requiring conditional rendering at call sites.
**Approved**: pending

**Decision**: The title's heading level is fixed at `<h2>`; there is no `level` or `as` prop to change it.
**Rationale**: The source hardcodes `<h2>` in every usage. This is a known limitation: nesting a Section Header inside content that already has an `<h2>` ancestor will produce an incorrect document outline. A future revision could add a `level`/`as` prop; until then, callers are responsible for keeping Section Header at a consistent outline depth.
**Approved**: pending

