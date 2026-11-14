
| ID | Requirements | Input | Expected |
|----|----|---|---|
| create-resource-001 | render-modal-dialog | Component is mounted | Modal dialog renders with `role="dialog"` and `aria-modal="true"` in document.body |
| create-resource-002 | render-heading | heading="New Product" | h2 element renders with text "New Product" |
| create-resource-003 | render-close-button | Component is mounted | Close button (×) is rendered in dialog header with aria-label="Close" |
| create-resource-004 | render-cancel-button | Component is mounted | Cancel button is rendered in footer |
| create-resource-005 | render-save-button | Component is mounted | Save button is rendered in footer with text "Save" |
| create-resource-006 | disable-save-when-pristine | Draft state equals blank state | Save button has disabled attribute |
| create-resource-007 | disable-save-when-pristine | User edits form (draft differs from blank) | Save button is enabled |
| create-resource-008 | validate-on-save | User clicks Save; validate returns "Name is required" | `renderForm` receives error="Name is required" as its third argument on the next render; display is renderForm's responsibility |
| create-resource-009 | prevent-save-when-invalid | User clicks Save; validate returns non-null error | Create callback is not invoked |
| create-resource-010 | invoke-create-on-save | User clicks Save; validate returns null | Create callback is invoked with current draft |
| create-resource-011 | disable-buttons-while-saving | Create callback is in progress | Both Cancel and Save buttons have disabled attribute |
| create-resource-012 | render-save-button | Create operation is in progress | Save button text is "Saving…" |
| create-resource-013 | invoke-oncreated-on-success | Create callback resolves successfully | onCreated callback is invoked with the result; UnsavedChangesAlert is not shown; the component does not close itself (closing after success, e.g. by unmounting, is left to the host) |
| create-resource-014 | display-create-error, disable-buttons-while-saving | Create callback throws Error("Network timeout") | `renderForm`'s error argument becomes "Network timeout" on the next render; `saving` flips to false, so Cancel and Save return to their normal enabled state |
| create-resource-015 | display-create-error | Create callback throws non-Error object | `renderForm`'s error argument becomes "Failed to create." |
| create-resource-016 | invoke-onsaveerror-on-create-failure | Create callback throws; onSaveError is provided | onSaveError callback is invoked with the exception |
| create-resource-017 | guard-close-on-dirty | User clicks Cancel; draft is dirty | UnsavedChangesAlert is shown; dialog is not closed |
| create-resource-018 | guard-close-on-dirty | User clicks ×; draft is pristine | Dialog closes immediately without showing alert |
| create-resource-019 | ignore-backdrop-click | User clicks overlay background | Dialog remains open |
| create-resource-020 | route-escape-through-guard | User presses Escape; draft is dirty | UnsavedChangesAlert is shown |
| create-resource-021 | route-escape-through-guard, stay-dismisses-alert | User presses Escape while alert is open | Alert is dismissed (mapped to Stay); dialog remains open |
| create-resource-022 | route-escape-through-guard | User presses Escape; draft is pristine | Dialog closes without showing alert |
| create-resource-023 | support-optional-save-gate | saveEnabled returns false | Save button is disabled even if draft is dirty |
| create-resource-024 | support-optional-save-gate | saveEnabled returns true and draft is dirty | Save button is enabled |
| create-resource-025 | render-only-on-client | Component is rendered on server (document is undefined) | Component returns null |
| create-resource-026 | discard-invokes-onclose | User clicks Discard in UnsavedChangesAlert | onClose is invoked; UnsavedChangesAlert itself is not dismissed by this click and remains visible unless the host unmounts the dialog in response to onClose |
| create-resource-027 | stay-dismisses-alert | User clicks Stay in UnsavedChangesAlert | UnsavedChangesAlert closes; dialog remains open with the draft unchanged; onClose is not invoked |
| create-resource-028 | escape-active-during-save | User presses Escape while `saving` is true and draft is dirty | UnsavedChangesAlert is shown even though Cancel and Save are currently disabled |
| create-resource-029 | render-form-content | Component is mounted with draft state, an onChange handler, and error=null | `renderForm` is invoked with `(draft, onChange, error)` in that order; its returned content renders between the header and footer |
| create-resource-030 | use-aria-label | ariaLabel="Create Product" | Dialog container element has aria-label="Create Product" |

