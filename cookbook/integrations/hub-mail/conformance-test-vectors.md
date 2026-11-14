
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-mail-001 | typed-columns, upsert-revives | Upsert a message with `to_addresses` `["a@x"]`, `label_ids` `["INBOX"]` | `message(id:)` returns it with `to == ["a@x"]`, `labelIds == ["INBOX"]` |
| hub-mail-002 | soft-delete, live-rows-only | Delete it with version 7 | `message(id:)` is nil; the projection's sync version is 7 |
| hub-mail-003 | upsert-revives | Upsert it again | `message(id:)` returns it |
| hub-mail-004 | live-rows-only | Upsert a message with `is_deleted` true | It is in no read |
| hub-mail-005 | messages-newest-first, keyset-paging | Five messages, limit 2 | Pages of 2, 2, 1, newest first; the last page's `next` is nil |
| hub-mail-006 | messages-newest-first | Label filter `INBOX` over messages labelled `INBOX` and `SENT` | Only the `INBOX` messages |
| hub-mail-007 | labels-by-connection | A user label "Alpha" and the system label "INBOX" | `INBOX` first |
| hub-mail-008 | thread-oldest-first | Three messages in one thread | Oldest first |
| hub-mail-009 | connections | Messages on two connections | Both ids, sorted |
| hub-mail-010 | pull-only, sign-out-purges | A scripted pull of one message and one label through `HubMailSync`, then `signOut` | After sync both read back; after sign-out, none |
| hub-mail-011 | send-action | A fake client answering ok with external id `g1` | The input names the connection and `send`, carries the fields, and the result is ok with `g1` |
| hub-mail-012 | send-errors | The fake client answers 401 | `HubMailSendError.rejected(statusCode: 401)` |

