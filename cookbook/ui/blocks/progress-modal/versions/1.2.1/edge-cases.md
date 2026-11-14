
- **Empty batch**: When `total` is zero, percentage calculation produces zero instead of NaN. Progress bar renders at 0%.
- **No results**: When `results` array is empty or undefined, results log section does not render.
- **No error**: When `error` prop is null or undefined, error block does not render.
- **Missing itemLabel in error**: When `error.itemLabel` is null or undefined, only the error message renders in the error block.
- **Missing message in result**: When a result has no `message` property, the component uses `okLabel` (for "ok" status) or `failedLabel` (for "failed" status) as the displayed text.
- **Error present at finish**: When `error` is set and `finished` is also true, `finished` takes precedence — the error block and Continue/Stop buttons do not render; only Close renders (see **finished-overrides-halt**).
- **Stop action while processing**: When `onStop` is invoked, the host owns the batch loop and decides when to set `finished={true}`. The modal does not stop the underlying operation.
- **Continue after error**: When `onContinue` is invoked, the host resumes the batch loop. The `error` prop is expected to be cleared by the host in the next render.
- **Dismiss attempt mid-run**: Pressing Escape or clicking the close button while `finished={false}` is swallowed internally — the component does not call `onClose` and the modal remains open. `ProgressModal` has no host-facing `onOpenChange` prop; the swallowing happens inside the component's own wiring to the underlying `Dialog`.

