
**Decision**: The view calls only the model and renders only model state.
**Rationale**: The model is "the tested unit"; keeping the view thin leaves all behavior in one place that tests cover and makes the view replaceable on another platform.
**Approved**: pending

**Decision**: Errors, including per-account sync errors, are shown as alerts, not inline text.
**Rationale**: The source comment states "Errors are shown as alerts, not inline text." The account row carries only the "Error" badge, and "Show Error" re-raises the alert on request.
**Approved**: pending

**Decision**: The fetch window offers fixed choices (7, 14, 30, 90, 180, 365 days) rather than a stepper, and the picker adds the account's current value when it is custom.
**Rationale**: The source comment says each change re-syncs, "so a day at a time is costly". Adding the current value stops a stored custom setting from being silently replaced or shown blank.
**Approved**: pending

**Decision**: Toggles and pickers stay enabled while the model is busy.
**Rationale**: The model applies a change locally at once and coalesces rapid changes into the latest send, so a disabled control would only get in the way. The busy gate applies to actions, not to settings.
**Approved**: pending

**Decision**: A change sends the account's whole settings with one field changed.
**Rationale**: The binding comment states "a write sends the whole settings at once", so the service receives a complete settings value each time and partial writes need no merging.
**Approved**: pending

**Decision**: Account removal asks for confirmation with Cancel as the default and Esc declining.
**Rationale**: Removal signs the account out, removes the stored sign-in and deletes its mail from the Mac; the source comment cites `confirmDestructive` for the safe default.
**Approved**: pending

**Decision**: Reconnect reuses the Add Account flow.
**Rationale**: The model comment states the service matches the account by email and reuses it, so no separate reconnect call exists.
**Approved**: pending

**Decision**: The Cancel button for sign-in is not disabled while the model is busy.
**Rationale**: Sign-in is itself a call in flight, so the model is busy for the whole wait; gating Cancel on busy would make the sign-in impossible to cancel.
**Approved**: pending

**Decision**: The client secret is shown only as ten fixed dots plus the last five characters, or "Stored (hidden)" when no suffix is available.
**Rationale**: The model comment states the daemon sends only those characters and the mask has a fixed length so it does not reveal the secret's length.
**Approved**: pending

**Decision**: Strings are literals with no localization layer, and picker labels do not pluralize.
**Rationale**: This records what the source does, not an endorsement. No fixed choice is 1, so "1 days" could appear only for a stored custom value.
**Approved**: pending

