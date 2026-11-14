
- **claims-two-resources**: The projection MUST claim exactly `integration.integration_email_messages` and `integration.integration_email_labels`.
- **typed-columns**: The projection MUST store each backend column under its own name in a typed column, keep JSON array and object columns (`to_addresses`, `cc_addresses`, `label_ids`, `attachments`, `color`) as JSON text, and keep `sync_version` and `deleted_at` for the store.
- **upsert-revives**: An upsert MUST replace the row's columns, take the change's sync version and clear `deleted_at`, so a deleted row that comes back is live again.
- **soft-delete**: A delete MUST keep the row as a tombstone with `deleted_at` set, and take the delete's sync version when it has one.
- **live-rows-only**: Every read MUST skip rows with `deleted_at` set or `is_deleted` true; the backend's worker sets `is_deleted` on mail Gmail removed.
- **truncate-own-tables**: Truncate MUST empty only the tables of the resources it is given.
- **connections**: `connections()` MUST return the distinct connection ids that have live messages or labels, sorted.
- **labels-by-connection**: `labels(connectionId:)` MUST return that connection's live labels, system labels first, then by name.
- **messages-newest-first**: `messages(...)` MUST return live messages newest first by `internal_date`, then by id descending, optionally narrowed to one connection and to messages whose `label_ids` contain one label.
- **keyset-paging**: A page MUST hold at most `limit` messages (clamped to 1...500) and a `next` cursor that is non-nil exactly when more messages follow; passing it back MUST return the messages after the last one, with no repeats or gaps while the rows do not change.
- **thread-oldest-first**: `thread(connectionId:threadId:)` MUST return the thread's live messages oldest first.
- **pull-only**: `HubMailSync` MUST register both resources as pull-only with the sync store, because the hub refuses pushes to worker-owned tables, and MUST pass both as the engine's `hostResources` so no other enrolled table is mirrored.
- **sign-out-purges**: `signOut()` MUST pause the engine, purge every mirrored row, cursor and outbox entry for the departing identity, then resume.
- **send-action**: `HubMailSender.send` MUST post the `send` action for the connection with `to`, `cc`, `bcc`, `subject`, `bodyText` and `bodyHtml`, and return the result's `ok`, `externalId`, `deduped` and `error`.
- **send-errors**: A non-200 answer MUST throw `HubMailSendError.rejected(statusCode:)`.

