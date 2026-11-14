
### Installation

- **install-hides-native-title**: Installing in a window MUST hide the title the platform draws.
- **install-adds-accessory**: Installing MUST add the component to the window as a titlebar accessory.
- **install-sets-window-title**: Installing MUST set the window's `title` to the current text, so the Window menu and accessibility still read the name.
- **install-observes-resize**: Installing MUST observe that window's resize notification, on the main queue, and re-size the component on each one.
- **install-sizes-immediately**: Installing MUST size the component once, immediately after wiring.
- **leading-edge**: The component MUST sit at the leading edge of the title bar.

### Text

- **text-reads-label**: The `text` property MUST read back the label's current string.
- **text-sets-label**: Setting `text` MUST set the label's string.
- **text-mirrors-window-title**: Setting `text` MUST also set the title of the window the component is in, when it is in one.
- **text-before-install**: Setting `text` before installation MUST NOT fail, and the first installation MUST carry that text to the window's title.
- **text-resizes**: Setting `text` MUST re-size the component.

### Icon

- **icon-reads-view**: The `icon` property MUST read back the icon view's image.
- **icon-sets-view**: Setting `icon` MUST set the icon view's image.
- **icon-nil-hides**: Setting `icon` to nil MUST hide the icon view, and setting it to an image MUST show it.
- **icon-resizes**: Setting `icon` MUST re-size the component.
- **icon-size**: The icon view MUST be fixed at 14 points wide and 14 points high, with the image scaled proportionally to fit.
- **icon-hidden-from-accessibility**: The icon view MUST NOT be an accessibility element.

### Label

- **label-single-line-tail**: The label MUST truncate at its tail.
- **label-font**: The label MUST use the system title bar font at its default size.
- **label-color**: The label MUST use the system primary label color.
- **label-low-compression-resistance**: The label MUST have its horizontal content-compression resistance set to the default-low priority, so that it is the view that gives way (the icon is held at a fixed width).
- **label-identifier**: The label MUST carry the accessibility identifier `window.title`.

### Layout

- **stack-horizontal**: The icon and label MUST be laid out in a horizontal stack, centred vertically, with 5 points between them.
- **stack-insets**: The stack MUST inset its contents by 6 points on the left and right sides and none on the top and bottom. The insets are physical left and right values, equal on both sides.
- **width-fits-title**: The component's width MUST be the stack's fitting width, so that the title is as wide as its own content.
- **width-capped-by-window**: The component's width MUST NOT exceed the window's width minus the 160 points kept for trailing accessories and the window controls.
- **width-never-negative**: The component's width MUST be clamped to 0 when the window is narrower than 160 points.
- **width-unbounded-without-window**: With no window, the component's available width MUST be unbounded, so only the fitting width applies.
- **height-minimum**: The component's height MUST be the stack's fitting height, but at least 28 points.
- **resize-on-window-resize**: The component MUST re-size whenever its window is resized.

### Lifetime and isolation

- **observer-removed-on-deinit**: The component MUST remove its resize observer when it is deallocated.
- **observer-weak**: The resize observer MUST hold the component weakly.
- **no-archive-init**: The component MUST NOT support construction from an archive.
- **ui-thread-confined**: The component MUST be used on the main thread only.

