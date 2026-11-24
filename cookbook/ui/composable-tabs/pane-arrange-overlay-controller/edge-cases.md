
- **Null and empty input**: A controller whose pane view has no window MUST treat the mode as off: `isEnabled(in:)` answers false for a nil window and the key handler returns unconsumed. A pane with no name closure set uses the default empty name; the default closures answer false and an empty direction set.
- **Boundary values**: An arrow key whose code matches no direction MUST pass through unconsumed. Keys other than Return, Enter, Escape and the four arrows MUST pass through unconsumed.
- **Reentrant install**: Calling `install` with an overlay present MUST refresh its availability and install nothing more.
- **Concurrent access**: The controller is `@MainActor`, but the key monitor's closure is not isolated, so it hands the work to the main actor with `MainActor.assumeIsolated` and only the consumed flag crosses back out, because the event type is not `Sendable`. Every pane in a window has a monitor, so one key press runs several handlers; turning the mode off twice is a no-op and only the active pane acts on an arrow.
- **Error states**: Not applicable: the controller calls no dependency that can fail; a pane view or window that has gone away stops the handlers by their guards.
- **Offline or disconnected state**: Not applicable: the controller performs no network access.
- **Teardown**: A `deinit` cannot remove the monitor because it is nonisolated, so the monitor is removed on window close or when the overlay is removed; a window that closes without leaving the mode MUST NOT leak the monitor.

