
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| FocusedTopicDetail block | adhsdk://recipes/topic-detail | The master/detail layout (topic list + detail panel) every route composes | yes | `topics`, `paneOwnedActions` |
| OptionMenu | adhsdk://recipes/option-menu | The selector popup that switches focus and hosts the New action | yes | radio entities + All + trailing New item |
| AlertAndDialog | adhsdk://recipes/alert-and-dialog | Step-1 warning alert + step-2 type-to-confirm delete dialog | yes | destructive; `Entity`/`rdid`/`childEntities` params |
| Disclosure | adhsdk://recipes/disclosure | The collapsible Danger Zone in the entity pane | yes | collapsed default; apt-red accent only when open |
| DataTable | adhsdk://recipes/data-table | The All view "list" render mode (one row per entity) | yes | name + identifier + key meta columns |
| ResizableSplit | adhsdk://recipes/resizable-split | Optional split layout within a topic's detail panel | no | as needed per topic |

