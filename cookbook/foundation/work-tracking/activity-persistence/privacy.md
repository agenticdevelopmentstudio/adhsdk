
- **Data collected**: Spans carry `windowTitle`, `workingPath`, `repoRoot`, `branch` and `appName`, which describe what the user works on; idle intervals record when the user was away.
- **Storage**: The host's own database; in the toolkit, the `activity_span` and `activity_presence` tables of `DaemonDatabase`, or memory for `InMemoryActivityStore`.
- **Transmission**: The contract does no networking; data leaves the process only through the host's own channels, such as the work-tracking XPC protocol.
- **Retention**: `pruneActivity(endedBefore:)` deletes derived spans and old idle intervals; the caller chooses the cutoff, and a span the host has not derived is kept indefinitely.

