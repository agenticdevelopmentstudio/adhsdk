
- **Data collected**: The signed-in user's mail as the hub holds it: addresses, subjects, snippets, bodies, label names and attachment metadata.
- **Storage**: A local SQLite file the host chooses, in its own container.
- **Transmission**: Pulled from the hub over HTTPS with the user's token; sends go to the hub's action route.
- **Retention**: A deleted message stays on disk as a tombstone with its content until the next pull replaces it or the user signs out, when `signOut` purges every row.

