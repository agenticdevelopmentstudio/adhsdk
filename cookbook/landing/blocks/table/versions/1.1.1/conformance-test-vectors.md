
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| table-001 | caption-required, columns-prop, rows-prop | `caption="Run Results"`, `columns=["Date", "Status"]`, `rows=[["2026-09-22", "Pass"], ["2026-09-21", "Fail"]]` | Table renders with caption "Run Results" hidden from visual display and two rows of data |
| table-002 | column-headers-scoped | `columns=["Name", "Role"]` | `<thead>` contains `<tr>` with two `<th scope="col">` elements containing "Name" and "Role" respectively |
| table-003 | tbody-rows | `rows=[["Alice", "Engineer"], ["Bob", "Designer"]]` | `<tbody>` contains two `<tr>` elements, each with two `<td>` elements containing the correct data |
| table-004 | row-width-validation | `columns=["A", "B"]`, `rows=[["1", "2"], ["3"]]` (second row has 1 cell, columns has 2) | Component throws an `Error` whose message includes the row index `1`, the row's cell count `1`, and the column count `2` (the reference implementation's exact text is `Table: row 1 has 1 cells but there are 2 columns`) |
| table-005 | caption-hidden-by-default | `caption="Revenue"`, `showCaption` not provided or false | Caption element renders with `class="lp-sr-only"` |
| table-006 | visible-caption-option | `caption="Revenue"`, `showCaption={true}` | Caption element renders without `lp-sr-only` class and is visible on page |
| table-007 | scroll-container, table-class | Any valid input | Outermost div has `class="lp-table-scroll"`, inner table has `class="lp-table"` |
| table-008 | row-width-validation | `columns=["X", "Y", "Z"]`, `rows=[["1", "2", "3"]]` (row length matches) | No error is thrown; row renders correctly |
| table-009 | rows-prop | `columns=["Name", "Role"]`, `rows=[]` | `<tbody>` renders with zero `<tr>` elements; `<thead>` still renders two `<th scope="col">` headers; no error is thrown |
| table-010 | columns-prop, row-width-validation | `columns=[]`, `rows=[]` | `<thead>` renders a `<tr>` with zero `<th>` elements; `<tbody>` renders zero `<tr>` elements; no error is thrown |
| table-011 | tbody-rows | `columns=["A", "B"]`, `rows=[[null, "x"]]` | Both `<td>` elements render; the first is empty (`null` renders as no visible content), the second contains "x"; no error is thrown |
| table-012 | tbody-rows, columns-prop | `columns=["Name", <strong>Status</strong>]`, `rows=[["Alice", <span>Active</span>]]` | The header and cell render the ReactNode content as given (the `<strong>` and `<span>` elements appear in the DOM); no error is thrown |

