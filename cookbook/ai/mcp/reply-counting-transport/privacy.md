
- **Data collected**: It parses every message to read `id`, `method` and `params.requestId`, and retains only the id keys of owed requests, never bodies or params.
- **Storage**: The owed set is in memory only and lives with the actor.
- **Transmission**: It relays messages to and from the wrapped transport and adds no transmission of its own.
- **Retention**: An id is dropped when its reply is sent or its request is cancelled; ids of requests never answered stay until the actor is released.
- **Logging**: The logger is a no-op, so nothing it sees is written anywhere.

