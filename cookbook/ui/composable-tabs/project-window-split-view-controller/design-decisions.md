
**Decision**: The shelf is a plain split item in a plain split view, not a sidebar item in a themed split view.
**Rationale**: The source documents this as the Conversations shelf's shape: sidebar material is drawn by the appearance and reaches no theme, and the themed split view's divider color is what trapped Conversations at launch.
**Approved**: pending

**Decision**: The slide is walked by hand through the shelf host's width constraint on every display frame, not by an animated collapse and not by moving the divider.
**Rationale**: Per the source comment, an animated collapse lays contents out once at the final size, so a web view jumps to its end width on the first frame while its pane slides to meet it; setting a divider near zero collapses a collapsible item, and a set divider is undone by the next layout pass in favor of the constraint.
**Approved**: pending

**Decision**: The walked width sits at priority 999 and the window width is held required during the slide.
**Rationale**: The walked width and the panes' held shares sit above the window's own stay-put priority of 500, so once a pane reached its minimum the layout widened the window instead of stopping the shelf; held, the window keeps its size and what cannot fit is the shelf's width or a share.
**Approved**: pending

**Decision**: On the first uncollapse after a launch that began collapsed, the window frame is put back to what it was before.
**Rationale**: Per the source comment, that first uncollapse grows the window by the shelf's remembered width as if the shelf were added beside the content, whereas the shelf should take its room from the panes.
**Approved**: pending

**Decision**: Shelf moves are told apart from window resizes by comparing the split view's width with its width at the last resize, and a drag is finished when it has rested for 250 milliseconds.
**Rationale**: Per the source, AppKit has no notification for the user letting go of a divider, and the window holds each pane at its share of the width only across shelf moves, not window resizes.
**Approved**: pending

**Decision**: While a slide or adoption holds the shares, resize notifications do not raise the move callbacks, and sliding out reads shares before the first step.
**Rationale**: Per the source comment, sliding out AppKit lays the content out at its final width before the first step, so shares read at a step would already be lopsided.
**Approved**: pending

**Decision**: The visibility callback fires both when an animated change starts and when it ends, although its documentation says "after the shelf has finished".
**Rationale**: The source calls it at the end of the slide-starting function and again when the slide lands; the component's callers repaint the toggle from the state reached, which both calls report correctly (the first reports the destination). A port that fires it once at the start keeps that behavior.
**Approved**: pending

**Decision**: The opening width requested at construction is the raw persisted width, while sliding in uses the clamped width.
**Rationale**: The source applies the clamp only in the slide path; the pane's own minimum and maximum thickness constrain the construction path. Technical debt that does not change the visible result inside 180 through 480 points.
**Approved**: pending

**Decision**: On a window with no shelf, visibility requests are ignored without running their completion.
**Rationale**: The source returns before the completion when there is no shelf item, which can leave a caller waiting; callers that pass a completion check has-shelf.
**Approved**: pending

**Decision**: A slide does not consult the system's Reduce Motion setting.
**Rationale**: No such check exists in source; this is recorded as the open question on `Reduce Motion` pending a policy on whether a width slide counts as motion to reduce.
**Approved**: pending

