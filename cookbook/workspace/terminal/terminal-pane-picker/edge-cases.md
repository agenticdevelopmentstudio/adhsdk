
- **Host window gone at begin (MUST)**: The picker finishes at once without a panel.
- **Click on a pane not in the host window (MUST)**: Panes whose view is not in the host window are skipped.
- **Pane with an unloaded view (MUST)**: Skipped, because only loaded views are tested.
- **Overlapping panes (MUST)**: The first offered pane whose bounds contain the point wins.
- **Click outside every pane (MUST)**: Consumed and ignored; the picker keeps waiting.
- **Cancel after finish (MUST)**: Calls no callback, because both callbacks were cleared; the cleanup steps run again with nothing left to remove.
- **Picker owner discards it early (MUST)**: Calling cancel ends the pick, removes the monitor and outline and takes the panel down.
- **Concurrent access**: The picker is main-actor isolated and its monitor handler runs on the main thread; no other concurrency is defined.
- **Offline or disconnected state**: Not applicable: the picker is in-process and uses no network.
- **Null and empty input**: An empty list of panes means every click is ignored.
- **Boundary values**: Not applicable: no numeric input beyond fixed panel and outline sizes.

