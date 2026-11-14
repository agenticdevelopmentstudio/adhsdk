
- **Null/empty input** (MUST): an empty `text` leaves an empty label and sets the window's `title` to empty; a nil `icon` hides the icon.
- **Boundary values** (MUST): a window narrower than 160 points clamps the width to 0, so the title is not visible (see `width-never-negative`).
- **Very long title** (MUST): the title truncates at its tail, since its width is capped by the window (see `width-capped-by-window`).
- **Text set before installation** (MUST): there is no window to mirror to, and the first install carries the text across (see `text-before-install`).
- **Installed twice** (MAY): the source does not guard; each install adds the controller as an accessory again and registers another observer, and only the last observer is released on deallocation. Callers should install once.
- **Concurrent access** (MUST): confined to the main thread.
- **Window narrower than reserved width** (MUST): no handling beyond the clamp to 0; the source does not hide the accessory or re-flow it.
- **Error states**: Not applicable: no I/O or throwing operation.
- **Offline/disconnected state**: Not applicable: no networking.

