
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `button.cancel` | "Cancel" | Cancel button label |
| `button.save` | "Save" | Save button label (default state) |
| `button.saving` | "Saving…" | Save button label while async operation is in progress |
| `button.close` | "Close" | Close button aria-label |
| `error.createFailed` | "Failed to create." | Fallback error message when `create` throws a non-`Error` value |

All five strings above are hardcoded literals in the component's source, not read from a localization resource; the `String Key` column is this recipe's proposed externalization scheme, not the source's current behavior — an implementation that must localize them needs to introduce a resource lookup itself. The `heading` prop is application-provided and not localized by the component.

