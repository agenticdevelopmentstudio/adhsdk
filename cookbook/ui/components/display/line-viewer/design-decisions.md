
**Decision**: One fixed row height and Core Text drawing of only the dirty rows, rather than an `NSTableView` or a TextKit text view.
**Rationale**: Row geometry is then arithmetic, so hit testing, folding and scroll sync need no layout pass, and the cost of a frame is bounded by the visible rows however long the file is.
**Approved**: pending

**Decision**: The document width grows to the widest row drawn so far instead of measuring every row up front.
**Rationale**: Measuring every row would ask the data source for all of them, which is exactly what virtualisation avoids; growing on demand keeps horizontal scrolling correct for everything the reader has seen.
**Approved**: pending

**Decision**: A row longer than 1 024 UTF-16 units is laid out once into a small per-row `CTLine` cache, and each draw finds the glyph range under the dirty rect (bisecting runs, then glyph origins) and draws it with `CTRunDraw(run, context, range)`, rather than laying out only a slice of the text under the rect.
**Rationale**: A cached line need not draw every glyph: `CTRunDraw` takes a glyph range, so a frame costs the glyphs under the rect plus a logarithmic search. Slicing the text instead had to map UTF-16 units to columns, so a tab, wide or combining character shifted later glyphs in one dirty rect but not the next and glyphs jumped, repeated or vanished at the seams. The cost is one whole-line layout per long row, bounded by the cache's row and unit limits.
**Approved**: pending

**Decision**: A long row that is printable ASCII in a column-true font is sliced by column with no layout cached; only other long rows use the cache, whose capacity follows the visible rows and never evicts a row of the current frame.
**Rationale**: A fixed cache of 8 rows was smaller than one screen of long rows, so every frame of a minified file rebuilt every row's whole layout. Most long lines (minified JS, JSON, logs) are ASCII, and in a font that draws every printable ASCII glyph one column wide a column is an exact position, so slicing is both cheap and seam-free; the font check and a per-slice width check keep a ligature or kerning font on the cached path. Sizing the cache from the visible height and pinning the frame's rows means a redraw of what is on screen never lays anything out again.
**Approved**: pending

**Decision**: A long row's runs are indexed once, sorted by location over a max-tree of their upper bounds, and each frame queries the index for the runs under the slice or the drawn glyphs.
**Rationale**: A syntax-highlighted minified line has around 10^5 runs; walking all of them for every visible long row on every frame cost about 10 MB allocated per row per frame. Sorting gives the end of the overlapping runs by bisection; a running maximum of upper bounds alone would let one run spanning the row (a whole-line highlight) make every query walk from it to the slice, so each tree node holds the furthest reach of the runs beneath it and whole subtrees ending before the slice are skipped. A query costs O(log n) per overlapping run. Hits are returned in the row's own order so overlapping runs resolve exactly as on the short-row path.
**Approved**: pending

**Decision**: The gutter is a subview of the document view kept at the clip view's horizontal origin, not drawn in each row.
**Rationale**: Side-by-side diff needs line numbers visible while long lines scroll sideways; a subview moved on bounds change keeps vertical scrolling free (it scrolls with the rows) and lets the text draw under it.
**Approved**: pending

**Decision**: Folds are held as data-source ranges and cleared by `reloadData()`.
**Rationale**: After a reload the rows may have moved, so an old fold range could hide the wrong lines; the views that reload know what changed and can fold again.
**Approved**: pending

