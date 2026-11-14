
- **No local database in the browser.** The plan settles that the web app reads through the hub API and keeps no local store, so there is no second sync engine. An in-memory snapshot built from `/sync/pull` is that read: it lasts as long as the page and is never persisted.
- **`/sync/pull` rather than a per-connection listing.** The hub's connection-data route does not serve email messages, and `/sync/pull` already returns the caller's Gmail rows owner-scoped, with deletes. Pulling everything and filtering client-side costs more on the first read, but uses a route that exists and is the same contract the native mirrors follow.
- **Accounts from `/integrations/me/connections`.** The connection list carries the address, status and last error the accounts list shows. The native bridge derives the address from sent mail because its mirror has no connection table; the web client has the real list one request away.
- **Injected fetch.** The client takes `fetchJson` rather than importing an auth package, so it sits in the lowest tier with no dependencies and works in any host's auth (dependency injection).
- **Legacy paths, camelCase envelope.** `/sync/pull` and `/integrations/me/connections` answer camelCase envelopes; a row's `data` keeps the backend's snake_case column names, exactly as the native projection reads them.

