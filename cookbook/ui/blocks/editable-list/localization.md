
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| search.placeholder | "Filter" | Placeholder for search input (from `searchPlaceholder` prop) |
| search.aria-label | "Filter [ariaLabel]" | Accessibility label for search input |
| empty.no-filter | "Nothing here." | Message when list is empty with no active filter |
| empty.filtered | "Nothing matches these filters." | Message when list is empty due to active filters |
| selection.count | "{count} selected" | Selection count button text |
| selection.hidden | "({count} not shown)" | Hidden selection count (appended in the accent color) |
| selection.clear | "Clear selection" | Screen-reader label for clear-selection button |
| table.error | "Couldn't load {ariaLabel}" | Error alert title (default, overridable via `errorTitle` prop) |
| table.error.with-rows | "{message} — showing the last rows that loaded." | Error alert description when rows exist; a single template so a locale can reorder the message |
| table.select-all | "Select all" | Accessible label of the header checkbox; hardcoded in `DataTable` |
| table.empty | "No items." | `DataTable`'s own default empty text; `EditableList` always overrides it with `emptyLabel` or `emptyFilteredLabel` |
| table.resize-column | "Resize column {key}" | Accessible label of a column's resize handle; hardcoded in `DataTable` |
| details.label | "Details" | Default label for details pane header |
| details.empty | "Select a row to see its details." | Message when details pane has no selection |
| details.many | "Select a single row to see its details." | Message when details pane has multiple selections |
| button-bar.aria-label | "{ariaLabel} actions" | Accessibility label for button bar |

All text defaults are passed as component props; externalization depends on the application's localization strategy.

The `ariaLabel.toLowerCase()` call used to build both `search.aria-label` and the default `table.error` title is a locale-sensitive casing transform: JavaScript's `String.prototype.toLowerCase()` applies the Unicode default case-folding, which is wrong for some locales (Turkish's dotted/dotless I is the standard example). A localization pass should give this a locale-aware lowercasing path rather than assume the default transform is correct everywhere — and it must not reach for an invariant-culture call either, since this text is user-facing, not an internal key.

