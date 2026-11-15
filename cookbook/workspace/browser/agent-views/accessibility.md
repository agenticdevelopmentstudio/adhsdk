
- **Role/trait**: The control is a native segmented control with
  accessibility identifier `browser.agent-view`; each segment exposes its
  tooltip text as its accessibility description, since segments carry
  icons only.
- **Label requirements**: Website, Agent preview, Agent source.
- **Announce state changes**: The native control reports its selection
  change; the content swap posts no further announcement.
- **Keyboard / assistive-technology navigation**: The control is in the
  key-view loop like the toolbar's other controls; the source view is a
  selectable, read-only text view, and the preview is a read-only web view
  that assistive technology can read.
- **Minimum tap target**: The system segmented control's size.

