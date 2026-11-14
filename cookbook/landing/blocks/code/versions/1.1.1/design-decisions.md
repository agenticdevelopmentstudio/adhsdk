
**Decision**: The `text` prop is a plain `string` rather than `children` (`ReactNode`).
**Rationale**: Every other block in this package accepts `ReactNode` so a host can put emphasis or links inside it; here the whole point is that nothing is interpreted, and a `ReactNode` would invite a host to pass marked-up prose that would then render as code. A host that needs formatted content within code should use a separate component or structure.
**Approved**: pending

**Decision**: The component does not wrap text; it scrolls horizontally instead.
**Rationale**: Wrapping hides the real line boundaries, so readers mis-copy or misread multi-line input such as a wrapped shell invocation.
**Approved**: pending

