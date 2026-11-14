
A container that holds exactly one child view controller inside a pane whose
own backdrop fills the whole pane, the strip behind a clear titlebar
included. It exists so that a window whose content runs up behind a
transparent titlebar can still choose, per pane, whether the child starts
below the titlebar (the safe area) or is given the whole height to place
things itself. The pane paints its own color, so adjoining panes can each
paint the titlebar strip in their own color and no band of a third color
crosses the top.

Use it around any pane in a window that extends its content under the
titlebar. It adds no controls, no state beyond its insets and its backdrop
color, and no behavior of its own beyond pinning, clipping and painting.

