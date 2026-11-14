
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `button_bar.create_label` | "New" | Label for the Create button; overridable via `actions.createLabel`. This is the only preset label the component lets a consumer replace. |
| `button_bar.cancel_label` | "Cancel" | Label for the Cancel button; hardcoded in source, not currently wired to a string key. |
| `button_bar.save_label` | "Save" | Label for the Save button when not saving; hardcoded in source, not currently wired to a string key. |
| `button_bar.saving_label` | "Saving…" | Label for the Save button while a save is in flight; hardcoded in source, not currently wired to a string key. |
| `button_bar.delete_label` | "Delete" | Label for the Delete button; hardcoded in source, not currently wired to a string key. |
| `button_bar.toolbar_label` | "Editing actions" | Default `aria-label` for the toolbar; a consumer can override the whole string via `ariaLabel`, but the source has no keyed-translation lookup for the default value itself. |

This table names the strings the component would need to externalize to be fully localizable; today only `createLabel` is an injectable prop. See the Compliance section below for the resulting `string-externalization`/`no-hardcoded-strings` status.

