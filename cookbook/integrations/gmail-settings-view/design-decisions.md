
**Decision**: The view calls only the model and renders only model state.
**Rationale**: The model is "the tested unit"; keeping the view thin leaves all behavior in one place that tests cover and makes the view replaceable on another platform.
**Approved**: pending

**Decision**: Errors, including per-account sync errors, are shown as alerts, not inline text.
**Rationale**: Alerts interrupt until acknowledged, so a failure cannot be missed in a pane that otherwise has no place for it. The account row carries only the "Error" badge, and "Show Error" re-raises the alert on request.
**Approved**: pending

**Decision**: The fetch window offers fixed choices (7, 14, 30, 90, 180, 365 days) rather than a stepper, and the picker adds the account's current value when it is custom.
**Rationale**: Each change to the window triggers a re-sync, so stepping a day at a time would be costly. Adding the current value stops a stored custom setting from being silently replaced or shown blank.
**Approved**: pending

**Decision**: Toggles and pickers stay enabled while the model is busy.
**Rationale**: The model applies a change locally at once and coalesces rapid changes into the latest send, so a disabled control would only get in the way. The busy gate applies to actions, not to settings.
**Approved**: pending

**Decision**: A change sends the account's whole settings with one field changed.
**Rationale**: The service receives a complete settings value each time, so receives a complete settings value each time and partial writes need no merging.
**Approved**: pending

**Decision**: Account removal asks for confirmation with Cancel as the default and Esc declining.
**Rationale**: Removal signs the account out, removes the stored sign-in and deletes its mail from the Mac; the shared destructive-confirmation helper supplies the safe default.
**Approved**: pending

**Decision**: Reconnect reuses the Add Account flow.
**Rationale**: The service matches the account by email and reuses it, so no separate reconnect call exists.
**Approved**: pending

**Decision**: The Cancel button for sign-in is not disabled while the model is busy.
**Rationale**: Sign-in is itself a call in flight, so the model is busy for the whole wait; gating Cancel on busy would make the sign-in impossible to cancel.
**Approved**: pending

**Decision**: The client secret is shown only as ten fixed dots plus the last five characters, or "Stored (hidden)" when no suffix is available.
**Rationale**: The daemon sends only those characters, and the mask has a fixed length so it does not reveal the secret's length.
**Approved**: pending

**Decision**: Strings are literals with no localization layer, and picker labels do not pluralize. This is acknowledged debt (it is why no-hardcoded-strings fails), not a goal.
**Rationale**: The macOS source ships English literals. No fixed choice is 1, so "1 days" could appear only for a stored custom value. A port SHOULD use localized, pluralized labels from the start; the debt is repaid on macOS when the settings surface adopts a string catalog.
**Approved**: pending

**Decision**: The reconnect hint appears whenever a client is imported and any account exists, not only after a client was replaced.
**Rationale**: The view reads only the model, and the model exposes no "client replaced since sign-in" state, so the view cannot tell. A short always-on caption costs little and warns before a replacement, which is when it matters.
**Approved**: pending
