
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| targetName | string &#124; null | null | The name of the selected category row to display in action labels. When null, labels do not include a target. |
| canEditTarget | boolean | false | Whether the target-specific actions (rename, move, file, delete) are available. Controls the disabled state of four menu items. |
| noun | string | "category" | Singular, lowercase noun used in labels and trigger title. E.g., "tag", "item", "note". Capitalized in trigger label. |
| onAction | (action: "add" &#124; "rename" &#124; "move" &#124; "file" &#124; "delete") => void | (required) | Callback invoked when any menu item is clicked. Receives the action type — the `CategoryGearAction` union: "add", "rename", "move", "file", or "delete". |
| disabled | boolean | false | When true, the trigger is disabled and the menu cannot be opened. |
| className | string | undefined | Optional CSS class to apply to the trigger element (passed to GearMenuTrigger). |

