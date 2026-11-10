
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | "Delete" | Delete button label |
| (none — hardcoded) | "Delete selected?" | Default confirmation modal title, used when `deleteConfirm` is not provided |
| (none — hardcoded) | "Cancel" | Confirmation modal cancel button label |

None of these three strings can be overridden by the caller. `deleteConfirm` only replaces the modal's `title` and `description`; the Delete button's own label and the modal's Cancel/Confirm labels have no override point in the component's props. Localizing them today requires forking the component; the parent application is not able to localize them through configuration alone.

