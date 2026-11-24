
- **Role**: The component sets `role="alert"` to signal to screen readers that the content is an alert or error message that requires immediate attention.
- **Text Content as Label**: The error message itself is the accessible label; no additional `aria-label` or `aria-labelledby` is required because the text is visible and announced.
- **Screen Reader Announcement**: When an error appears, screen readers announce it as an alert. When the error is dismissed (component returns null), the text is no longer present in the DOM. This relies on the container itself being visible when the error mounts; see the **Zero-width or hidden parent container** edge case for the one sequence where announcement is not guaranteed.
- **Keyboard Interaction**: Error Text is not keyboard-interactive; it is a passive text display. Focus management and form submission behavior are the responsibility of the containing form or surface.
- **Color and Meaning**: The message is communicated both by the red color (`text-apt-red`) and the text content. The text content provides a redundant signal for users with color vision deficiency and ensures the message is not color-dependent.

