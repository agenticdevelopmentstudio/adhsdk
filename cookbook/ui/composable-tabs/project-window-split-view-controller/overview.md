
The content of one project window: an optional shelf (the list of projects)
down the leading edge, and the window's own content (the tabs and their
footer) beside it. Both halves run the full height of the window, up behind a
clear titlebar, and each paints that strip in its own color, which is what
makes the titlebar seamless: no band of a third color crosses the top. The
content is laid out from the safe area, below the toolbar; the shelf is given
the whole height, because its bordered card encloses the window controls and
lays out its own controls from the safe area.

Beyond arranging the two panes, the component owns three behaviors a plain
split view does not give: a shelf that slides in and out by a layout pass on
every display frame instead of an animated collapse; a remembered shelf
visibility and width shared by every project window; and a pair of
"shelf will move" and "shelf did move" notifications that let the window hold
each tab pane at its share of the width while the shelf moves. Use it as the
content controller of a project window. A window with no shelf (a host with no
projects to list) passes none and gets the content alone.

