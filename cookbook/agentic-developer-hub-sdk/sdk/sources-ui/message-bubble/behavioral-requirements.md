
- **sender-name-accessible**: The component MUST include the sender's name in the accessibility tree, even when it is not visually displayed.
- **text-content-rendered**: The component MUST render the message's text content whenever it is non-empty.
- **timestamp-display**: When a timestamp is present, the component MUST display it in the locale's preferred hour cycle and ordering, with the hour zero-padded to two digits.
- **composing-caret**: When `deliveryStatus` is `.composing`, the component MUST append a streaming caret character (U+258B) to the text.
- **failed-state-indicator**: When `deliveryStatus` is `.failed`, the component MUST display the failure reason and apply a failure border (1pt, danger color) to the bubble.
- **failure-announced-on-web**: On Web, the component MUST place the failure reason inside a `role="alert"` container so assistive technology announces it automatically when it appears.
- **theme-by-sender-role**: The component MUST apply the appropriate semantic theme colors based on whether the sender is the local user or a persona.
- **size-to-content**: The component's bubble width MUST NOT exceed the caller-provided maximum width; text MUST wrap rather than overflow horizontally at that width, and the bubble MUST shrink to fit shorter content.
- **flat-theme-fill**: When a theme provides no fill (alpha ≤ 0.001), the component MUST render as a flat line (no background, no padding, no corner radius), even when a bubble border role is declared.
- **optional-theme-border**: When a theme declares a bubble border role with visible alpha and the bubble is neither flat nor in a failed state, the component MUST apply a 1pt border in the declared color.
- **rich-content-rendering**: The component MAY render rich content items (images, etc.) inline after the text.
- **rich-content-load-gating**: On platforms that preload rich-content images, the component MUST defer rendering the entire bubble, including its text, until every image has finished loading.
- **detail-indicator**: The component MAY display an optional detail indicator (e.g., arrow) controlled by the caller, and MUST invoke the caller-provided callback when the indicator is activated.
- **tool-call-pills**: The component MAY render an inline status pill for each tool call attached to the message (started, completed, or failed).
- **avatar-slot-rendered**: The component MUST render an avatar slot for every message, even when the sender has no avatar image, so that a transcript's left edge stays aligned.
- **connector-anchor**: On Web in three-pane mode, the component MAY render a connector anchor when the message declares a popover and its transcript index is known.
- **selected-state**: On Web, the component MAY apply a selected visual state (`.pc-message-selected`) when the caller marks the message as selected.
- **container-click-handler**: On Web, the component MAY invoke a caller-provided click handler when the bubble container is clicked or tapped.

