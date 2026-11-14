
Hub Mail is how an app reads mail the ADH hub already synced from Gmail, without talking to Gmail itself. The hub's Gmail worker fills two owner-scoped tables, `integration.integration_email_messages` and `integration.integration_email_labels`, and enrolls them for app sync. `AgenticDeveloperHubSDKHubMail` pulls them through the [sync engine](cookbook:355a8f54-aee5-45cd-a28d-12c3b7a3085c) and the [hub sync transport](cookbook:6edbc7b8-b533-4cca-b62d-74b92ce3f650) into a local SQLite mirror of its own, then answers typed questions over it: which connections and labels there are, a page of messages under a label, one message, one thread. Sending goes the other way, through the hub's `send` integration action, so the hub's worker talks to Gmail.

It is a separate store from the direct macOS Gmail worker in `AgenticDeveloperHubSDKIntegrations`, by design: the two never share tables, so either can be removed without touching the other. It builds for macOS and iOS; the iOS app has no Gmail code at all and reads only through this.

Four types make it up:

- `HubMailProjection`, a `SyncMirrorProjection` that keeps the two resources in typed tables (`hub_email_messages`, `hub_email_labels`).
- `HubMailStore`, the read API over those tables, plus `applyLabels`, which writes a label change the hub has accepted into the mirror until the next pull.
- `HubMailSync`, which wires the projection, a `GRDBSyncStore` and a `SyncEngine` over one database and exposes sync-now and sign-out.
- `HubMailSender`, which sends a message, or changes a message's labels, through the hub client's generated `APIProtocol`.

