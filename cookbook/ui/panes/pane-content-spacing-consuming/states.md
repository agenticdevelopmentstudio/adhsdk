
Not applicable — the protocol is a contract, not a visual component. It has no
visual states: the gap changes only when the spacing settings change, and each
change calls `applyPaneSpacing(_:)` again (see applied-again-on-change).

