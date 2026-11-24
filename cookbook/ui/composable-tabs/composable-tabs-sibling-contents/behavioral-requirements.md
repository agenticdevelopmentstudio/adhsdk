
- **find-enclosing-pane**: `tabPanes()` MUST locate the nearest ancestor of the view controller, starting from its parent, that is a pane view controller.
- **empty-outside-pane**: `tabPanes()` MUST return an empty array when no ancestor of the view controller is a pane view controller.
- **empty-without-split-host**: `tabPanes()` MUST return an empty array when the enclosing pane's host is not a composable tabs split view controller.
- **empty-without-root-split**: `tabPanes()` MUST return an empty array when the host split's `rootSplit()` returns nothing. In source `rootSplit()` starts from the host split itself and climbs `enclosingSplit` until the split marked `isRoot` or a split with no enclosing split, so it returns a split in every case and this guard is defensive.
- **panes-from-root-in-reading-order**: `tabPanes()` MUST return every pane of the tab, found from the tab's root split in depth-first order, which is the order the user reads the panes in.
- **include-own-pane**: The array from `tabPanes()` MUST include the pane that holds the calling view controller.
- **answer-for-current-layout**: `tabPanes()` MUST be computed from the layout at the time of the call and MUST NOT be cached between calls.
- **contents-of-every-pane**: `tabPaneContents()` MUST return the content view controller of each pane returned by `tabPanes()`, in the same order.
- **omit-panes-without-content**: `tabPaneContents()` MUST omit a pane that has no content view controller, rather than leaving a placeholder.
- **contents-empty-outside-pane**: `tabPaneContents()` MUST return an empty array whenever `tabPanes()` does.

