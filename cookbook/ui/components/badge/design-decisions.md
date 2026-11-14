
**Decision**: The chip is transparent with the border and text sharing a single tone color, rather than a filled background.
**Rationale**: The source comment states it is a 1:1 match of the deployed header badge, which is drawn this way.
**Approved**: pending

**Decision**: Badge is a plain `span` with `variant` as its only own prop, and it spreads the remaining `span` props.
**Rationale**: It stays a non-interactive label that consumers can extend with ids, titles and aria attributes without new API.
**Approved**: pending

**Decision**: The module exports `badgeVariants` as well as `Badge`.
**Rationale**: The class builder can then be applied to other elements that need the same look, such as a link styled as a badge.
**Approved**: pending

