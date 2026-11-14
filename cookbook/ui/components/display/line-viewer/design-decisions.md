
**Decision**: One fixed row height and Core Text drawing of only the dirty rows, rather than an `NSTableView` or a TextKit text view.
**Rationale**: Row geometry is then arithmetic, so hit testing, folding and scroll sync need no layout pass, and the cost of a frame is bounded by the visible rows however long the file is.
**Approved**: pending

**Decision**: The document width grows to the widest row drawn so far instead of measuring every row up front.
**Rationale**: Measuring every row would ask the data source for all of them, which is exactly what virtualisation avoids; growing on demand keeps horizontal scrolling correct for everything the reader has seen.
**Approved**: pending

**Decision**: A row longer than 1 024 UTF-16 units is laid out only where the dirty rect crosses it, mapping UTF-16 units to monospaced columns, rather than caching a whole-line `CTLine` per row.
**Rationale**: A cached line still draws every glyph of a 1 MB minified line on each frame; slicing bounds a frame by the rect's width. The cost is that a long line with tabs, wide or combining characters drifts from its true layout, which short lines (laid out whole) never do.
**Approved**: pending

**Decision**: The gutter is a subview of the document view kept at the clip view's horizontal origin, not drawn in each row.
**Rationale**: Side-by-side diff needs line numbers visible while long lines scroll sideways; a subview moved on bounds change keeps vertical scrolling free (it scrolls with the rows) and lets the text draw under it.
**Approved**: pending

**Decision**: Folds are held as data-source ranges and cleared by `reloadData()`.
**Rationale**: After a reload the rows may have moved, so an old fold range could hide the wrong lines; the views that reload know what changed and can fold again.
**Approved**: pending

