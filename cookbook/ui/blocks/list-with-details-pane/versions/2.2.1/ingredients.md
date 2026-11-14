
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | Renders filtered, multi-select rows | yes | `columns`, `rows`, `getRowId`, selection, `loading`, `emptyLabel`, `autoSizeColumns`, `columnWidthsKey`, `reorder` |
| ListHeader | [adhsdk.ingredient.ui.blocks.list-header](cookbook:a8f66760-7db0-4a10-927e-856c2170dd4f) | The filter + actions bar above the table | yes | `search` from `filterText`/`onFilterTextChange`; `actions` from `actions` + Delete |
| ResizableSplit | [adhsdk.ingredient.ui.components.layout.resizable-split](cookbook:c21473ee-a075-4800-96db-ff3de0888515) | Top/bottom split: table on top, details below its header-bar divider (`header={detailsLabel}`) | yes | `storageKey` forwarded from props; persists split bar position |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | Destructive confirm shown before delete | yes | `destructive` tone; copy from `deleteConfirm` |

Composed shared primitives without their own recipe domains: `Button` (toolbar
actions + Delete), `Input` (filter box), and `Separator` (`dividerBefore`).

The `ingredients` domains above point at other `recipes/*`, not at
`ingredients/*`, and that is intentional here: `ListWithDetailsPane` is a
block composed from other blocks/recipes (`ListHeader`, `DataTable`,
`ResizableSplit`, `AlertAndDialog`) rather than from primitive ingredients
directly, so its Ingredients table names the recipes it wires together.

