
- **Content taller than the visible area** (MUST): Behaves as any document view; the flip changes nothing but the origin.
- **Content added after creation** (MUST): Stays at the top; the view's flip is fixed.
- **Subviews with their own flip** (SHOULD): A subview's coordinates are its own; only the document's origin is changed.
- **Resizing the window** (MUST): The slack below the content grows and shrinks; the content does not move.
- **Concurrent access**: Not applicable: no state.
- **Network or offline state**: Not applicable.

