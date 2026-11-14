
| State | Appearance change |
|-------|------------------|
| Default | Form is empty (pristine), Save button is disabled, no error message visible |
| Dirty | Form has been edited, Save button is enabled (unless saveEnabled returns false), no error message |
| Focused | Keyboard focus is visible on any interactive control (button, form field) |
| Validating (implied) | User clicked Save; inline validation runs synchronously before async operation |
| Saving | Both Cancel and Save buttons are disabled; Save button text changes to "Saving…" |
| Error | `error` is set and passed into `renderForm`, which is responsible for displaying it; Cancel and Save return to their normal enabled state (Save gated by `canSave`) once saving completes, since only the `saving` flag disables them |
| Confirming | UnsavedChangesAlert is displayed as a sibling overlay; dialog remains visible but interaction is focused on the alert |
| Server-side (implied) | Component returns null when document is undefined (SSR context) |

