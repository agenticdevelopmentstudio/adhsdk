
| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `ariaLabel` | string | Yes | — | Accessibility label for the dialog container |
| `heading` | string | Yes | — | Dialog heading/title rendered as h2 |
| `blank` | () => TInput | Yes | — | Factory function that returns the initial pristine state for the form |
| `validate` | (draft: TInput) => string \| null | Yes | — | Validation function; returns null if valid, error message string if invalid |
| `create` | (draft: TInput) => `Promise<TResult>` | Yes | — | Async resource creation function; throws on error |
| `onClose` | () => void | Yes | — | Callback invoked when the dialog is closed without a successful create: directly via Cancel, ×, or Escape while the draft is pristine, or via Discard in the `UnsavedChangesAlert` after confirming a dirty draft. Never invoked after `onCreated` fires. |
| `onCreated` | (result: TResult) => void | Yes | — | Callback invoked when create succeeds |
| `renderForm` | (draft: TInput, onChange: (next: TInput) => void, error: string \| null) => ReactNode | Yes | — | Render function for form fields; receives draft state, onChange handler, and error message |
| `saveEnabled` | (draft: TInput) => boolean | No | undefined | Optional gate function; returns true to enable Save beyond the pristine check, false to disable |
| `onSaveError` | (err: unknown) => void | No | undefined | Optional telemetry callback invoked when create fails; the error is also displayed inline |

