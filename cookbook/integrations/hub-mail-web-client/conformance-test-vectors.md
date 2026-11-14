
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
| hmw-013 | `fetchJson` rejects with a 500 error | the read rejects; the earlier snapshot is kept |
| hmw-014 | connections page 1 `has_more: true` ending at `g1`, page 2 `has_more: false` | two requests, the second with `starting_after=g1`; both Gmail accounts returned in order |

