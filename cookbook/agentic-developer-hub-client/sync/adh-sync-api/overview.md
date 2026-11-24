
`ADHSyncAPI` is the authenticated wire client for the Agentic Developer Hub
backend's offline-sync endpoints, `GET /sync/pull` and `POST /sync/push`. It
deliberately owns exactly three things — the request
URLs, attaching the caller's bearer credential, and mapping HTTP status codes
to a typed `Failure` — and decodes nothing: the wire shapes belong to the
backend and to the native sync core, so this package needs no sync-core
dependency. A host adapts `ADHSyncAPI` to the `SyncTransport` protocol the
sync engine ([adhsdk.ingredient.data.sync.offline-sync-client](cookbook:d3a0b65f-92c0-43c1-b04c-77638eb72044)) calls through, in about 20 lines.

