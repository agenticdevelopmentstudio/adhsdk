
A modal dialog that displays the real-time progress of a batch operation. It shows a progress bar, the current item being processed, a log of completed items, and handles error states by halting the operation and offering the user a choice to continue or stop. The modal does not close itself—the host owns the operation loop and decides when to dismiss. The modal cannot be dismissed mid-run, preventing accidental loss of visibility into background operations.

| Prop | Type | Required | Default |
|------|------|----------|---------|
| `open` | `boolean` | required | — |
| `title` | `React.ReactNode` | required | — |
| `description` | `React.ReactNode` | optional | — |
| `done` | `number` | required | — |
| `total` | `number` | required | — |
| `currentLabel` | `React.ReactNode` | optional | — |
| `error` | `ProgressError \| null` | optional | `null` |
| `finished` | `boolean` | optional | `false` |
| `onContinue` | `() => void` | optional | — |
| `onStop` | `() => void` | optional | — |
| `onClose` | `() => void` | optional | — |
| `results` | `ReadonlyArray<ProgressResult>` | optional | `[]` |
| `okLabel` | `React.ReactNode` | optional | `"done"` |
| `failedLabel` | `React.ReactNode` | optional | `"failed"` |

### Types

`ProgressError` (the `error` prop):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | `string` | required | The failure message shown in the error block. |
| `itemLabel` | `React.ReactNode` | optional | The item that failed, shown above the message. |

`ProgressResult` (each entry of `results`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `string` | required | Stable key for the log row. |
| `label` | `React.ReactNode` | required | How the operator refers to the item (an email, a name), not a uuid. |
| `status` | `"ok" \| "failed"` | required | Selects the muted or `apt-red` rendering. |
| `message` | `string` | optional | Replaces `okLabel` or `failedLabel` for this row. |

