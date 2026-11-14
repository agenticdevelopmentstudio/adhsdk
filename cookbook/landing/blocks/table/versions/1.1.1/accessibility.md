
- **Semantic table structure**: Component uses native `<table>`, `<thead>`, `<tbody>`, `<th>`, `<td>`, and `<caption>` elements, providing structural semantics to assistive technology.
- **Column headers**: Each column header in `<th>` has `scope="col"` attribute, associating cells with their column.
- **Caption requirement**: The caption prop is required and always rendered, ensuring screen readers announce what data the table represents.
- **Caption visibility toggle**: The `showCaption` prop allows the caption to be displayed visually when the surrounding context does not already identify the table's purpose.
- **Screen reader only class**: The `lp-sr-only` class hides the caption from sighted users by default while preserving it for screen readers.

