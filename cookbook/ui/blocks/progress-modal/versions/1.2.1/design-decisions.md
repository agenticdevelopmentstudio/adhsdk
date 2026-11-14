
1. **Decision**: Halt the batch on the first error and require the user to decide whether to continue or stop, rather than completing all items and presenting a summary at the end.
**Rationale**: Assumes that a failure in one item often indicates a systemic cause (e.g., a wrong destination path) that will recur for the remaining items, so continuing unattended risks repeating a preventable failure across the rest of the batch. This is a heuristic the host applies by setting `error`, not a guarantee the component enforces.
**Approved**: pending

2. **Decision**: The component does not dismiss itself on completion. Instead, it swaps the action buttons for a Close button, making the user responsible for dismissal.
**Rationale**: This preserves the record of what happened—the completed results are visible until the user explicitly closes the dialog.
**Approved**: pending

3. **Decision**: Progress is tracked as an item count (`done` / `total`), not elapsed time or bytes transferred.
**Rationale**: The host controls the loop and reports completion for each discrete operation, so an item count is an accurate fact rather than a throughput-based guess.
**Approved**: pending

4. **Decision**: The component is transport-agnostic — it renders state and emits decisions (Continue, Stop, Close) without knowing whether the batch is uploading, deleting, moving, or any other operation.
**Rationale**: Any host can drive it without specialized knowledge of the underlying operation.
**Approved**: pending

5. **Decision**: `okLabel` and `failedLabel` default to deliberately generic values ("done", "failed").
**Rationale**: The component runs any batch, so a hardcoded verb like "moved" would be a lie in a delete run. A host with domain-specific knowledge can pass a better verb.
**Approved**: pending

6. **Decision**: Escape and the × button are swallowed until the run ends (`finished` is true).
**Rationale**: Closing the dialog does not stop the background requests; a dialog that vanished on a stray keystroke would leave the batch running invisibly, losing visibility into the operation.
**Approved**: pending

