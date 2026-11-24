
**Decision**: Build the list header on `ButtonBar` rather than re-rolling a new
toolbar chrome beside it.
**Rationale**: Every toolbar on the platform is the same recessed strip;
composing `ButtonBar` keeps that chrome in one place. `ListWithDetailsPane`'s
inline toolbar was extracted into this block to establish a single source of
truth for list headers.
**Approved**: pending

**Decision**: Leave `SearchFilterBar` intact as a separate component rather
than merging it with `ListHeader`.
**Rationale**: The stacked search-region (field over `<select>` axes) serves
full search pages; merging the two would force each consumer to configure
away the other's shape. They remain separate patterns.
**Approved**: pending

**Decision**: `autoFocus` re-fires on every remount rather than only once at
first mount.
**Rationale**: Unlike the native HTML `autoFocus` attribute (which fires once
at first mount), this accommodates navigation stacks where filters need to
re-focus as users return to a list level (e.g. a topic level that unmounts on
exit and remounts on re-entry).
**Approved**: pending

**Decision**: The header owns no filter state of its own.
**Rationale**: It is a fully controlled component; the consumer holds the
filter text and calls `onChange` on every keystroke. This keeps the header
stateless and composable.
**Approved**: pending

**Decision**: Ship with four known gaps recorded as accepted debt rather than fixing them in
this version: the `Input` focus `transition-colors` is not gated behind
`prefers-reduced-motion` (`reduced-motion` failed); the `"Filter"` and `"Filter…"`
defaults are hard-coded English (`string-externalization` and `no-hardcoded-strings`
failed); and the Search icon's `left-2.5` and the input's `pl-8` are physical, not
logical, properties (`rtl-layout-support` partial).
**Rationale**: Each is small and contained. Consumers localize the two strings through
`search.label` and `search.placeholder`; the motion gate belongs to the shared `Input`
ingredient; the RTL fix is `start-2.5` and `ps-8`. Compliance keeps the failed and
partial statuses until they are fixed.
**Approved**: pending
