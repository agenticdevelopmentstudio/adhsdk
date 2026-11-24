
**Decision**: Prop presence is checked with `!== undefined` rather than truthiness.
**Rationale**: This allows falsy values like empty strings, `0`, or `false` to render as content, matching React's own treatment of these as valid children, and preserves the distinction between "prop not provided" (`undefined`) and "prop provided with a falsy value" (render it).
**Approved**: pending

**Decision**: The eyebrow renders as a generic `span` with no semantic role, rather than nested inside the `h2` or auto-linked to it.
**Rationale**: The eyebrow is a visual label that is not always semantically significant; the component leaves it to the caller to add the semantics (see **eyebrow-accessibility** guidance in Accessibility) when the eyebrow content matters to the outline.
**Approved**: pending

**Decision**: The title always renders at a fixed `h2` level; there is no `level` configuration option.
**Rationale**: `Head` is meant to introduce a section directly under a page's single `h1`, so a fixed level keeps every section's document outline consistent; a caller that needs a different level needs a different component, not a prop that could produce a broken outline.
**Approved**: pending

**Decision**: Because presence is checked with `!== undefined` (see above), passing `null` for `eyebrow`/`title` or `""` for `title` still renders the element — an empty `span` or an empty `h2` — rather than skipping it.
**Rationale**: Kept consistent with the presence-check decision above rather than adding a second, different rule for "empty" values; the accessibility cost is that a blank `h2` reaches the screen-reader heading outline, so callers MUST pass `undefined` (omit the prop), not `null` or `""`, when there is no title to show.
**Approved**: pending

