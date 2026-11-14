
A web app in the Temporal family (whatsnow.today's `/email` and the Email Desktop App on `/desktop`) shows the same hub-synced Gmail the macOS and iOS apps read from their local mirror ([adhsdk.ingredient.integrations.hub-mail](cookbook:a6442464-e17d-451e-b47a-3be23a2dc753)). The web app keeps no local database, so it does not run a second sync engine: `createHubMailClient` reads the hub API directly and holds what it read in memory for the life of the page.

It is the package `@adh-sdk/hub-mail` (`packages/web/packages/hub-mail/`). It has no runtime dependencies. The host injects one function, `fetchJson(path)`, that resolves a backend path (`/sync/pull?…`, `/integrations/me/connections`) to parsed JSON with the caller's bearer token, so the package never reads tokens, storage or a base URL itself. A host that already has an authed fetch (whatsnow's `adh-auth`, or `@adh-sdk/auth`'s `authedJson`) passes it in.

What it does:

- **Accounts** come from `GET /integrations/me/connections`, keeping the caller's Gmail message connections (`provider` `gmail`, `serviceType` `messages`). Each account carries the connection id, a display address, its status and its last error.
- **Messages** come from `GET /sync/pull`. The client pages from an empty cursor until `hasMore` is false, keeps only the two Gmail resources (`integration.integration_email_messages` and `integration.integration_email_labels`), applies each upsert and delete to its snapshot, and remembers the cursor. A later `refresh()` pulls only what changed since.
- **One message** is the snapshot's row for that connection and id, with its full body.

It answers the same three reads the iOS Email App asks of `MailClient` (`accounts`, `messages(account)`, `message(account, id)`), with the same field names the Desktop Email App renders, so the web Email App mirrors the native one.

