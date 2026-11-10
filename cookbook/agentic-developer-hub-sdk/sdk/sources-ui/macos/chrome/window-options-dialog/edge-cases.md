
- **Dialog already open**: Calling `present()` when `isShown == true` is a no-op — see **single-dialog-instance**. Calling `toggle()` when open does NOT share this no-op behavior: it closes the dialog instead (see **support-toggle**).

- **Close called when dialog is not open**: A no-op; no exception thrown — see **end-modal-session-on-close**.

- **Title changed while dialog open**: The dialog rebuilds controls via `rebuildControls()` — see **rebuild-on-title-change** and **rebuild-controls-public**. This is necessary for windows whose title changes (e.g., a tab-like pane named by its content).

- **Host window level changes during modal session**: The dialog re-samples the host's window level on every pass of the event loop while the modal session is active and adjusts its own level to match — see **host-level-sync**. This prevents the dialog from appearing behind its host when the host is raised to `.floating`.

- **Host window closed while dialog is open**: The host window reference (`gearButton.window`) becomes `nil`. The dialog remains open; subsequent attempts to read the host's level or reposition the dialog fall back to the main screen or the window's own `center()`. The component does not close the dialog or end the modal session on its own in this case.

- **Host window moved to a different screen while dialog is open**: The dialog's screen was sampled once, from the host window's screen at the moment it opened — see **center-on-screen**. It is not re-centered if the host is subsequently moved to a different screen while the dialog stays open; this differs from **host-level-sync**, which does track the host continuously.

- **Multiple dialogs in same window**: Each window can have multiple gear buttons with their own `WindowOptionsDialog` instances, each managing a separate modal dialog. The dialogs do not interfere if opened sequentially.

- **Concurrent modifications to title or controls**: All updates occur on `@MainActor`, so thread safety is managed by the actor isolation.

