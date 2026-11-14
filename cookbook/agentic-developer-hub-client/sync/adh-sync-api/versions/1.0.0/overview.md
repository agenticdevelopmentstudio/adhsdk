
`ADHSyncAPI` is the authenticated wire client for the Agentic Developer Hub
backend's offline-sync endpoints, `GET /sync/pull` and `POST /sync/push`. Per
its own doc comment, it deliberately owns exactly three things — the request
URLs, attaching the caller's bearer credential, and mapping HTTP status codes
to a typed `Failure` — and decodes nothing: the wire shapes belong to the
backend and to the native sync core, so this package needs no sync-core
dependency. A host adapts `ADHSyncAPI` to the `SyncTransport` protocol the
sync engine (`offline-sync-client.md`) calls through, in about 20 lines,
per the same comment.

