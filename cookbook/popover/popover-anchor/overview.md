
PopoverAnchor is a positioning context wrapper that groups a popover trigger and its associated panel as a single hover target. It establishes `position: relative` as the reference frame for the popover's absolute positioning, and it suppresses `onMouseLeave` when the pointer moves from the trigger to the panel (or back), rather than treating that crossing as leaving the group.

That suppression follows DOM containment, not visual geometry; see **panel-in-anchor-flow** for the conditions and the Edge Cases for what breaks them.
