
- **Empty input**: If the input rows array is empty, `flattenTree()` returns an empty array.
- **Single root, no children**: Input is a single row with no parent; output is a single TreeRow at depth 0 with hasChildren=false.
- **Null or undefined parentId**: If `parentId()` returns null or undefined for any row, that row is treated as a root.
- **Duplicate IDs**: `id()` MUST return a unique value per row — this is a caller precondition, not something `flattenTree()` validates. Internally, the depth-first walk tracks visited rows by id in a `reached` set: whichever row bearing a given id is walked first is added to the output, and any later row sharing that id returns early (`reached.has(key)`) and is silently omitted. It does not become an orphan — it is dropped. Do not rely on a duplicate-id row appearing anywhere in the output.
- **Very deep nesting (10+ levels)**: The algorithm MUST handle arbitrary nesting depth. At 10 levels, indent is 12.5em; at 20 levels, 25em. No depth limit is enforced.
- **Large input (1000+ rows)**: The algorithm uses a single O(n) pass to build the index and a single depth-first walk, which is linear in row count. When a `compare` function is provided, sorting each sibling group (and the roots) adds up to O(n log n) on top of that linear walk.
- **All rows are orphans**: If all rows have missing parents, all are treated as roots and rendered at depth 0.
- **Mixed cycles and valid hierarchy**: Rows in valid chains are reachable and rendered in depth-first order. Rows in cycles are detected at the end and surfaced at depth 0.
- **Expansion set does not match input**: If `expanded` Set contains IDs not in the input, they are ignored. If it omits IDs that are in the input, those rows are treated as collapsed (see **omit-collapsed-descendants**).
- **Label prop is empty string**: `TreeRowLabel` MUST still render; aria-label becomes "Expand " or "Collapse " (with trailing space).
- **TreeRowLabel with depth=0**: Indent is 0 (no padding); toggle and content align to the left edge.
- **TreeRowLabel with negative depth**: `depth` MUST be supplied by the caller as a non-negative integer — this is a precondition, not a validated input. `flattenTree()` itself never produces a negative depth, but a caller invoking `TreeRowLabel` directly with a negative value gets a negative `padding-inline-start`, which is out of contract, not handled.

