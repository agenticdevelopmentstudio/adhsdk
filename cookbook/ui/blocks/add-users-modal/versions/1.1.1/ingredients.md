
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | Growing table of staged `DraftUser` rows | yes | columns Name · Email · Phone · Admin note; selection; empty label |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | The modal `Dialog` shell (`DialogContent max-w-2xl`) + the discard-confirm `UnsavedChangesAlert` | yes | modal semantics; discard-confirm copy |

Composed shared primitives without their own recipe domains: `Input` and `Field`
(the entry row inputs) and `Button` (entry Add + footer Cancel/Add).

