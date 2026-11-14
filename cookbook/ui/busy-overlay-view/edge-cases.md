
- **Empty or nil message** (MUST): The message line is hidden and the text cleared; the spinner alone shows.
- **Long message** (MUST): The message truncates at the tail within the width left after the 16-point insets.
- **show called twice with the same host** (MUST): Only the message and the accessibility label change; the overlay is not re-added and its opacity is not reset to 0, though the fade-in animation to 1 is requested again.
- **hide called when not showing** (MUST): Does nothing; safe to call at any time.
- **hide called twice during the fade** (MUST): The second call returns at once; the first fade completes and removes the overlay.
- **show during fade-out** (MUST): The pending removal is cancelled by the hiding flag being cleared; the completion handler finds the flag false and leaves the overlay up.
- **show on a different host while showing** (MUST): The overlay leaves the old host and starts again at opacity 0 over the new host.
- **Pointer events during fade-out** (MUST): `hide()` sets the overlay's opacity to 0 through the animator, which updates the opacity value at once while the fade is drawn over 0.2 seconds, so hit tests answer nothing from the moment `hide()` is called and presses reach the controls beneath while the overlay is still visibly fading.
- **Keyboard input** (MUST NOT): The overlay overrides only the three mouse-down events and scroll wheel; it overrides no key event and no mouse-up or drag event, so it does not intercept keystrokes.
- **Concurrent access** (MUST): The type is confined to the main actor, so every call runs serialized on the main thread; there is no cross-thread access to define.
- **Network or offline state**: Not applicable: the overlay performs no network, disk or other external work; its owner decides when work is done.
- **Decoding from an archive** (MUST NOT): The coder initializer is unavailable and traps if called; the overlay is built only in code.

