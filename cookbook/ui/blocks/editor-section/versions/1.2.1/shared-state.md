
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `items` (`EditorSectionItem[]`) | Caller | TopicDetail rail (mapped to `TopicDetailItem[]`) | Down | Prop |
| `selectedId` (`string \| null`) | Caller | TopicDetail selection + editing/EmptyState choice + can* flags | Down | Prop |
| `dirty` | Caller | ButtonBar `canSave` | Down | Prop |
| `busy` | Caller | ButtonBar `saving` + Delete disablement | Down | Prop |
| `canDelete` | Caller (or derived from `selectedId`) | ButtonBar Delete enablement | Down | Prop, default `?? editing` |
| `error` | Caller | Error line under the toolbar | Down | Prop |
| selected id on row click | TopicDetail rail | Caller `onSelect(id)` | Up | Callback |
| New / Delete / Cancel / Save intents | ButtonBar | Caller `onNew` / `onDelete` / `onCancel` / `onSave` | Up | Callbacks |

