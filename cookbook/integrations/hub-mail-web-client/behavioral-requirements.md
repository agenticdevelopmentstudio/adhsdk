
- **injected-fetch**: The client MUST make every request through the injected `fetchJson(path)` and MUST NOT read tokens, storage, cookies or a base URL itself.
- **accounts-from-connections**: `accounts()` MUST read `/v1/integrations/connections?limit=100`, then each following page with `starting_after=<last id>` while `has_more` is true, and return one account per connection whose `provider` is `gmail` and `service_type` is `messages`, in the order the hub returned them.
- **account-fields**: An account's `id` MUST be the connection id, its `email` MUST be the connection's `username`, else its `display_name`, else its id, where an empty `username` or `display_name` counts as missing and falls through to the next option; `status` MUST be the connection's, and `lastError` its `last_error` (null when absent).
- **pull-until-done**: The first read of messages MUST page `/v1/sync/pull?limit=500` with no cursor, then `/v1/sync/pull?cursor=<c>&limit=500` passing each response's `cursor` to the next request, until a response has `has_more` false.
- **resource-filter**: Changes for any resource other than the two Gmail resources MUST be ignored, and their cursor still advances.
- **apply-changes**: An `upsert` MUST replace the row with that id in that resource's table of the snapshot; a `delete` MUST remove it. Each resource has its own table, so a message id and a label id never collide. Changes MUST be applied in the order received.
- **live-rows-only**: A message row whose `deleted_at` is set or whose `is_deleted` is true MUST NOT be returned.
- **one-pull-at-a-time**: Concurrent reads that need a pull MUST share one in-flight pull rather than start a second.
- **refresh-delta**: `refresh()` MUST pull from the remembered cursor, not from empty, and resolve when `has_more` is false. A `refresh()` that arrives while a pull is in flight MUST join that pull rather than start another.
- **accounts-uncached**: `accounts()` MUST fetch the connection list on every call.
- **cursor-expired**: A pull answered with HTTP 410 MUST clear the snapshot and cursor and pull again once from an empty cursor. A 410 is recognised by the numeric `status` property that a `fetchJson` rejection carries (see Configuration). If that second pull also fails, including with another 410, the read MUST reject with that error and the client is in **failed**.
- **messages-order**: `messages(account)` MUST return that connection's live messages newest first by `internal_date`, rows with no date last, ties by id descending, at most `limit` (default 50); a `limit` below 1 MUST be treated as 1.
- **message-summary-fields**: Each listed message MUST carry `id`, `account` (the connection id), `threadId`, `from`, `to`, `cc`, `subject`, `snippet`, `date` (the `internal_date`) and `labelIds`, with missing text fields as null and missing lists as empty.
- **message-detail**: `message(account, id)` MUST return the listed fields plus `bodyText` and `bodyHtml`, or null when the snapshot has no live row for that connection and id.
- **errors-propagate**: A failure from `fetchJson` other than 410 MUST reject the read with that error. Pages already applied stay in the snapshot, and the cursor stays at the last applied page, so the next read continues from there.
- **reset**: `reset()` MUST drop the snapshot and cursor, so the next read pulls from empty (a host calls it on sign-out). A pull still in flight when `reset()` runs MUST NOT apply its pages, move the cursor or mark the client pulled, and the next read MUST start a new pull rather than join it.

