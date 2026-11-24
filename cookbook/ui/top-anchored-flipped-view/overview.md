
The top anchored flipped view is an empty container whose coordinate origin is
at its top-left corner. It is for use as the document view of a scroll view.
AppKit's default origin is at the bottom-left, so a document shorter than the
scroll view's visible area sinks to the bottom and leaves an empty gap above
its content whenever the window is taller than the rows. With a flipped
document, the content stays at the top and the gap falls below it, which is
where a reader expects it.

It adds no drawing, no layout and no behavior of its own; its only job is the
flipped coordinate system.

