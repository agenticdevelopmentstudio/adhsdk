
**Decision**: The name and value sit together on one line from the left, with the bar beneath, instead of a label column beside the bar.
**Rationale**: The source comment explains that long names are the norm (paths, referrers, hostnames), and a label column would leave them truncated to nothing or crowding the bars out at phone width.
**Approved**: pending

**Decision**: Long names wrap, breaking inside a word, and rows past `maxItems` open in place rather than being cut or paged.
**Rationale**: The source comment states that "Nothing is hidden for good: a long name wraps, and the rows past the limit open in place"; the test "lets a long name wrap rather than cutting it off" asserts the name is not truncated.
**Approved**: pending

**Decision**: The bar length uses the maximum over all items, not over the shown items.
**Rationale**: The maximum is computed from `items` before the limit is applied, so expanding the list never rescales the rows already on screen. The source does not state a rationale in a comment; this follows from where the maximum is computed.
**Approved**: pending

**Decision**: A bar for a positive value has a 2px floor.
**Rationale**: The fill carries `minWidth: 2` when the value is greater than zero, so a very small value stays visible; the source gives no comment, and a zero value deliberately gets none.
**Approved**: pending

**Decision**: The component owns the expanded flag but not the selection.
**Rationale**: Selection is passed in (`selected`) and reported out (`onSelect`) so the host controls it, while the overflow toggle is purely local presentation. A consequence worth noting as technical debt: the expanded flag survives a change of `items`, as documented under Edge Cases.
**Approved**: pending

