
### Hosting

- **single-child**: The component MUST host exactly one child view controller, supplied at construction, and MUST show that child's view as its only content.
- **child-owned**: The component MUST retain the child for its own lifetime and attach it as its child controller when its view is loaded.
- **view-fills-pane**: The component's own view MUST be one container view that holds the child's view; sizing that view to the pane is the job of the container that hosts it.
- **clips-child**: The component MUST clip its content to its own bounds, so a pane narrower than its child (a shelf sliding in) shows the part that fits and does not spill over its neighbors.

### Pinning

- **safe-area-top**: When constructed to pin to the safe area (the default), the component MUST hold the child's top edge at the pane's top safe area edge, offset by the top inset.
- **full-height-top**: When constructed not to pin to the safe area, the component MUST hold the child's top edge at the pane's top edge, offset by the top inset.
- **bottom-pinned**: The component MUST hold the child's bottom edge at the pane's bottom edge, offset upward by the bottom inset.
- **side-edges-pinned**: The component MUST hold the child's leading and trailing edges at the pane's leading and trailing edges, offset inward by the leading and trailing insets.
- **side-edges-yield**: The leading and trailing pins MUST sit below required priority, at the platform's default-high priority, so a pane collapsing to zero width does not force the layout system to break a required constraint.
- **top-bottom-required**: The top and bottom pins MUST be required.

### Insets

- **insets-default-zero**: The insets MUST default to zero on every edge.
- **insets-live**: Changing the insets MUST update the pins at once, without rebuilding the view.
- **insets-before-load**: Insets set before the view is first loaded MUST take effect when it loads.
- **insets-sign**: The component MUST apply the left and top insets as positive offsets and the right and bottom insets as negative offsets, so every inset moves its edge inward.

### Backdrop

- **backdrop-default-clear**: The backdrop color MUST default to clear.
- **backdrop-paints-pane**: Setting the backdrop color MUST paint the whole pane, including the strip behind the titlebar.
- **backdrop-snapshot**: The backdrop color MUST be applied as a resolved color value at the time it is set; the component MUST NOT track later appearance changes, so its owner re-applies the color when the theme changes.
- **backdrop-loads-view**: Setting the backdrop color before the view has loaded MUST load the view as a side effect.

### Lifetime and isolation

- **no-archive-init**: The component MUST NOT support construction from an archive.
- **ui-thread-confined**: The component MUST be used on the UI thread only.

