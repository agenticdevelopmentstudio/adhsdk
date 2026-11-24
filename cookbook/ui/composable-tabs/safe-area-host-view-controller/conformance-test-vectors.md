
No test beside the source drives this component directly; it is built (indirectly) by the tests that construct a project window. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| safe-area-host-001 | single-child, child-owned | Construct with a child controller and load the view | The child is attached as a child controller and its view is the only subview |
| safe-area-host-002 | safe-area-top | Default construction in a window with a 28-point titlebar safe area | The child's top is 28 points below the pane's top |
| safe-area-host-003 | full-height-top | Construct with pinning to the safe area off, same window | The child's top is at the pane's top, 0 points |
| safe-area-host-004 | insets-sign, insets-live | Set insets of top 4, left 8, bottom 6, right 10 after load | Child frame is inset 8 leading, 10 trailing, 6 bottom, and 4 below its top pin |
| safe-area-host-005 | insets-before-load | Set insets before the view is loaded, then load | The child is inset by those values at first layout |
| safe-area-host-006 | insets-default-zero | Read the insets on a new instance | All four edges are 0 |
| safe-area-host-007 | side-edges-yield, top-bottom-required | Inspect the four pins after load | Leading and trailing at the default-high priority; top and bottom required |
| safe-area-host-008 | side-edges-yield, clips-child | Size the pane to zero width with a child that has a wide fitting size | No constraint is broken; the pane draws nothing outside its bounds |
| safe-area-host-009 | backdrop-default-clear | Read the backdrop color on a new instance | Clear; the layer's background is never set until a color is assigned, so nothing is painted |
| safe-area-host-010 | backdrop-paints-pane, backdrop-snapshot | Set the backdrop color to a theme color, then change the system appearance without re-setting | The layer holds the color as set; it does not change with the appearance |
| safe-area-host-011 | backdrop-loads-view | Set the backdrop color on an instance whose view is not loaded | The view is loaded and its layer carries the color |
| safe-area-host-012 | no-archive-init | Attempt to construct from an archive | The attempt is rejected with a fatal error |
| safe-area-host-013 | ui-thread-confined | Construct from off the UI thread | The use is rejected at build time or by a runtime check |

