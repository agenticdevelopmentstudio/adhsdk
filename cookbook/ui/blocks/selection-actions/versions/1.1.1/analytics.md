
- **action.clicked**: When the user clicks any action button, the parent application MAY emit an analytics event naming the action and selection state. Selection Actions does not emit events internally.
- **delete.initiated**: When the Delete button is clicked, the confirmation modal appears. The parent application MAY track this as an intent-to-delete event.
- **delete.confirmed**: When the user confirms deletion in the modal, the parent application MAY emit an event after `onDelete` is called.
- **delete.cancelled**: When the user cancels the delete confirmation, the parent application MAY track this if needed.

Analytics implementation is the responsibility of the parent application and action handlers; Selection Actions provides no built-in analytics.

