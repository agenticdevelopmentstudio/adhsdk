
- **caption-required**: Component MUST accept a required `caption` prop (ReactNode) that identifies the data population represented by the table rows.
- **row-width-validation**: Component MUST throw an error if any row has a length that does not match the `columns` array length, reporting the offending row index and cell counts.
- **caption-hidden-by-default**: Component MUST render the caption element and hide it from visual display by default (via `lp-sr-only` class), ensuring screen reader access to the caption.
- **visible-caption-option**: Component MUST accept an optional `showCaption` boolean prop that, when true, renders the caption visibly on the page (removing the `lp-sr-only` class).
- **column-headers-scoped**: Component MUST render a `<thead>` containing a single row of column headers, each wrapped in a `<th>` element with `scope="col"` attribute.
- **tbody-rows**: Component MUST render a `<tbody>` containing one row per entry in the `rows` prop, with each cell rendered as a `<td>` element.
- **columns-prop**: Component MUST accept a required `columns` array prop (ReactNode[]) that defines the header labels and establishes the table width.
- **rows-prop**: Component MUST accept a required `rows` array prop (ReactNode[][]) that defines the data cells, organized as rows.
- **scroll-container**: Component MUST wrap the table in a div element with class `lp-table-scroll` to enable horizontal scrolling on narrow viewports.
- **table-class**: Component MUST apply the `lp-table` class to the `<table>` element.

