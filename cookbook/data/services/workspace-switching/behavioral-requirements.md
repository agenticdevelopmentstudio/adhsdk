
- **every-row-read**: The every-row read state MUST resolve to the result of
  the all-rows operation: every workspace row the caller can switch to,
  teams included, in the backend's order.
- **every-row-cache-entry**: The every-row read state MUST cache its rows on
  the toolkit's own query client under the workspace-rows cache key, so
  every reader on that client shares one entry.
- **every-row-enabled-default**: The every-row read state's `enabled` option
  MUST default to `true`.
- **every-row-disabled-no-request**: While `enabled` is `false` (the
  signed-out case), the every-row read state MUST NOT issue a request.
- **every-row-no-retry**: The every-row read state MUST NOT retry a failed
  read; the failure MUST surface on the returned query result.
- **every-row-refetch-on-change**: When this copy of the package announces
  that the workspace list changed, a mounted, enabled every-row reader MUST
  refetch and resolve to the new rows.
- **every-row-subscribe-on-read**: Mounting an every-row reader MUST
  subscribe its query client to workspace-list-changed announcements made by
  any other copy of the package, through Resource Data's subscription for
  announcements made elsewhere, and each such announcement MUST invalidate
  the workspace-rows entry on that client.
- **every-row-one-subscription-per-client**: The every-row read state MUST
  hold at most one such subscription per query client however many readers
  are mounted on it, so one announcement invalidates the entry once per
  client.
- **every-row-own-announcement-one-sweep**: An announcement this copy made
  MUST invalidate the workspace-rows entry exactly once on this copy's
  client (the announcement's own direct invalidation), however many readers
  are mounted.
- **every-row-subscription-refcount**: The subscription MUST stay in place
  while any reader on that client is mounted, and MUST be removed when the
  last one unmounts.
- **composite-id-format**: The composite-id helper, given a row's `type` and
  `slug`, MUST return `<type>:<slug>`.
- **composite-id-carries-type**: Two rows with the same slug and different
  types MUST get different composite ids.
- **list-label-trimmed-name**: The list-label helper MUST return the row's
  `name` with leading and trailing whitespace removed when that is not
  empty, for every type, the individual workspace included.
- **list-label-blank-individual**: The list-label helper MUST return
  `My Workspace` for an individual row whose name is empty or whitespace.
- **list-label-blank-other**: The list-label helper MUST return `Workspace`
  for an organization or team row whose name is empty or whitespace.
- **list-label-never-empty**: The list-label helper MUST NOT return an empty
  string.
- **first-per-slug-keeps-first**: The first-per-slug helper MUST keep the
  first row of each slug and drop every later row with that slug.
- **first-per-slug-order**: The first-per-slug helper MUST keep the
  surviving rows in their input order and return the same row values it was
  given, of whatever row shape.
- **row-helpers-pure**: The three row helpers MUST be pure functions with no
  UI-framework or network dependency.
- **preference-shared-entry**: The workspace-preference read state MUST read
  and write the caller's preference row through the shared item cache under
  the cache key `workspace-prefs` and the item id `me`, both exported so
  every reader and writer of the row shares one entry.
- **preference-load**: The workspace-preference read state MUST load the
  row with Resource Data's workspace-preferences read operation.
- **preference-disabled**: While `enabled` is `false`, the
  workspace-preference read state MUST NOT read the row and MUST report
  `slug` as `null` and `settled` as `false`.
- **preference-enabled-default**: The workspace-preference read state's
  `enabled` option MUST default to `true`.
- **preference-seed-browser-cache**: Until the row is in, the
  workspace-preference read state MUST report the slug held in the browser's
  cached-workspace storage, or `null` when none is held.
- **preference-seed-read-each-render**: The browser-cache seed MUST be read
  on every render while enabled, never captured once at mount.
- **preference-server-row-wins**: Once the row is in, the
  workspace-preference read state MUST report the row's `slug`, and MUST
  report `null` when the row carries no slug.
- **preference-failed-read**: When the row's read fails, the
  workspace-preference read state MUST keep reporting the browser-cache seed.
- **preference-settled**: `settled` MUST be `true` once the row is in or its
  read has failed, and `false` before that.
- **preference-slug-not-validated**: The workspace-preference read state
  MUST NOT check the slug against the caller's workspaces; the caller holds
  the list and decides what a slug outside it means.
- **preference-choose-order**: Choosing a slug MUST write it to the browser's
  cached-workspace storage, then re-render the reader, then write it into the
  shared item-cache entry, then send it to the server with Resource Data's
  workspace-preferences write operation as `{ slug }`.
- **preference-choose-shows-at-once**: After a choice, the reader MUST
  report the chosen slug without waiting for the server.
- **preference-choose-put-failure-silent**: A failed server write MUST NOT
  raise, and MUST leave the choice standing in both caches; the next choice
  writes again, and nothing retries this one.
- **preference-choose-survives-first-read**: A choice made while the first
  read is in flight MUST NOT be overwritten when that read lands.

