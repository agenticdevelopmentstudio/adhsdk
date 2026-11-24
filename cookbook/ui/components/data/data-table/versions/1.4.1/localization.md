
Most user-facing text is caller-supplied (`ariaLabel`, `emptyLabel`, column `header`, `describeRow`), and localization of those is the caller's responsibility. The component itself also owns a small set of hardcoded English strings that have no override besides `emptyLabel`:

| String | Context |
|---|---|
| `"Select all"` | Select-all checkbox `aria-label`, shown when `showSelectionCheckboxes` is true |
| `"No items."` | Default `emptyLabel`; overridable via that prop |
| `` `row {id}` `` | Fallback row-checkbox `aria-label` when no `describeRow` is given and the row has no other non-empty string field |
| `` `Select {name}` `` | Row-checkbox `aria-label` template, `{name}` from `describeRow(row)` or the fallback above |
| `` `Resize column {key}` `` | Column resize-handle `aria-label`, built from the column `key` rather than its header text |

These literals are not routed through any localization layer; a non-English caller sees them in English regardless of locale.

