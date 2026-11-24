
- **Data collected**: The bundle ids the user added or removed, the retention length, and the Accessibility answer with the app's code-signing designated requirement.
- **Storage**: The host's settings table, through the injected store; this code adds no other storage.
- **Transmission**: None by this code; values leave only through whatever the host does with its store.
- **Retention**: Values stay until overwritten; `activity_retention_days` is stored here but governs the activity history, which is enforced elsewhere.

