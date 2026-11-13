
- **Provider unknown at removal**: When the provider has not loaded, or its load failed, a confirmed removal MUST be sent to the service as if configured. The decision is `provider?.configured != false`, so only a known not-configured state skips the call.
- **Pick then remove**: When Gmail was picked from `+` and never configured, a confirmed removal MUST only clear the pick and the error message; nothing is sent.
- **Pick already configured elsewhere**: When Gmail is configured, the menu item is disabled, so a pick cannot duplicate it; the listing rule still shows a single row.
- **Pick lost on configuration**: A pick is in-memory only and is not persisted; it is cleared by a confirmed removal and not by a successful configuration, which shows the same single row through the listing rule.
- **Remove with nothing listed**: Pressing `−` MUST announce refusal and MUST NOT open a confirmation, even though the button is also disabled in that state.
- **Missing window**: The confirmation is attached to the panel's window if it has one; the source passes an optional window and the shared helper decides what happens without one.
- **Provider publisher timing**: The provider publisher emits before the property holds its new value, so the rebuild check MUST run one main-queue turn later; checking immediately would see the stale value.
- **Redundant provider updates**: A provider update that does not change whether Gmail is listed MUST NOT rebuild the listing, which preserves the user's selection.
- **Rebuild after panel deallocation**: Callbacks hold the panel weakly, so a callback after deallocation does nothing.
- **Reload failure**: The panel does not handle a failed reload itself; the failure is the model's error message, shown by the Gmail view. Because the provider then stays unknown, only a pick lists Gmail.
- **Concurrent access**: The panel and the Gmail detail are main-actor isolated, and reloads and removals run as unstructured tasks started from the main actor; overlapping calls are serialized and counted by the model (`busyStaysTrueUntilOverlappingCallsBothFinish`), not by the panel.
- **Offline or disconnected service**: The panel sends nothing itself; a failed or unreachable service surfaces as the model's error message and leaves the provider state as it was.
- **Decoding from an archive**: Creation from an archive terminates the process with a fatal error.
- **Null and empty input**: The initializer takes a required client and a tracker defaulting to the shared one; there is no optional input to be empty.
- **Boundary values**: The listing is either empty or one row, because Gmail is the only integration.

