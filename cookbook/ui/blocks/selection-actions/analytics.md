
- **action.clicked**: When the user clicks any action button, the parent application MAY emit an analytics event naming the action and selection state. Selection Actions does not emit events internally.
- **delete.initiated**: When the Delete button is clicked, the confirmation modal appears. The component exposes no callback for this, so the parent cannot observe it; it is unobservable unless a future `onDeleteRequest` prop is added.
- **delete.confirmed**: When the user confirms deletion in the modal, the parent application MAY emit an event after `onDelete` is called.
- **delete.cancelled**: When the user cancels the delete confirmation, the component exposes no callback for this, so the parent cannot observe it; it is unobservable unless a future `onDeleteCancel` prop is added.

Analytics implementation is the responsibility of the parent application and action handlers; Selection Actions provides no built-in analytics.

