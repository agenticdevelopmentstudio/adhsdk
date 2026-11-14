
| String Key | Default (en) | Context | Notes |
|-----------|-------------|---------|-------|
| dialog.title | `Rename {noun}` | Dialog header title. Interpolated with `noun` prop. | |
| dialog.description | `This renames it everywhere it is used.` | Dialog header description. | Describes consequence of rename. |
| input.label | `New {noun} name` | Input aria-label. Interpolated with `noun` prop. | Screen reader only. |
| error.empty-name | `A {noun} needs a name.` | Validation error for empty trimmed input. Interpolated with `noun` prop. | |
| error.duplicate | `There is already a {noun} called "{nextName}".` | Validation error for duplicate name. Interpolated with `noun` and attempted name. | Case-insensitive comparison. |
| button.confirm | `Rename` | Confirm button label. | |
| button.cancel | `Cancel` | Cancel button label. | |
| error.fallback | `Could not rename the {noun}.` | Fallback error message if `onRename` rejects without an Error. Interpolated with `noun` prop. | |

