
- **Data collected**: What the user types into the composer and what the connected terminal prints, both held in the chat's history.
- **Storage**: Only the remembered pane's node identifier is persisted, in the pane state store; chat history storage belongs to the chat session and view model.
- **Transmission**: Messages go to the connected in-process terminal session. When a directory and listing are supplied the session is listed so processes outside the app can drive it.
- **Retention**: The remembered identifier lasts until a confirmed disconnect or another connection replaces it; a disconnect keeps the chat history.

