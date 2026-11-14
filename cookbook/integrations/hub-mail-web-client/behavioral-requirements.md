
- **injected-fetch**: The client MUST make every request through the injected `fetchJson(path)` and MUST NOT read tokens, storage, cookies or a base URL itself.
- **accounts-from-connections**: `accounts()` MUST call `/integrations/me/connections` once per call and return one account per connection whose `provider` is `gmail` and `serviceType` is `messages`, in the order the hub returned them.
- **account-fields**: An account's `id` MUST be the connection id, its `email` MUST be the connection's `username`, else its `displayName`, else its id; `status` and `lastError` MUST be the connection's (`lastError` null when absent).
- **pull-until-done**: The first read of messages MUST page `/sync/pull?cursor=<c>&limit=500`, starting from an empty cursor, passing each response's `cursor` to the next request, until a response has `hasMore` false.
- **resource-filter**: Changes for any resource other than the two Gmail resources MUST be ignored, and their cursor still advances.
- **apply-changes**: An `upsert` MUST replace the snapshot row with that id; a `delete` MUST remove it. Changes MUST be applied in the order received.
- **live-rows-only**: A message row whose `deleted_at` is set or whose `is_deleted` is true MUST NOT be returned.
- **one-pull-at-a-time**: Concurrent reads that need a pull MUST share one in-flight pull rather than start a second.
- **refresh-delta**: `refresh()` MUST pull from the remembered cursor, not from empty, and resolve when `hasMore` is false.
- **cursor-expired**: A pull answered with HTTP 410 MUST clear the snapshot and cursor and pull again once from an empty cursor.
- **messages-order**: `messages(account)` MUST return that connection's live messages newest first by `internal_date`, rows with no date last, ties by id descending, at most `limit` (default 50).
- **message-summary-fields**: Each listed message MUST carry `id`, `account` (the connection id), `threadId`, `from`, `to`, `cc`, `subject`, `snippet`, `date` (the `internal_date`) and `labelIds`, with missing text fields as null and missing lists as empty.
- **message-detail**: `message(account, id)` MUST return the listed fields plus `bodyText` and `bodyHtml`, or null when the snapshot has no live row for that connection and id.
- **errors-propagate**: A failure from `fetchJson` other than 410 MUST reject the read with that error and leave the snapshot and cursor as they were.
- **reset**: `reset()` MUST drop the snapshot and cursor, so the next read pulls from empty (a host calls it on sign-out).

