
### Structure

- **content-pane**: The component MUST host the window content in a pane whose minimum width is 300 points.
- **content-safe-area**: The component MUST lay the window content out from the top safe area, below the toolbar.
- **content-backdrop**: The component MUST paint the content pane's full area, the strip behind the titlebar included, in the theme's window background color.
- **shelf-optional**: The component MUST accept an absent shelf, and with none MUST host the content alone and report that it has no shelf.
- **shelf-leading-pane**: When a shelf is supplied, the component MUST place it in a pane on the leading side of the content pane.
- **shelf-full-height**: The component MUST give the shelf pane the window's whole height, up behind the titlebar, and MUST NOT inset the shelf from the safe area.
- **shelf-backdrop**: The component MUST paint the shelf pane's full area in the theme's project pane backdrop color.
- **theme-repaint**: The component MUST re-apply both backdrop colors whenever the active theme palette changes.
- **divider-thin**: The component MUST draw a thin divider between the panes.
- **plain-panes**: The component MUST use ordinary (non-sidebar) split items and a plain split view, because sidebar material and a themed split view's divider color reach no theme (see Design Decisions).

### Shelf geometry and persistence

- **shelf-width-bounds**: The shelf pane MUST be no narrower than 180 points and no wider than 480 points.
- **shelf-width-restored**: The component MUST ask for the shelf's opening width from the persisted shelf width (default 240 points) at a priority that any user drag beats.
- **shelf-visibility-restored**: The component MUST start with the shelf collapsed unless the persisted shelf visibility (default hidden) is true.
- **shelf-collapsible**: The shelf pane MUST be collapsible.
- **window-keeps-size**: When the shelf collapses or expands, the window MUST keep its size and the content pane MUST give up or take the room.
- **window-resize-spares-shelf**: When the window is resized, the content pane MUST absorb the change and the shelf MUST keep the width the reader gave it.
- **width-remembered-on-drag**: The component MUST persist the shelf's width whenever it changes while the shelf is visible, not sliding, and at least its minimum width.
- **width-ignored-below-minimum**: The component MUST NOT persist a shelf width below 180 points, which is what a window still being assembled reports.
- **width-ignored-while-animating**: The component MUST NOT persist the shelf's width while a collapse is in flight, so the shrinking width on the way to zero is not recorded as the reader's choice.
- **width-synced-after-drag**: After persisting a dragged width, the component MUST make that width the shelf's requested width, so the next layout pass does not pull the shelf back.
- **open-width-clamped**: The width the shelf slides open to MUST be the persisted width clamped to 180 through 480 points.

### Visibility API

- **has-shelf**: The component MUST report whether a shelf pane exists.
- **is-shelf-visible-target**: The component MUST report the shelf's visibility as the destination of a slide in flight (visible when the slide's target width is above zero), and otherwise as the inverse of the shelf pane's collapsed state.
- **no-shelf-not-visible**: With no shelf, the component MUST report the shelf as not visible.
- **toggle**: Toggling MUST request the opposite of the reported visibility.
- **set-visible-persists**: Requesting a visibility change that is not already satisfied MUST persist the new visibility at once, before any animation runs.
- **set-visible-noop**: Requesting the visibility the shelf already has, with no slide in flight, MUST change nothing and MUST run the completion at once.
- **set-visible-no-shelf**: With no shelf, a visibility request MUST do nothing, and the completion MUST NOT run.
- **same-direction-joins**: Requesting the destination a slide in flight is already heading to MUST NOT start a second slide, and the new completion MUST run after the first slide's completion when that slide lands.
- **opposite-supersedes**: Requesting the opposite destination mid-slide MUST land the slide in flight at its destination first and MUST drop that slide's completion unrun.
- **hide-resigns-focus**: Hiding the shelf MUST make the shelf give up keyboard focus before the slide begins.
- **no-window-immediate**: When the component's view is not in a window, a visibility request MUST apply the collapsed state at once with no animation, then notify the visibility callback and run the completion.
- **panel-toggle-hide**: Toggling a shelf panel while the shelf is visible and already showing that panel MUST hide the shelf.
- **panel-toggle-show**: Toggling a shelf panel otherwise MUST switch the shelf to that panel, show the shelf, and put keyboard focus in the shelf's filter once the shelf has landed.
- **panel-toggle-no-shelf**: With no shelf, toggling a shelf panel MUST do nothing.
- **land-slide**: The component MUST let a caller end a slide in flight at its destination.

### Slide

- **slide-duration**: A shelf slide MUST last 0.2 seconds.
- **slide-easing**: A slide's width MUST follow smoothstep easing, progress squared times three minus two times progress, from origin to target.
- **slide-per-frame-layout**: A slide MUST run a full layout pass on every display frame, so every view inside both panes takes the frame its constraints give it on every frame.
- **slide-through-width**: A slide MUST move the shelf by changing the shelf host's requested width, and MUST NOT move the divider position.
- **slide-width-priority**: During a slide the requested width MUST sit at priority 999, above every holding priority and below required.
- **slide-minimum-zero**: During a slide the shelf pane's minimum thickness MUST be zero so the width can be walked to and from zero.
- **slide-in-from-zero**: Sliding in MUST uncollapse the shelf at zero width, so the shelf never shows at its full width before the slide begins.
- **slide-in-window-frame**: Sliding in MUST restore the window's frame if uncollapsing grew it.
- **slide-window-width-hold**: For the length of a slide the window's content width MUST be held to its width at the start.
- **slide-content-gives-up-room**: The content pane MUST give up what the shelf gains, point for point, through an animated resize that begins before the slide and ends after it.
- **slide-start-after-draw**: The slide clock MUST start only once the panes have drawn for the animated resize.
- **slide-start-guard**: A slide whose start is overtaken by a later toggle MUST NOT start.
- **slide-end-collapse**: Ending a slide to zero width MUST collapse the shelf pane.
- **slide-end-restore**: Ending a slide MUST restore the shelf's minimum thickness to 180 points, the requested width to the clamped open width, its priority to the drag-beatable one, and release the window width hold.
- **slide-end-order**: Ending a slide MUST run the did-move callback, then the visibility callback, then the completion (unless superseded).
- **slide-visibility-callbacks**: An animated visibility change MUST call the visibility callback when the slide begins and again when it ends.

### Move notifications

- **move-pair**: The component MUST call the will-move callback as the shelf's width is about to change beside the content and the did-move callback when it has finished, for a slide, an adopted layout and a divider drag.
- **move-not-for-window-resize**: The component MUST NOT call either move callback for a window resize, which moves the content's edge and not the shelf's.
- **move-detects-by-width**: The component MUST treat a resize as a shelf move when the split view's width equals its width at the previous resize and is above zero.
- **drag-settle**: A divider drag MUST count as finished when no further resize has arrived for 250 milliseconds.
- **drag-settle-restart**: Each further drag step MUST restart that 250 millisecond wait.
- **slide-owns-callbacks**: While a slide or adoption holds the pane shares, drag detection MUST NOT call either move callback.

### Layout handoff

- **shelf-layout-snapshot**: The component MUST describe its shelf as a value holding visibility and the shelf pane's current width, with width zero when there is no shelf.
- **adopt-immediate**: Adopting a layout MUST apply it at once with no animation.
- **adopt-holds-shares**: Adopting a layout MUST call will-move before changing the shelf and did-move after a layout pass completed, with the pane shares held for the whole span.
- **adopt-visibility**: Adopting a layout MUST collapse or uncollapse the shelf only when its state differs from the layout's visibility, and MUST call the visibility callback when it does.
- **adopt-width**: Adopting a visible layout MUST apply its width only when it is at least the shelf's minimum thickness, by setting the requested width and the divider position.
- **adopt-no-shelf**: With no shelf, adopting a layout MUST do nothing.

### Lifetime and isolation

- **teardown**: Releasing the component MUST cancel a pending drag-settle wait, stop a slide's display link and remove both split view observers.
- **ui-thread-confined**: The component MUST be used on the UI thread only.
- **no-archive-init**: The component MUST NOT support construction from an archive.

