
| State | Appearance change | When |
|-------|------------------|------|
| Default | Combobox and chooser inputs are editable, breadcrumbs (if any) are static or interactive buttons. | Initial state when `disabled={false}` and no value or hierarchy conditions inhibit interactivity. |
| Disabled | Combobox and chooser are disabled (grayed out, non-interactive), breadcrumbs render as static text spans. | When `disabled={true}`. |
| No value | Breadcrumb section is hidden; combobox and chooser remain visible and interactive. | When `value === ""`. |
| No hierarchy | Breadcrumb section is hidden even if `value` is set; combobox and chooser are visible. | When `nodes` is omitted or empty. |
| Renaming | CategoryRenameDialog modal is open and centered over the component; combobox and chooser remain visible but input is not focused. | When user clicks a breadcrumb button and `onRename` is defined. |
| Rename success | Dialog closes; breadcrumbs update if the renamed node was selected, and `value` follows the new name via `onChange` (see **rename-follows-selected**). | After the `onRename` callback resolves successfully. |
| Rename error | Dialog behavior on a rejected rename is CategoryRenameDialog's own — see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3). CategoryField's `value` does not change. | When `onRename` callback rejects or throws. |
| Multi-path | Multiple breadcrumb trails are displayed vertically. | When the selected category node has multiple parents in the hierarchy. |

