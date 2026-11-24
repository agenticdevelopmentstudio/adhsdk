
- **Empty columns array**: Zero columns means every row must have zero cells. If `rows` is empty (or every row is `[]`), the table renders with no header cells and no error; if any row has cells (for example `columns=[]` with `rows=[["x"]]`), #requirements/row-width-validation throws (see #test-vectors/table-014). See Design Decisions.
- **Empty rows array**: If `rows` is an empty array, the table renders with headers but no body rows. MUST render without error.
- **Null or undefined cells**: If a cell value is `null`, `undefined`, or a falsy ReactNode, it renders as an empty cell. MUST render without error and display the cell visually empty.
- **ReactNode content in cells**: Cells accept ReactNode values (strings, numbers, React elements, fragments). MUST render without error regardless of ReactNode type.
- **Several mismatched rows**: See #requirements/reports-first-mismatched-row; only the lowest-index bad row is reported (see #test-vectors/table-013).

