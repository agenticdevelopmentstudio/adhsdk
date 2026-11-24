
No logging. `DialogActions` is a presentational footer; success/error telemetry
belongs to the host's `onConfirm`/`onCancel` handlers, not to the component.

