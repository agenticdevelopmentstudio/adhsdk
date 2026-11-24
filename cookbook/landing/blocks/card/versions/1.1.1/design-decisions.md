
**Decision**: Kicker renders as a `<span>`, not a `<div>`.
**Rationale**: The kicker is a small inline label, so `<span>` is more semantic than `<div>` and does not start a new block-level section.
**Approved**: pending

**Decision**: Title always renders as `<h3>` (see **render-title**), and the component exposes no way to change the heading level.
**Rationale**: Card title is a tertiary heading (after page and section titles); consumers place the card where an `<h3>` fits in the document's heading hierarchy rather than the component adapting to a different level.
**Approved**: pending

**Decision**: Kicker is omitted entirely when `undefined`, not rendered with empty content.
**Rationale**: This avoids empty DOM nodes and simplifies CSS selectors; the conditional `{kicker === undefined ? null : ...}` ensures no render when absent.
**Approved**: pending

**Decision**: No styling concerns (colors, padding, font sizes, shadows, borders) live in the component; they are delegated to the `lp-card` and `lp-card__kicker` CSS classes.
**Rationale**: This keeps the component focused on structure and props, making it reusable across design systems.
**Approved**: pending

**Decision**: Children render directly, with no wrapper and no assumptions about content type.
**Rationale**: This maximizes flexibility; consumers control the layout and styling of prose, images, or other content.
**Approved**: pending

