
**Decision**: Use CSS `margin` rather than CSS `transform` to extend the child element past the content column.
**Rationale**: `margin` forces the neighboring column to surrender space, creating the intended visual hierarchy; a `transform` would move the element visually without affecting layout, leaving space in the neighboring column and defeating the "crop by viewport" effect.
**Approved**: pending

**Decision**: Filter out falsy class names (empty strings, `null`, `undefined`) before joining the class list.
**Rationale**: Prevents unintended class concatenation (e.g., a stray double space from an empty `className`) and keeps the rendered class list clean.
**Approved**: pending

**Decision**: Do not validate that `side` is one of the expected values (`'left'` or `'right'`).
**Rationale**: Passing an invalid value renders a class like `lp-bleed--invalid` as-is (see **side-passthrough**). This delegates validation to the caller and keeps the component simple; TypeScript's `'left' | 'right'` type covers the supported surface, and a value outside it means the caller has bypassed the type.
**Approved**: pending

**Decision**: Assume Bleed is rendered inside a container with `overflow-x: clip` (e.g. `.lp-band`, see the `Band` ingredient).
**Rationale**: Without that ancestor clipping, the overhang widens the document instead of appearing cropped, defeating the visual intent; enforcing it inside Bleed itself is not possible without coupling Bleed to a specific parent component.
**Approved**: pending

