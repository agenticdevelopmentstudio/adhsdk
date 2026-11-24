
**Decision**: Use `<dl>`, `<dt>`, and `<dd>` elements rather than generic `<div>`s.
**Rationale**: Leverages semantic HTML to provide out-of-the-box accessibility for screen readers and assistive technology.
**Approved**: pending

**Decision**: `term` and `detail` accept `ReactNode` rather than `string`.
**Rationale**: Allows consumers to pass not just text but also styled elements, images, links, or other React components, trading compile-time per-field validation for runtime flexibility.
**Approved**: pending

**Decision**: Delegate all visual styling to the `lp-rule` CSS class; the component applies no inline styles, colors, fonts, or sizes.
**Rationale**: Keeps the component pure and confines styling concerns to the stylesheet.
**Approved**: pending

**Decision**: Do not validate the `steps` prop or guard against `null`, `undefined`, or malformed input.
**Rationale**: Consumers are responsible for ensuring `steps` is a valid array of `RuleStep` objects; the TypeScript type contract enforces this at compile time.
**Approved**: pending

