
- **Null / empty input**: Not applicable: The formatter takes a non-optional date; a caller with no date decides its own text (the Gmail settings pane shows `Never synced`).
- **Boundary values**: An interval of exactly the cutoff is relative; one second more is absolute. A date equal to now renders the platform's relative phrase for a zero interval.
- **Concurrent access**: A stateless function; each call builds its own formatter, so calls from any thread are independent.
- **Error states**: Not applicable: Formatting cannot fail.
- **Offline / disconnected state**: Not applicable: The formatter has no network access.
- **Cancellation**: Not applicable: The formatter has no concern of this kind beyond what Behavioral Requirements state.

