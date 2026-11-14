
A configurable list/table component combining a button bar (with search, text filters, and facet menus), a data table (with sortable and resizable columns), row selection via checkboxes, and an optional details pane for viewing one selected row in full. Rows do not carry their own action buttons; actions operate on the selection and are supplied via the bar. The component never paginates; the full matching set is on screen and scrolls.

"Editable" names what the list is *for*, not a per-cell edit mode the component itself provides: the bar's actions mutate the underlying data by acting on the selection, and the underlying `DataTable` cells are built to stay usable as inline-editable controls (a column's own `render` can put an input, a select, or a button in a cell without that click stealing the row's selection — see `data-table.tsx`'s `fromCellControl` guard) if the caller's column wants one. No row carries a built-in edit control of its own.

