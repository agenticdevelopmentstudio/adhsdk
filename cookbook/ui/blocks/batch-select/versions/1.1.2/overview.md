
Batch Select provides a mode for lists to enter multi-select behavior, distinct from the default single-select interaction. The hook (`useBatchSelect`) manages the state of active (batch mode on/off) and selected row IDs, with automatic clearing of selections when the visible rows change (via page, filter, or search). The button component (`BatchSelectButton`) toggles batch mode and reflects the current state with label changes.

