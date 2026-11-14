
`ADHSyncTransport` is the `SyncTransport` a hub app hands to the [sync engine](cookbook:355a8f54-aee5-45cd-a28d-12c3b7a3085c) so the engine pulls from and pushes to the ADH hub. It wraps `ADHSyncAPI` from the hub client, which owns the HTTP: the `GET sync/pull` and `POST sync/push` routes, the bearer token and the status codes. The transport adds the two things the API leaves out: it turns the raw bytes into the engine's wire types (`SyncPullResponse`, `SyncPushRequest`, `SyncPushResponse`) and it turns the API's `Failure` into `SyncTransportError`, the only error vocabulary the engine reacts to.

It lives in its own framework, `AgenticDeveloperHubSDKHubSync`, so a hub app links it beside the engine without the engine itself ever depending on the hub client. Any app that mirrors hub tables uses it; Temporal's hub mail is the first.

