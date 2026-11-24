
**Decision**: Render the root as a `<p>` element rather than `<span>` or `<div>`.
**Rationale**: Trades semantic neutrality for a block-level default; the component has no element prop, so callers place it in block-level content and never inside a `<p>`, `<button>` or other phrasing-only element.
**Approved**: pending

**Decision**: `free` defaults to `undefined` (falsy) rather than requiring an explicit value.
**Rationale**: Lets the common case (`<StatusPill>Active</StatusPill>`) skip passing `free={false}`.
**Approved**: pending

**Decision**: Build the class list with `['lp-status', free === true ? 'lp-status--free' : ''].filter(Boolean).join(' ')` instead of a class-name utility library.
**Rationale**: One conditional class does not justify a dependency; the filter-and-join pattern keeps the component dependency-free.
**Approved**: pending

**Decision**: Keep the prop named `free` rather than a neutral name such as `accent` or `variant`.
**Rationale**: The source docstring documents `free` as marking "the one status that gets the accented treatment". The name began as a free-tier marker, but the Hero status and the `Chips` provider list use the same prop to accent any one item, so `free` is now a legacy name for "accented". Renaming it would break callers for no behavioral gain; read `free` as "accented" everywhere, as the Overview does.
**Approved**: pending

**Decision**: Keep StatusPill separate from `badge` ([adhsdk.ingredient.ui.controls.badge](cookbook:2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f)) rather than folding it in as a variant.
**Rationale**: The two differ in root element (block `<p>` here vs. inline `<span>` in badge), token namespace (`--lp-*` landing tokens vs. badge's own tokens), and variant model (one binary accent here vs. badge's six tone variants); merging them would mean badge's `<span>` consumers inherit a block element, or StatusPill's callers inherit six unrelated tones.
**Approved**: pending

