
- **closed-non-interactive**: When `open` is `false`, the overlay MUST be non-interactive (clicks/taps on the header, close button, and body do not invoke `onClose` or otherwise pass through) and MUST NOT be visible.
- **apply-open-class**: The component MUST apply the `open` CSS class to the root element when the `open` prop is `true`.
- **omit-open-class**: The component MUST NOT apply the `open` CSS class to the root element when the `open` prop is `false`.
- **invoke-on-close**: The component MUST invoke the `onClose` callback function when the close button is clicked.
- **render-children**: The component MUST render the `children` prop within the body element.
- **close-label**: The component MUST display the `closeLabel` prop as the close button text when provided.
- **default-close-label**: The component MUST display the string `'← back'` as the close button text when `closeLabel` is not provided.
- **custom-class-name**: The component MUST apply the `className` prop to the root element, in addition to base and state CSS classes, when provided.

