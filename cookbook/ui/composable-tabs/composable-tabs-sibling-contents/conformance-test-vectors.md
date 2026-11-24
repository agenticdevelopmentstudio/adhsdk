
No test beside the source exercises `tabPanes()` or `tabPaneContents()` (the test bundles contain no reference to either), so these vectors are derived from the source's behavior and its doc comments; each states a hierarchy in which a view controller sits.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tab-sibling-contents-001 | find-enclosing-pane, include-own-pane, panes-from-root-in-reading-order | A tab whose root split holds panes A and B; a content view controller inside pane A calls `tabPanes()` | The result is A then B, and includes A |
| tab-sibling-contents-002 | panes-from-root-in-reading-order | A root split holding pane A and a nested split holding panes B and C; content in pane C calls `tabPanes()` | The result is A, B, C |
| tab-sibling-contents-003 | empty-outside-pane | A view controller with no pane ancestor calls `tabPanes()` | The result is empty |
| tab-sibling-contents-004 | empty-without-split-host | A view controller inside a pane whose host is not a composable tabs split view controller calls `tabPanes()` | The result is empty |
| tab-sibling-contents-005 | empty-without-root-split | A view controller inside a pane whose host split's `rootSplit()` returns nothing (a guard that the source's `rootSplit()` never trips, since it always returns the walked split) calls `tabPanes()` | The result is empty |
| tab-sibling-contents-006 | answer-for-current-layout | Call `tabPanes()` from content in pane A of a two-pane tab, add pane C, call it again | The first result has two panes and the second has three, including C |
| tab-sibling-contents-007 | answer-for-current-layout | From the three-pane tab, close pane B and call again | The result has two panes and omits B |
| tab-sibling-contents-008 | contents-of-every-pane | Panes A and B hold content view controllers X and Y; X calls `tabPaneContents()` | The result is X then Y |
| tab-sibling-contents-009 | omit-panes-without-content | Panes A, B and C where B has no content view controller; content in A calls `tabPaneContents()` | The result has the contents of A and C only |
| tab-sibling-contents-010 | contents-empty-outside-pane | A view controller with no pane ancestor calls `tabPaneContents()` | The result is empty |
| tab-sibling-contents-011 | find-enclosing-pane | Content nested several view controllers deep inside pane B calls `tabPanes()` | The result is the same as for content directly in B |

