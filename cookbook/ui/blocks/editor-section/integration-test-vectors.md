
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | derive-editing-from-selection, show-detail-while-editing | `selectedId = null` | Pane shows the `EmptyState` titled `emptyDetail`; `children` not rendered |
| T2 | show-detail-while-editing | `selectedId = "r1"` | Pane renders `children` (the record form); no `EmptyState` |
| T3 | render-title-in-toolbar | `title="Sites"`, `titleBadge=<Badge/>` | Toolbar leading shows the gold mono title with the badge beside it |
| T4 | gate-save-on-dirty-selection | editing, `dirty=false` | Save disabled |
| T5 | gate-save-on-dirty-selection | editing, `dirty=true` | Save enabled (gold) |
| T6 | gate-cancel-on-editing | `selectedId=null` | Cancel disabled |
| T7 | default-can-delete-to-editing | editing, `canDelete` unset | Delete enabled |
| T8 | default-can-delete-to-editing | editing, `canDelete={false}` (new draft) | Delete disabled |
| T9 | disable-delete-while-busy, disable-save-while-busy, disable-cancel-while-busy, keep-new-enabled-while-busy | editing, `busy=true` | Delete disabled; Cancel disabled; Save disabled and shows "Saving…"; New remains enabled |
| T10 | omit-delete-when-no-handler | `onDelete` omitted | No Delete button rendered |
| T11 | render-warn-badge-per-row | item `{ warn:true, warnCount:5, warnTitle }` | Row trailing shows a `⚠ 5` accent Badge with `warnTitle` |
| T12 | render-warn-badge-per-row | item `{ warn:true }` (no count) | Row trailing shows a bare `⚠`; a non-warned row shows nothing |
| T13 | surface-mutation-error | `error="Save failed"` | Red error line renders under the toolbar; absent when `error` unset |
| T14 | collapse-list-header-when-collapsed | `listHeader` set, rail collapsed | `listHeader` hidden while collapsed, shown while expanded |
| T15 | default-empty-list-label | `items=[]`, `emptyList` omitted | Rail shows "Nothing here yet." (hardcoded default) |
| T16 | render-warn-badge-per-row | item `{ warn:true, warnCount:5, warnTitle:"5 project sites not yet connected" }` | The rail row's accessible name (its button content) includes `warnTitle`, contributed by the Badge's `aria-label` after the row label |
| T17 | default-can-delete-to-editing | `selectedId=null`, `canDelete={true}`, `onDelete` set | Delete enabled (the explicit value is honored) |
| T18 | forward-row-select | User selects the row with id "r2" | `onSelect("r2")` called once |
| T19 | forward-toolbar-intents | Editing, `dirty=true`, `onDelete` set; user activates New, Delete, Cancel, then Save | `onNew`, `onDelete`, `onCancel`, `onSave` each called once, in that order, and no other callback is called |
| T20 | size-rail | `railWidth={360}`, rail expanded | Rail is 360px wide; with `railWidth` omitted it is 240px |
