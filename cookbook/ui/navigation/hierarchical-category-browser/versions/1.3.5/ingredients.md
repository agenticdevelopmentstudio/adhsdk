
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Category Picker | [adhsdk.ingredient.ui.blocks.category-picker-dialog](cookbook:88d69611-4a12-4777-9509-8af6c0626dc7) | The dialog behind BOTH place-picking gear actions — browses the folded forest and returns a place to file the selected category under. | yes | Move: `confirmLabel="Move"`, `allowRoot`, `rootLabel` = "Top level" or "Remove from “<parent>”" (see #integration-requirements/not-call-an-unfiling-a-rooting), `disabledIds` = the moved category + its own descendants. Also file: `confirmLabel="File"`, `initialSelectedId={null}`, NO `allowRoot` (a root is a category with no parents, so there is nothing to add), `disabledIds` = the category + its descendants + every parent it is ALREADY filed under. |

The other three gear dialogs (Rename, Delete, and the one-field Add) are plain
compositions of the shared `Dialog`/`Input`/`DialogActions`/`AlertModal`
primitives with no dedicated recipe of their own — see
[adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1),
Dialog Actions ([adhsdk.ingredient.ui.components.overlays.dialog-actions](cookbook:f679a77e-04f7-4e43-b898-6d78a637a760)) and
Alert and Dialog ([adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500)) for those.
`useCategoryLevels` wires all four; this recipe documents the whole.

