
**Decision**: No local database in the browser.
**Rationale**: The web app reads through the hub API and keeps no local store, so there is no second sync engine. An in-memory snapshot built from `/v1/sync/pull` is that read: it lasts as long as the page and is never persisted.
**Approved**: pending

**Decision**: `/v1/sync/pull` rather than a per-connection listing.
**Rationale**: The hub's connection-data route does not serve email messages, and the sync pull already returns the caller's Gmail rows owner-scoped, with deletes. Pulling everything and filtering client-side costs more on the first read, but uses a route that exists and is the same contract the native mirrors follow.
**Approved**: pending

**Decision**: Accounts from `/v1/integrations/connections`.
**Rationale**: The connection list carries the address, status and last error the accounts list shows. The native bridge derives the address from sent mail because its mirror has no connection table; the web client has the real list one request away.
**Approved**: pending

**Decision**: Injected fetch.
**Rationale**: The client takes `fetchJson` rather than importing an auth package, so it sits in the lowest tier with no dependencies and works in any host's auth (dependency injection).
**Approved**: pending

**Decision**: Use the hub's `/v1` surface.
**Rationale**: The hub's `/v1` routes are its stable public API (the signup form in `@adh-sdk/ui` moved to them too). With a customer token, `/v1/integrations/connections` returns the caller's own connections; how the hub routes that request is the hub's concern, not the client's.
**Approved**: pending

**Decision**: Snake_case wire types, mapped once to camelCase.
**Rationale**: The `/v1` routes answer snake_case envelopes (`has_more`, `sync_version`, `service_type`) and a list envelope (`object: "list"`, `data`, `has_more`) for connections. The package's wire types say so, and the mapping to the camelCase `HubMail*` types happens once, in the client. A row's `data` keeps the backend's snake_case column names, exactly as the native projection reads them.
**Approved**: pending

