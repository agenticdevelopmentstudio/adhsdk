
- **Role/trait**: Text area / rich text input (depending on platform accessibility framework)
- **Label requirements**: The pane itself has no built-in label, and its public API provides no member through which a caller could set one — `textView` is private in both variants, so the standard `UIAccessibility`/`NSAccessibility` label mechanisms are not reachable through this component's surface. See the accessibility gap under **Compliance**.
- **Announce state changes**: The read-only state transition (toggling `isEditable`) is not automatically announced. The parent is responsible for signaling mode changes to accessibility systems if needed.
- **Minimum tap target**: On iOS, the text view itself is the touch target; its size is determined by its container. The 44×44pt minimum SHOULD be respected by the parent container.
- **Keyboard navigation**: The text view supports standard keyboard navigation (arrows, home/end, page up/down, etc.) on both platforms.
- **Selection and copy**: Text selection and copy/paste are supported on both platforms via standard gestures and keyboard shortcuts.

