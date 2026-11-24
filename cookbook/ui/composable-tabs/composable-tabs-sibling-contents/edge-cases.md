
- **Null and empty input**: A view controller with no parent MUST get an empty array from both methods. A tab with a single pane MUST return that pane alone, and its content from `tabPaneContents()`.
- **Boundary values**: A pane with no content view controller MUST be counted by `tabPanes()` but omitted by `tabPaneContents()`.
- **Calling on a pane itself**: The walk starts at the receiver's parent, so the receiver is never tested. A pane view controller that calls `tabPanes()` on itself finds a pane only if it is nested inside another pane; otherwise it gets an empty array. The doc comment promises the receiver's own pane for a view controller inside a pane, which is the content case.
- **Concurrent access**: Not applicable: the extension reads view controller state that AppKit confines to the main thread, and keeps no state of its own.
- **Error states**: Not applicable: the extension returns an empty array for every broken or missing link in the chain and throws nothing.
- **Offline or disconnected state**: Not applicable: the extension performs no network or file access.
- **Layout change between calls**: A pane added or closed between two calls MUST be reflected in the second call, because the result is rebuilt from the tree each time. A caller that holds the array holds a snapshot that can go stale.

