
- **Empty pillars array**: When `pillars` is provided but has zero length, the entire pillars section does not render (conditional on `length > 0`).
- **Undefined pillars**: When `pillars` prop is undefined, no pillar rendering occurs and no error is thrown; this is the normal state for a leaf site (see Design Decisions).
- **Missing navigation**: When both `back` and `next` are undefined (e.g., a single-stop tour or an isolated view), the navigation container still renders but contains no links.
- **Out-of-range position values**: The component does not validate `position.step` or `position.total` (for example `step` less than 1, `step` greater than `total`, a non-integer, or `total` less than or equal to 0); it renders whatever the format string produces (e.g., "Step 0 of 3") without throwing or clamping.
- **Block-level promise content**: Because `promise` renders inside a `<p>` element, passing block-level content (a heading, a `<div>`, etc.) produces invalid HTML nesting; callers should limit `promise` to phrasing content such as text, `<strong>`, `<em>`, or inline fragments.
- **Single instance per page**: The `id="tour"` on the root `Screen` is hardcoded, not exposed as a prop, so only one Tour Strip should render per page; a second instance would produce a duplicate DOM id.
- **Long eyebrow text**: No maximum length is enforced in the component; rendering and wrapping behavior are determined by CSS styling.
- **Long step labels**: Navigation label text length is not constrained; truncation or wrapping is controlled by CSS.
- **Long note text**: Optional note text has no length limit; layout behavior defers to CSS styling for the `<em>` element.
- **Complex promise content**: The `promise` prop accepts any React node; nested components, fragments, or HTML elements render as provided by the caller.
- **Pillar with missing fields**: If a pillar object lacks `title` or `body`, or either is empty string, those fields render as-is (no fallback text or placeholder).

