
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

