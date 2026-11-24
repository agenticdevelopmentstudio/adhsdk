
**Decision**: The `caption` prop is required and always rendered; it is visually hidden via `lp-sr-only` unless the caller passes `showCaption={true}`, which defaults to `false`.
**Rationale**: The caption is the only element that identifies the data population the table represents — omitting it silently risks presenting a partial sample (e.g., three of ten runs) as complete, misleading readers. The default visual hiding preserves the caption's accessibility benefit while avoiding redundancy with surrounding prose that already states the table's purpose. A caller passes `showCaption={true}` only when the surrounding context does not already identify the table's purpose and the caption's text needs to be visible on the page.
**Approved**: pending

**Decision**: Row width validation (**row-width-validation**) occurs synchronously at render time and throws a synchronous error on mismatch, rather than returning a validation result.
**Rationale**: This fail-fast behavior prevents silent data misalignment — the kind of defect that reads as a typo in the content rather than as a bug — and makes the error obvious during development. A validation framework could instead return a validation result prop; this implementation prioritizes immediate visibility over graceful error recovery.
**Approved**: pending

**Decision**: The component uses semantic HTML (`<table>`, `<th scope="col">`, `<caption>`) to delegate accessibility responsibility to browser defaults rather than requiring custom ARIA roles.
**Rationale**: This approach reduces implementation burden and follows the practice of preferring native semantics over custom ARIA roles when a native element already provides the needed behavior, per the W3C WAI tables tutorial and the HTML `caption`/`th[scope]` specification listed in `references`.
**Approved**: pending

**Decision**: An empty `columns` array is allowed. It produces a table with no header cells, and is valid only when every row also has zero cells (an empty `rows` array satisfies this trivially); **row-width-validation** still throws if any row has a non-zero length in that case.
**Rationale**: Zero columns is a degenerate input but not inherently invalid — the same width check that guards against misaligned cells already rejects any row that doesn't match it, so no separate rule against empty `columns` is needed. Banning zero columns outright would reject legitimate callers, such as a table rendered before its columns are known, without preventing any misalignment the existing check doesn't already catch.
**Approved**: pending

