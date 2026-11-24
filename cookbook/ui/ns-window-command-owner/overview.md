
`commandOwner` is a read-only property added to `NSWindow` in a public
extension. It answers which window a command typed or chosen in a given window
is about: the window itself, or for a child window the window it is attached
to, followed up the chain to the top.

A child window is part of its parent rather than a window of its own. The
source gives the example of a Chrome pane's page, kept over the pane, which
takes the keys by being key itself, and so do its bubbles and menus above it.
A command that finds its target through the key window, or the window of a key
event, and stops at the child would act on a window that has no panes, no notes
and no project. This property is the one place that walks up to the real
window. It is non-visual shared logic with no state of its own.

