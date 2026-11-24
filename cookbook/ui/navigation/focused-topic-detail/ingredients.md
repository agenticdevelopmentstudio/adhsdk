
| Name | Ingredient | Role | Required | Configuration |
|------|--------|------|----------|---------------|
| TopicDetail | [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) | The rail and pane frame; receives the topics, the selector as `railSlot`, and `panePadding={false}` | Yes | `items`, `selectedId`, `railSlot`, `railSlotActive`, `panePadding` |
| OptionMenu | [adhsdk.ingredient.ui.components.inputs.option-menu](cookbook:4d0e04ff-39eb-472c-93a0-8070f1b64a6a) | Related selector ingredient; the block's own selector is `PopupMenu`, a radio dropdown | No | Not used by the block's source |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | A confirmation a consumer may raise from its pane content | No | Not used by the block's source |
| Disclosure | [adhsdk.ingredient.ui.components.layout.disclosure](cookbook:c99e2822-f5a9-4e84-8740-9341880bb82a) | A collapsible section a consumer may place in its pane content | No | Not used by the block's source |
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | A table a consumer may place in its pane content | No | Not used by the block's source |
| ResizableSplit | [adhsdk.ingredient.ui.components.layout.resizable-split](cookbook:c21473ee-a075-4800-96db-ff3de0888515) | A split a consumer may place in its pane content | No | Not used by the block's source |

`PopupMenu`, `SectionHeader` and `ResourceCard` are sibling blocks in the same package and are not separate ingredients here.

