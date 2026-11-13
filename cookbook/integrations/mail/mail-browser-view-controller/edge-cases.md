
- **Refresh while off screen**: No refresh task exists while the view is not on screen. The component MUST NOT poll in that state.
- **Cancellation during sleep**: The wait ignores the cancellation error, and the loop then checks for cancellation and exits. The component MUST NOT refresh after cancellation.
- **Repeated appear**: A second appear cancels the earlier task before starting a new one. The component MUST keep at most one refresh task.
- **Short or zero interval**: The source does not bound the interval; a very short interval makes the model check for syncs that often. The source validates nothing here.
- **Failed account read during a poll**: The model's refresh swallows a failed accounts read and does nothing; no alert appears. This is the model's behavior and the controller adds nothing.
- **Error with no window**: The alert runs application-modally and blocks until closed. The component MUST dismiss the model error afterward.
- **Error cleared**: The error stream drops nil values, so clearing the error shows nothing.
- **Second error while one is showing**: Each non-nil value triggers a new alert request; the source does not coalesce or suppress them. Behavior of stacked sheets is the system's.
- **No accounts or provider not configured**: Not a controller concern: the model clears the list and the panes show their empty state.
- **Concurrent access**: The controller and model are confined to the main actor; the refresh task hops to the main actor to call the model, so calls are serialized with UI work.
- **Offline**: The poll reads only the local store, so loss of connectivity does not affect it; the controller makes no network call.
- **Task started before load completes**: The initial reload is a detached task whose handle is not kept; it is not cancelled when the view disappears.

