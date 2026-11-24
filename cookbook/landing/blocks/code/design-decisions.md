
**Decision**: The `text` prop is a plain `string` rather than `children` (`ReactNode`).
**Rationale**: The sibling blocks ([adhsdk.ingredient.landing.blocks.closer](cookbook:688cd8dc-2927-4a8a-9931-807fe283ed01), [adhsdk.ingredient.landing.blocks.cta](cookbook:f98e53f7-ac16-48b0-afa5-544d05bf3f70) and [adhsdk.ingredient.landing.blocks.contact](cookbook:8c5e2f9b-7d3a-4a1c-b8e4-9f2d1c5a7b3e)) accept `ReactNode` so a host can put emphasis or links inside it; here the whole point is that nothing is interpreted, and a `ReactNode` would invite a host to pass marked-up prose that would then render as code. A host that needs formatted content within code should use a separate component or structure.
**Approved**: pending

**Decision**: The component does not wrap text; it scrolls horizontally instead.
**Rationale**: Wrapping hides the real line boundaries, so readers mis-copy or misread multi-line input such as a wrapped shell invocation.
**Approved**: pending

**Decision**: An empty `text` renders a collapsed block, and the layout shift when `text` goes from empty to non-empty is accepted.
**Rationale**: The component does not set a `min-height` on `.lp-code`, because an empty transcript is a caller error rather than a state to design for, and reserving a line would add a rule that every port must reproduce for no real use.
**Approved**: pending
