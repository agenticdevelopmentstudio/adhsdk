
- **Empty levels array**: Component MUST render without error (no columns, only toolbar and breadcrumb if provided).
- **No selection at any level**: Component renders only level 0 (frontier is 0) with all items visible. Breadcrumb shows only root label if provided.
- **Selection gap**: If `levels[0].selectedId != null` but `levels[1].selectedId == null`, frontier is level 1 and only levels 0–1 render.
- **defaultSelectedId not in items**: If a level's `defaultSelectedId` names an item not in `items`, the default is not applied and no error is raised.
- **Async item updates**: If `items` changes after a default has fired, the default does not re-fire. A manual `onSelect` can re-apply the selection.
- **Width below minDetailWidth**: If container width is less than `minDetailWidth`, detail pane shows at container width (no horizontal scroll); ancestor columns remain hidden.
- **exitGuard isDirty flip during alert**: If `exitGuard.isDirty` becomes false while the alert is shown, the alert MUST still block the pending action (the guard check happens once, not re-checked while rendering).
- **Pin state on hidden list**: A pinned-disclosed list that is later hidden by width pressure MUST remain pinned (the toggle preserves the intent); when space recovers, the list is re-disclosed.
- **Pointer exit during reveal**: If pointer leaves the menu area while a branch is revealed, the reveal MUST close and the stack MUST re-settle to the configured disclosure style on the next render.
- **Multiple levels with same defaultSelectedId**: Each level applies its own default independently; sharing the same `defaultSelectedId` is valid and not a conflict.

