
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

