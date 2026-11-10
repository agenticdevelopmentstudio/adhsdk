
- **Window role**: Standard window with title accessible to the accessibility tree (title bar hidden but title retained for screen readers, Mission Control, and the Window menu).
- **Chat view and composer**: Accessibility provided by `InlineChatView` and the contained text field; the controller does not impose additional barriers.
- **Keyboard navigation**: First responder management ensures the composer field receives keyboard focus when the window becomes key, enabling immediate text input without requiring Tab navigation.
- **Minimum interaction target**: Not applicable. This component manages the window and focus; interactive elements (buttons, fields) are owned by `InlineChatView` and governed by their own specifications.

