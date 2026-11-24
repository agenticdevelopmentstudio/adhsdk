
| id | input | expected |
|---|---|---|
| hmw-001 | connections: one `gmail`/`messages`, one `github`/`repos` | `accounts()` returns only the Gmail one |
| hmw-002 | connection with `username` "a@x.com" | account `email` is "a@x.com" |
| hmw-003 | connection with empty `username`, `display_name` "Work" | account `email` is "Work" |
| hmw-004 | pull page 1 `has_more: true, cursor: "c1"`, page 2 `has_more: false` | two requests; the first is `/v1/sync/pull?limit=500`, the second has `cursor=c1` |
| hmw-005 | change for `notes.notes` | ignored |
| hmw-006 | upsert then delete of the same id | the message is absent |
| hmw-007 | messages dated 2026-11-01 and 2026-11-03, one undated | order: 11-03, 11-01, undated |
| hmw-008 | row with `is_deleted: true` | not listed |
| hmw-009 | two `messages()` calls before the first pull resolves | one pull request |
| hmw-010 | `refresh()` after a pull that ended with cursor "c9" | request has `cursor=c9` |
| hmw-011 | pull answered 410 | snapshot cleared, pull restarts from empty |
| hmw-012 | `message("conn", "missing")` | null |
| hmw-013 | `fetchJson` rejects with a 500 error on page 2 of a pull | the read rejects; page 1's changes stay applied and the cursor is page 1's |
| hmw-014 | connections page 1 `has_more: true` ending at `g1`, page 2 `has_more: false` | two requests, the second with `starting_after=g1`; both Gmail accounts returned in order |
| hmw-015 | pull answered 410, and the restart is answered 410 too | the read rejects with that error; the snapshot is empty and the client is in failed |
| hmw-016 | `reset()` after a completed pull, then `messages()` | the snapshot is empty and the request has no `cursor` |
| hmw-017 | 3 live messages, `messages(account, 2)` | the 2 newest |
| hmw-018 | `messages(account, 0)` | one message, the newest |
| hmw-019 | `message("conn", id)` for a live row with `body_text` and `body_html` | `bodyText` and `bodyHtml` carry them |
| hmw-020 | two messages with equal `internal_date` and ids "a" and "b" | "b" lists before "a" |
| hmw-021 | `accounts()` called twice | two connection-list requests |
| hmw-022 | `refresh()` called while a pull is in flight | one pull request; both calls resolve when it does |
| hmw-023 | `reset()` while a pull is in flight, its page then resolves, then `messages()` | the late page is not applied; a second pull request with no `cursor` is sent |
