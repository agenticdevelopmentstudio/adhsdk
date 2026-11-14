
- **Nil cursor (first sync).** Input: `pull(cursor: nil, limit: N)`. The
  `cursor` query item is omitted entirely rather than sent as an empty or
  placeholder value. MUST — `pull-cursor-omitted-when-nil`,
  `ADHSyncAPITests.pullFirstSync`.
- **Empty-string cursor.** Input: `pull(cursor: "", limit: N)`. Because
  `""` is non-`nil`, it is sent as `cursor=` (an empty query value) rather
  than being treated as equivalent to `nil`. MUST —
  `pull-cursor-query-item-verbatim`.
- **Non-positive or oversized `limit`.** Input: `limit` of `0`, a negative
  number, or `Int.max`. `pull` performs no local validation or clamping;
  `String(limit)` is sent to the server unmodified, and any resulting
  rejection surfaces through the ordinary status-mapping path
  (`maps-other-status-to-http`). MUST — this is the observed behavior of
  `pull-limit-query-item`; no client-side bound exists in the source.
- **Concurrent calls on one instance.** Two or more `pull`/`push` calls
  issued concurrently on the same `ADHSyncAPI` value proceed independently;
  `ADHSyncAPI` has no shared mutable state to race on, and it enforces no
  ordering between the calls' completions. MUST — `no-internal-serialization`.
- **Missing or revoked credential.** Input: `credentials.currentCredentials()`
  returns `nil` (no token available), or returns a token the server no
  longer honors. The former sends the request unauthenticated; the latter
  is indistinguishable from any other `401` at this layer — both resolve
  through the server's response, mapped to `Failure.unauthorized`. MUST —
  `unauthenticated-when-absent`, `maps-401-to-unauthorized`.
- **Resync required.** Input: server responds `410`. `pull`/`push` throw
  `Failure.resyncRequired` and perform no local resync themselves — that
  policy belongs to the caller (`offline-sync-client.md`'s `SyncEngine`).
  MUST — `maps-410-to-resync-required`.
- **Unreachable server / offline device.** Input: `session.data(for:)`
  throws (verified in source with `URLError(.notConnectedToInternet)`).
  The call throws `Failure.transport(String(describing: error))`; no retry
  is attempted by `ADHSyncAPI` itself. MUST —
  `maps-transport-errors`, `ADHSyncAPITests.transportFailureMapping`.
- **Task cancellation mid-request.** Input: the calling `Task` is cancelled
  while `session.data(for:)` is in flight. `URLSession` surfaces this as a
  thrown error (typically `URLError(.cancelled)`), which `perform` catches
  through the same generic `catch` as any other transport error and
  rethrows as `Failure.transport(String(describing: error))`; a caller
  cannot distinguish a user-cancelled request from any other transport
  failure except by inspecting that description string, which is not
  documented as a stable format. MUST — `maps-transport-errors` (this is
  the same code path; it is called out separately here because it is easy
  to overlook that cancellation is not a distinct `Failure` case).
- **Non-HTTP response.** Input: the `URLResponse` returned by
  `session.data(for:)` cannot be cast to `HTTPURLResponse`. `perform`
  throws `Failure.transport("non-HTTP response")`. MUST —
  `maps-non-http-response`.
- **Error body on a non-2xx, non-401, non-410 status.** Input: a `503`
  response body carrying a structured JSON error (as in
  `ADHSyncAPITests.errorMapping`'s `{"error":{"message":"x"}}` fixture).
  `Failure.http(503)` carries only the status code; the body is never read
  for these statuses. MUST — `maps-other-status-to-http`.

