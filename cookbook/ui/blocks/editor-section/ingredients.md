
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| ButtonBar | [adhsdk.ingredient.ui.blocks.button-bar](cookbook:81db83fc-b30c-4ba3-b4d5-572dc8b4e335) | The fixed editing toolbar: gold mono title (`leading`) + the New/Delete/Cancel/Save preset | yes | `leading` = title + `titleBadge`; `actions` = `{ onCreate, createLabel, onCancel, canCancel, onSave, canSave, saving, onDelete, canDelete }`; `showDelete` = `!!onDelete` |
| TopicDetail | [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) | The two-pane rail\|pane primitive: collapsible records rail + detail pane | yes | `items` (mapped from `EditorSectionItem[]`), `selectedId`, `onSelect`, `emptyLabel` = `emptyList`, `railSlot` = `listHeader`, `railWidth`, `panePadding={false}` |
| EmptyState | [adhsdk.ingredient.ui.components.display.empty-state](cookbook:e86eb195-1ec2-4b12-8a24-79f8c03f65ce) | The "nothing selected" placeholder rendered in the pane when not editing | yes | `title` = `emptyDetail`; fixed standard detail-pane inset (literal classes: see the React/Web platform note) |

Composed shared primitives without their own recipe domains: `Badge`
(`variant="accent"`) for the `⚠ N` count badge on warned rows.

