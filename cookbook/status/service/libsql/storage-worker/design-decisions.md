
- **Decision**: One dedicated thread owns the only connection, and every other thread talks to it over a `MessagePort`.
  **Rationale**: Stated in the source comment and in `storage/remote.ts`: an embedded `file:` connection runs statements synchronously on the calling thread and a lock wait can spin up to `busy_timeout` (5 s), so when the API thread held its own connection a read that met a monitor write or WAL checkpoint froze the event loop, `/health` timed out and the supervisor restarted the container (the 2026-10-22 outage).
  **Approved**: pending
- **Decision**: Run migrations on every boot of the worker.
  **Rationale**: The source comment says "embedded-file deployments self-migrate on boot"; migrations are idempotent, so repeated boots are safe.
  **Approved**: pending
- **Decision**: Report startup failure as a reply message instead of throwing, and do not end the worker from the module.
  **Rationale**: The host is awaiting the first message in `startStorageThread` and turns `{ ready: false, error }` into a rejection with a clear message; the source does not state why the worker is left running, so this is recorded as the code's behavior, not an endorsement.
  **Approved**: pending
- **Decision**: Do not validate attach messages and do not wrap the listener in a `try`.
  **Rationale**: Not stated in a comment; `StorageWorkerRequest` is the contract and the host's `connect()` is the sole sender. A malformed message therefore ends the worker, which the host treats as fatal through `onExit`. Recorded as fact.
  **Approved**: pending
- **Decision**: Keep this file as glue and leave spawn and attach policy to `storage-thread.ts`.
  **Rationale**: Stated in the source comment ("Glue only — spawn and attach policy live in storage-thread.ts").
  **Approved**: pending

