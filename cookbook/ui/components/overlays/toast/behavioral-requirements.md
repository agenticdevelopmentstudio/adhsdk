
- **render-title**: Toast MUST render a title element when provided.
- **render-description**: Toast MUST render a description element when provided.
- **render-close-button**: Toast MUST render a clickable close button.
- **dismiss-on-close**: Toast MUST dismiss and remove itself from the viewport when the close button is clicked.
- **enqueue-toasts**: The `useToast()` hook MUST accept objects with `title` and `description` properties and enqueue them for display.
- **position-viewport-bottom-right**: The toast viewport MUST be positioned at the bottom-right corner of the viewport (1rem from the right edge, 1rem from the bottom edge).
- **manage-z-index**: The toast viewport MUST render at z-index 50 (above typical page content).
- **animate-entrance**: Toasts MUST fade in smoothly (opacity transition from 0 to 1) on entrance.
- **animate-exit**: Toasts MUST fade out smoothly (opacity transition to 0) when dismissed.
- **stack-toasts**: Multiple toasts MUST render in a vertical stack with 0.5rem gap between each.
- **constrain-width**: Each toast MUST have a fixed width of 320px, capped to (viewport width − 2rem) when the viewport is narrower than 320px plus margins.
- **localize-close-label**: The close button's dismiss label MUST be localized for the active locale.
- **enlarge-close-hit-area**: The close button SHOULD provide a hit area of at least 44×44pt, independent of the visible icon size, since the icon alone does not meet this minimum.
- **respect-reduced-motion**: Toasts SHOULD disable or shorten the opacity fade when the system reduced-motion preference is enabled.
- **independent-provider-queues**: Each `ToastProvider` instance MUST manage its own toast queue independently.

