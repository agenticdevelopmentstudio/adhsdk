
**Decision**: Use CSS `margin` rather than CSS `transform` to extend the child element past the content column.
**Rationale**: `margin` forces the neighboring column to surrender space, creating the intended visual hierarchy; a `transform` would move the element visually without affecting layout, leaving space in the neighboring column and defeating the "crop by viewport" effect.
**Approved**: pending

**Decision**: Filter out falsy class names (empty strings, `null`, `undefined`) before joining the class list.
**Rationale**: Prevents unintended class concatenation (e.g., a stray double space from an empty `className`) and keeps the rendered class list clean.
**Approved**: pending

**Decision**: Do not validate that `side` is one of the expected values (`'left'` or `'right'`).
**Rationale**: TypeScript's `'left' | 'right'` type covers the supported surface, which keeps the component simple and delegates validation to the caller. What a value outside the type renders is unspecified (see the **Side values outside the typed union** edge case).
**Approved**: pending

**Decision**: Assume Bleed is rendered inside a container with `overflow-x: clip` (e.g. `.lp-band`, see the `Band` ingredient).
**Rationale**: Enforcing the clip inside Bleed would couple Bleed to a specific parent component; see the **Missing clipping parent** edge case for what happens without it.
**Approved**: pending

