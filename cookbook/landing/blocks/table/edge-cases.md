
- **Empty columns array**: If `columns` is an empty array, the table renders with no header cells and no validation error on rows (rows must also be empty or each row must have zero cells). MUST render without error if rows are also empty; throws error if rows contain non-empty sub-arrays. See Design Decisions.
- **Empty rows array**: If `rows` is an empty array, the table renders with headers but no body rows. MUST render without error.
- **Null or undefined cells**: If a cell value is `null`, `undefined`, or a falsy ReactNode, it renders as an empty cell. MUST render without error and display the cell visually empty.
- **ReactNode content in cells**: Cells accept ReactNode values (strings, numbers, React elements, fragments). MUST render without error regardless of ReactNode type.
- **reports-first-mismatched-row**: Row-width validation checks every row in order and reports the lowest index at which a mismatch occurs; it does not assume only the first row can be invalid. MUST report the index of the first row found to be incorrect.

