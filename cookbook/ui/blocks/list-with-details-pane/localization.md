
| String Key | Default (en) | Context |
|---|---|---|
| `list-with-details-pane.empty-detail` | Select a row to see details. | Details pane when 0 rows are selected (`emptyDetail`'s default) |
| `list-with-details-pane.multi-select-hint` | Select a single row to see details. | Details pane when more than 1 row is selected; hard-coded in this source with no override prop |
| `list-with-details-pane.details-label` | Details | Default title on the details pane's header-bar divider (`detailsLabel`'s default) |
| `list-with-details-pane.filter-placeholder` | Filter… | Default placeholder in the filter `Input` (`filterPlaceholder`'s default) |

`emptyDetail`, `detailsLabel`, and `filterPlaceholder` are all
prop-overridable, so a caller can already pass localized text through them;
only the multi-select hint has no such override and is hard-coded in the
source. None of the four go through a formal localization-key lookup inside
the component itself. Separately, the default `filterRow`'s case-insensitive
match (see **filter-rows**) uses `.toLowerCase()`, which is locale-sensitive
(e.g. Turkish `İ`/`i`); a caller matching locale-specific text should supply
its own `filterRow` using a locale-aware comparison rather than assume
invariant casing.

