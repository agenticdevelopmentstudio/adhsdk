
- **Data collected**: Message headers and bodies, sender and account email addresses, and label names, read through the client. The model adds nothing.
- **Storage**: In memory only, for the life of the model. Persistence is the client's concern. The source comment says a sync poll "Reads only the local store, never Gmail".
- **Transmission**: The model sends no data itself. Opening an unread message sends a modify-labels request through the client, which changes the message's labels.
- **Retention**: Until the model is released or the list is cleared, replaced or reloaded.

