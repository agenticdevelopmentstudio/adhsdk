
The Panel Scroll View is the canonical scroll host for panel content
inside a composable settings system. It wraps a private, top-down document
view so hosted content top-anchors (settings read top-to-bottom) instead
of using the platform's default bottom-up document origin. Content
installed through the component's set-content operation fills the
scroll view's viewport width (never narrower; wider only when it cannot
fit, in which case it scrolls sideways) and its height
constrained to at least the viewport height, so the content's own fitting
size never drives the size of the panel or its containing window. Per the
source's own doc comment, the owning split view controller wraps every
non-self-scrolling panel in one, and master/detail pickers host their
detail panes in one, so rebuilt content can never tug a split view's
divider.

