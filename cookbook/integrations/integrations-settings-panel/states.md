
| State | Appearance change |
|-------|------------------|
| Empty (Gmail not configured and not picked) | The sidebar lists no rows, the remove button is disabled, and no detail is selected. |
| Gmail picked, not yet configured | The sidebar lists the "Gmail" row, which is selected; the remove button is enabled; the detail is the Gmail settings view, whose OAuth client form is shown. |
| Gmail configured | The sidebar lists the "Gmail" row, which is selected; the remove button is enabled. This holds with or without a pick. |
| Add menu open | A menu with one "Gmail" item is shown under the add button; the item is disabled while Gmail is listed. |
| Remove confirmation open | A destructive confirmation sheet is attached to the window with Cancel as the default. |
| Provider not yet loaded | Gmail is listed only if it was picked; the panel treats the unknown state as configured when removing. |
| Pressed, Focused, Loading | Not applicable: the panel has no state of its own for them; button pressed and focus appearance belong to the shared footer, and loading belongs to the Gmail settings view and model. |
| Disabled | Only the remove button and the "Gmail" menu item disable, as above; the panel as a whole is never disabled. |

