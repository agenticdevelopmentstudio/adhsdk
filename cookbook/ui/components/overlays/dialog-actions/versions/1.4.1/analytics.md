
Not applicable: `DialogActions` is a presentational footer. No analytics events are fired by the component itself. Event tracking for the action's outcome (success/error) belongs in the host's `onConfirm` and `onCancel` handlers, not in the component.

