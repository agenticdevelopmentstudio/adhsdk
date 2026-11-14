
- **Role**: The h3 heading establishes document structure for the preview metadata.
- **Heading level**: Fixed at `h3` rather than exposed as a prop. This is correct because the header is always rendered exactly once, in the same position, by the preview dock (the single metadata header for the selected hit — see Overview) — it never appears at a variable depth in the document outline, so no configurable heading level is needed.
- **Title attribute**: h3 `title` attribute contains the raw title text (see **title-attribute**) to support tooltip display.
- **Link semantics**: "View full paper" is a native anchor element and is keyboard accessible.
- **Focus management**: Link uses focus-visible for keyboard-only focus styling (ring appears on keyboard navigation, not on click).
- **Text alternatives**: All text is visible; no icons without labels.
- **Color not sole differentiator**: Author and metadata distinguished by text weight and position, not color alone.

