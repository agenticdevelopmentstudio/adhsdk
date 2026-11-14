
- **Decision**: Use a local key event monitor instead of `keyDown` on the pane.
  **Rationale**: The source comment states the pane's content owns the first responder (a terminal, an editor) and would eat the arrow long before the pane saw it.
  **Approved**: pending

- **Decision**: Treat Return, Enter and Escape as the same action, leaving the mode.
  **Rationale**: The source comment states the mode is what they dismiss, and which of the three a person reaches for is a habit, not a distinction worth honouring.
  **Approved**: pending

- **Decision**: Give every pane its own monitor but let only the window's active pane move on an arrow key.
  **Rationale**: The source comments state every pane in the window has a monitor, so exit runs more than once and turning the mode off twice is a no-op, while only the pane the user selected moves.
  **Approved**: pending

- **Decision**: Ignore key events that do not belong to the pane's own window.
  **Rationale**: The source comment states a different window means a sheet is up, and Escape there cancels the sheet rather than the mode behind it.
  **Approved**: pending

- **Decision**: Remove the monitor on window close and on overlay removal, not in `deinit`.
  **Rationale**: The source comment states a closing window takes its panes with it without ever leaving arrange mode, and a `deinit` cannot touch the monitor because it is nonisolated.
  **Approved**: pending

- **Decision**: Refresh availability from the tree on every layout change instead of from the pane that acted.
  **Rationale**: The source comment states any pane moving changes what every other pane may do.
  **Approved**: pending

- **Decision**: Return only the consumed flag out of the key monitor's closure.
  **Rationale**: The source comment states `assumeIsolated` hands its result across an isolation boundary and the event type is not `Sendable`.
  **Approved**: pending

- **Decision**: Make the toggle button follow the mode, not the click.
  **Rationale**: The doc comment states the mode can also be turned on from the Window menu, so the tint follows the mode.
  **Approved**: pending

- **Decision**: Take the controller's pane questions as closures rather than a fixed pane type.
  **Rationale**: The doc comment states a project window's tree and the Coding Partner's two fixed panes ask different questions about what a pane may do while the mode, overlay and keys are one thing.
  **Approved**: pending

