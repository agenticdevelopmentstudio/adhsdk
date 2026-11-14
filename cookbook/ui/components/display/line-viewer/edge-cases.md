
- **Null / empty input**: No data source or no rows draws only the background; copy is disabled.
- **Boundary values**: A run range past the end of its row is clipped to the row; a run of zero length draws nothing. A click below the last row selects nothing. A gutter value wider than its column is left-aligned and clipped. A dirty-rect edge that falls inside a glyph, a surrogate pair or a composed sequence draws that glyph whole, clipped to the rect. A long ASCII row in a font whose ASCII glyphs are not all one column wide, or whose slice lays out wider or narrower than its columns, draws from the cached layout. A frame drawing more long rows than the cache's capacity keeps all of them until the frame ends.
- **Concurrent access**: Main actor only; the data source is asked on the main thread during drawing.
- **Error states**: None: the viewer draws whatever rows it is given.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: drawing is synchronous and bounded by the visible rows.

