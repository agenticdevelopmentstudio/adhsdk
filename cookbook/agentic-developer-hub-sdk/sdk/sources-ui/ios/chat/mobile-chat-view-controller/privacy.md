
- **Data collected**: Messages and drafts are collected from the session's `ChatViewModel`; the component does not collect user input beyond what the session provides. Send failures are caught but not logged.
- **Storage**: All message and draft data is stored in the session's memory; the component maintains no local persistence.
- **Transmission**: Message submission is delegated to the view model's `submitMessage()` method; the component does not directly transmit data.
- **Retention**: Messages are retained for the lifetime of the session; closing the component does not clear the session history.

