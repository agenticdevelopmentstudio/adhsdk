
- **render-trigger**: Component MUST render a gear icon trigger labeled with "{Noun} actions" (noun is singular and capitalized; defaults to "Category actions").
- **render-five-items**: Component MUST render five dropdown items corresponding to the actions: "Add {noun}…", "Rename…", "Move…", "Also file in…", and "Delete…" (the bare verb forms shown when no target name is applied; see **show-target-in-labels**).
- **show-target-in-labels**: Component MUST include the target name in menu item labels when `targetName` is not null and `canEditTarget` is true. Label format is `Rename “{targetName}”…`, `Move “{targetName}”…` and `Delete “{targetName}”…` for rename, move and delete, and `Also file “{targetName}” in…` for the file action.
- **omit-target-when-not-editable**: Component MUST omit the target name from item labels when `canEditTarget` is false, even if `targetName` is not null; labels use the bare verb form ("Rename…", "Also file in…") in that case.
- **disable-target-actions-when-not-editable**: Component MUST disable the `rename`, `move`, `file` and `delete` items when `canEditTarget` is false.
- **enable-add-always**: Component MUST keep the `add` item ("Add {noun}…") enabled regardless of `canEditTarget`.
- **render-separators**: Component MUST render a visual separator (DropdownMenuSeparator) between the `add` item and the target actions, and another separator between the `file` item and the `delete` item.
- **invoke-callback-on-action**: Component MUST invoke the `onAction` callback with the action type ("add", "rename", "move", "file", or "delete" — the `CategoryGearAction` union) when a menu item is clicked.
- **respect-disabled-prop**: Component MUST render the trigger as disabled when the `disabled` prop is true.
- **style-delete-destructive**: Component MUST style the "Delete" menu item using the platform's destructive/error styling.
- **align-to-end**: Component MUST align the dropdown menu content to the trailing (end) edge of the trigger; in right-to-left layouts, the trailing edge is the left side.

