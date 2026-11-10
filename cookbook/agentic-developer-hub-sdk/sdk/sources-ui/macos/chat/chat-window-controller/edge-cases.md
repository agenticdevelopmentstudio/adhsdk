
- **Null backdrop**: A nil backdrop is acceptable; the chat view renders without a background animation.
- **Empty view model**: The controller accepts the view model but delegates all chat display to `InlineChatView`; an empty or uninitialized view model is a concern for the view model, not the controller.
- **First responder already set**: If `focusInput()` is called when another view already has first responder status, the method attempts to set the composer as first responder; the window or other views may retain focus if they refuse to release it (e.g., during a drag operation).
- **Frame restoration failure**: If `setFrameUsingName(_:)` returns `false` (no saved frame), the window centers on screen; subsequent moves and resizes update the saved frame.
- **Window becoming key during text selection**: The `windowBecameKey` observer checks if the current first responder is the window itself before calling `focusInput()`. If a transcript selection or other view holds first responder, `focusInput()` is not called, preserving the selection.
- **Multiple ChatWindowController instances**: Each controller with a different `defaultsNamespace` maintains separate frame and appearance settings. Controllers with the same namespace share settings.
- **Window close/deinit**: The controller removes itself from `NotificationCenter` in `deinit` to avoid dangling observer references (see **remove-observer-on-deinit**).

