
- **Null/empty input** (MUST): a nil shelf produces a content-only window and every shelf operation is inert (see `shelf-optional`, `set-visible-no-shelf`, `adopt-no-shelf`). On a shelfless window a visibility request never runs its completion, so a caller waiting on one waits forever; callers check has-shelf first.
- **Boundary values** (MUST): the shelf is clamped to 180 through 480 points; a persisted width outside that range is clamped when opening by slide (see `open-width-clamped`), but the width requested at first construction is the raw persisted value and the pane's own bounds then constrain it. A width below 180 is never persisted.
- **View not in a window** (MUST): visibility changes apply without animation (see `no-window-immediate`).
- **Concurrent access** (MUST): confined to the UI thread; the only re-entrancy is a second toggle mid-slide, which lands the first slide and drops its completion (see `opposite-supersedes`), and a drag during a slide, which is ignored for callbacks (see `slide-owns-callbacks`).
- **First uncollapse after a collapsed launch** (MUST): uncollapsing can grow the window by the shelf's remembered width; the component puts the window frame back (see `slide-in-window-frame`).
- **Slide against a pane at its minimum** (MUST): the window width is held for the slide so the window does not widen to satisfy the walked width; what cannot fit is the shelf's width or a pane share (see `slide-window-width-hold`).
- **Adoption during a slide** (SHOULD): nothing in the component lands a slide in flight before adopting a layout; the source assigns that to the caller through the land-slide operation.
- **Error states** (dependency/network failure): Not applicable: the source performs no I/O beyond reading and writing two user settings and throws nothing.
- **Offline/disconnected state**: Not applicable: no networking exists in this file.

