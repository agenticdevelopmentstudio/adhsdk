
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| FocusedTopicDetail block | [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) | The master/detail layout (topic list + detail panel) every route composes | yes | `topics`, `paneOwnedActions` |
| OptionMenu | [adhsdk.ingredient.ui.components.inputs.option-menu](cookbook:4d0e04ff-39eb-472c-93a0-8070f1b64a6a) | The selector popup that switches focus and hosts the New action | yes | radio entities + All + trailing New item |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | Step-1 warning alert + step-2 type-to-confirm delete dialog | yes | destructive; `Entity`/`rdid`/`childEntities` params |
| Disclosure | [adhsdk.ingredient.ui.components.layout.disclosure](cookbook:c99e2822-f5a9-4e84-8740-9341880bb82a) | The collapsible Danger Zone in the entity pane | yes | collapsed default; apt-red accent only when open |
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | The All view "list" render mode (one row per entity) | yes | name + identifier + key meta columns |
| ResizableSplit | [adhsdk.ingredient.ui.components.layout.resizable-split](cookbook:c21473ee-a075-4800-96db-ff3de0888515) | Optional split layout within a topic's detail panel | no | as needed per topic |

