
**Decision**: Keep the parser free of the DOM and React.
**Rationale**: The header comment states that it is shared by the server-side injector and the client editor so there is one parser and no drift.
**Approved**: pending

**Decision**: Parse with regular expressions instead of a CSS parser.
**Rationale**: Inferred from the source: the input is generated theme CSS with a known shape (a leading `:root` token block), so a few patterns suffice and need no dependency. The cost is the edge cases listed above (semicolons and braces inside values, comments, a missing final semicolon).
**Approved**: pending

**Decision**: Read only the first `:root` block.
**Rationale**: The comment on the block pattern says the first `:root` block of a generated theme is its token block, and the utilities and body rules that follow are theme-independent.
**Approved**: pending

**Decision**: Drop the token-classification, grouping and serialisation helpers.
**Rationale**: The header comment records they were removed when the editor moved to free-form CSS, leaving parsing only; `ThemeDelta` remains as the transfer type.
**Approved**: pending

**Decision**: Return the properties as a `Map` rather than a plain object.
**Rationale**: The doc comment calls it an ordered prop to value map; consumers iterate it in declaration order when building a delta block.
**Approved**: pending

