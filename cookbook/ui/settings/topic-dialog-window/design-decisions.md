
**Decision**: The dialog is built as a settings window (topic sidebar, toolbar, help drawer) rather than a plain form.
**Rationale**: A record edited in steps reuses the settings window's navigation and help, so the two read as the same kind of surface.
**Approved**: pending

**Decision**: The close button is Cancel, and the window refuses to close itself.
**Rationale**: Closing must answer the owner exactly once, so the one `finish` path takes the window down.
**Approved**: pending

**Decision**: OK either finishes or hands over to `onOK`, which disables OK until the owner re-enables it or finishes.
**Rationale**: An owner that saves asynchronously needs one save in flight; Return is refused with the button.
**Approved**: pending

**Decision**: `present()` starts the modal session on the next run-loop pass, not inside the call.
**Rationale**: A caller running as a main-queue block would otherwise hold the main queue for as long as the dialog is up, and every await the dialog's own work makes on the main actor would wait for it to close.
**Approved**: pending

**Decision**: The dialog keeps a reference to itself from present, show or beginSheet until it finishes.
**Rationale**: A window does not keep its own controller, so an owner that presents and lets go would lose the dialog before its modal session starts.
**Approved**: pending

**Decision**: Finishing a running modal session also posts an application-defined event.
**Rationale**: Stopping the session takes effect when the loop next handles an event; an OK that completes from an awaited save comes from no event.
**Approved**: pending

**Decision**: The sheet is ended before `onFinish` is called.
**Rationale**: The owner can then begin the next sheet on the same window from within `onFinish`.
**Approved**: pending

**Decision**: A sheet has no toolbar; help moves to a round help button at the bottom left, and the problem line shifts right of it.
**Rationale**: A toolbar does not belong in a sheet; the topics stay in the sidebar.
**Approved**: pending

**Decision**: The dialog's sidebar width and help-drawer memory are stored apart from the settings window's.
**Rationale**: A dialog is smaller, and the settings window's remembered width would take most of it.
**Approved**: pending

**Decision**: Topics are not sorted and have no search field, and a single topic hides the list.
**Rationale**: The topics are steps in one task, in the order given, and few enough that a search field would only take room; one topic is the whole dialog.
**Approved**: pending

**Decision**: The owner's closures are released on finish.
**Rationale**: The dialog is done with what the owner captured; releasing avoids retain cycles.
**Approved**: pending

**Decision**: The dialog is not minimizable.
**Rationale**: It holds up the app until answered.
**Approved**: pending

