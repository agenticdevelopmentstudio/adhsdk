
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| selection (`Set<string>`) | ListWithDetailsPane | DataTable, toolbar action + Delete buttons, URL parameter | Down & Up | Component state + prop drilling + `history.replaceState` (when `paramKey` provided) |
| filterText | Caller (controlled) or internal state | Row filter → DataTable | Down | Controlled prop `filterText`/`onFilterTextChange` or internal state |
| rows (`T[]`) | Caller | DataTable, details pane, stale-link pruning | Down | Prop |
| deleteConfirm open | ListWithDetailsPane | AlertAndDialog (AlertModal) | Down | Boolean state |
| selectedIds on delete | ListWithDetailsPane | Caller `onDelete` | Up | Callback |
| split bar position | ResizableSplit (forwarded `storageKey`) | localStorage | Persisted | `ResizableSplit` owns the read/write itself; ListWithDetailsPane only forwards `storageKey` |
| column widths | DataTable (forwarded `columnWidthsKey`) | localStorage | Persisted | `DataTable` owns the read/write itself; ListWithDetailsPane only forwards `columnWidthsKey` |

