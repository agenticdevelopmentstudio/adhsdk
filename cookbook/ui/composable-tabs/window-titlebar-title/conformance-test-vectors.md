
No test beside the source drives this component. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| titlebar-title-001 | install-hides-native-title, install-adds-accessory | Install in a window | The window's title visibility is hidden and the window lists the component among its titlebar accessories |
| titlebar-title-002 | install-sets-window-title, text-before-install | Set `text` to "Notes" before installing, then install | The window's `title` is "Notes" |
| titlebar-title-003 | text-sets-label, text-mirrors-window-title | After install, set `text` to "Plan" | The label reads "Plan" and the window's `title` is "Plan" |
| titlebar-title-004 | text-reads-label | Set `text` to "Plan", read `text` | "Plan" |
| titlebar-title-005 | icon-nil-hides, icon-sets-view | Set `icon` to an image, then to nil | The icon view is shown with the image, then hidden with no image |
| titlebar-title-006 | icon-size, icon-hidden-from-accessibility | Read the icon view's constraints and accessibility flag | Width 14 and height 14; not an accessibility element |
| titlebar-title-007 | label-identifier, label-single-line-tail | Read the label | Identifier `window.title`; line break mode truncates the tail |
| titlebar-title-008 | stack-horizontal, stack-insets | Read the stack | Horizontal, centred vertically, spacing 5, insets 6 left and 6 right, 0 top and bottom |
| titlebar-title-009 | width-fits-title, width-capped-by-window | Install in a 1000-point window with a short title | Width equals the stack's fitting width |
| titlebar-title-010 | width-capped-by-window, resize-on-window-resize | Set a very long title in a 400-point window | Width is 240 points; widening the window to 600 points raises it, narrowing lowers it |
| titlebar-title-011 | width-never-negative | Resize the window to 100 points | Width is 0 |
| titlebar-title-012 | height-minimum | Install with a stack whose fitting height is under 28 points | Height is 28 |
| titlebar-title-013 | width-unbounded-without-window | Set `text` on a component not installed in any window | Width equals the stack's fitting width |
| titlebar-title-014 | observer-removed-on-deinit, observer-weak | Install, release the component, resize the window | The window resizes with no callback to the released component and no crash |
| titlebar-title-015 | no-archive-init | Attempt to construct from an archive | The attempt is rejected with a fatal error |

