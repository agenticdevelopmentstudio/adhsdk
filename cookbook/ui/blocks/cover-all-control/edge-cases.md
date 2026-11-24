
- **Both disabled**: A stack in which every list is covered and none of the covers can be lifted by a click (the host sets `canCollapse` false because nothing is open, and `canExpand` false because the covers are width pressure) shows both halves disabled, still in place. See ca-006.
- **Both enabled**: A mixed stack, where some lists are covered and some are open, enables both halves.
- **Disabled activation**: A disabled button cannot be activated, so a stray click does nothing. See ca-005.
- **Rapid activation**: Each activation of an enabled half calls its callback once; the control does not debounce, and the host's flags decide whether the next click is still possible.
- **Narrow layout**: The host does not render the control at all in its narrow layout (test: "is not in the narrow layout"); the control has no narrow-width behavior of its own.
- **Missing callbacks or flags**: All four props are required; the source does not default any of them.
- **Concurrent access**: Not applicable: the control is a synchronous render of props and holds no shared mutable state.
- **Error states and offline**: Not applicable: the control makes no network or storage calls.

