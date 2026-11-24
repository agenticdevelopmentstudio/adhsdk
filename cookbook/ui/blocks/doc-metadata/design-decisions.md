
**Decision**: The component is intentionally minimal and stateless — it accepts pre-formatted data from the host and renders it with no transformation.
**Rationale**: Labels and values come from the host; the component's sole job is layout and styling.
**Approved**: pending

**Decision**: Render the field list as a semantic `<dl>` element with `<dt>`/`<dd>` pairs.
**Rationale**: Definition lists are the correct HTML structure for label-value metadata.
**Approved**: pending

**Decision**: Right-align the entire component.
**Rationale**: Right alignment positions the metadata visually as supplementary annotation, not primary content.
**Approved**: pending

**Decision**: Use an 11px monospace font for labels and values.
**Rationale**: Monospace at this size is a conventional pattern for document metadata, distinguishing frontmatter from prose body text.
**Approved**: pending

**Decision**: Wrap array values as a right-aligned flex group instead of forcing horizontal scroll or truncation.
**Rationale**: Allows the component to handle multi-valued fields (tags, references, platforms) cleanly within the row.
**Approved**: pending

**Decision**: Keep the built-in 24px bottom margin (`mb-6`) as an overridable default.
**Rationale**: The block sits between prose and the change history and needs that gap in its main use; a host that lays it out differently overrides it through `className`, where the merge lets the host class win.
**Approved**: pending

**Decision**: Accept the dynamic-type-support failure for the fixed 11px font size.
**Rationale**: The block shows metadata annotations rather than primary content, and a relative font size would break the compact frontmatter look; a host that needs scaling overrides the size through `className`.
**Approved**: pending

**Decision**: When a host class conflicts with a default class, the host class wins (`cn()` with tailwind-merge).
**Rationale**: The host knows its own layout, and the component's defaults are only a starting point.
**Approved**: pending

