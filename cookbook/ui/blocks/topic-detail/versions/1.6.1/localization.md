
| String Key | Default (en) | Context |
|---|---|---|
| `emptyLabel` | "Nothing here yet." | Shown when `items` is empty |
| `newLabel` | "New" | Accessible name + tooltip for the create `+` button |
| `closeLabel` | "Close" | Accessible name + tooltip for the close button |
| `deleteConfirm` | "This action can't be undone." | Delete confirmation dialog body, per item |
| `deleteLabel` | item's `label` | Accessible name for the trash button and the dialog's subject; falls back to the item's own `label` when omitted |
| `railLabel` | "Topic list" | Accessible name for the rail's `<aside>` landmark |
| *(fixed)* | "topic list" (lowercase) | Desktop collapse toggle's `aria-label` — hardcoded literal, independent of `railLabel` |
| *(fixed)* | "Loading" | `aria-live="polite"` announcement while `busy=true` |
| *(fixed)* | ", needs attention" | Screen-reader-only suffix appended to a blocked row's accessible name |
| *(fixed)* | "Resize topic list" | Resize handle's `aria-label` |
| *(fixed)* | "Delete {label}?" | Delete confirmation dialog title template |
| *(fixed)* | "Delete {label}" | Delete button's `aria-label`/tooltip template |
| *(fixed)* | "Delete" / "Cancel" | `AlertModal`'s confirm/cancel button labels at this call site |

Six strings are overridable via props; the seven marked *(fixed)* are English literals with no override and no i18n hook — this section is `partial` (see Compliance).

