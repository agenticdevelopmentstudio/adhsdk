
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
| hub-mail-013 | query-filters | `HubMailQuery` with `labelIds` `["INBOX", "Label_1"]`, then `anyLabelIds` `["Label_1", "SENT"]` | Only the message carrying both; then the messages carrying either, newest first |
| hub-mail-014 | query-filters | `since`/`until` around one of three dates | Only that message |
| hub-mail-015 | message-by-either-id | `message(connectionId: "c1", id:)` with the row id, the provider id, and another connection's row id | The message, the message, nil |
| hub-mail-016 | local-label-write | `applyLabels` adding `Label_1` and `UNREAD`, removing `INBOX`, on a message labelled `INBOX`, `UNREAD` at version 6, plus a missing id | Labels `UNREAD`, `Label_1`; version still 6; the missing id is skipped |
| hub-mail-017 | label-write-action | `modifyLabels` with message `g1`, add `Label_1`, remove `INBOX` | The path ends in `/actions/modify_labels`, the body carries `message_ids`, `add_label_ids` and `remove_label_ids`, the result is ok |
| hub-mail-018 | truncate-own-tables | Truncate with only the messages resource, with both tables holding rows | The messages table is empty; the labels table keeps its rows |
| hub-mail-019 | keyset-paging | A page with `limit` 0, then `limit` 9999, over 600 messages | 1 message; 500 messages |
| hub-mail-020 | pull-only | A `HubMailSync` over a transport that also enrolls a third resource | Only the two mail resources are mirrored, and neither is pushed |
| hub-mail-021 | label-write-action, send-errors | The fake client answers 403 to `modifyLabels` | `HubMailSendError.rejected(statusCode: 403)` |
| hub-mail-022 | send-action | The fake client answers 200 with `ok` false, `error` "quota" and `deduped` true | The result is returned, not thrown, with `ok` false, `error` "quota" and `deduped` true |
| hub-mail-023 | edge case: undated | One dated message and one with a null `internal_date` | The undated one lists last and pages by id among undated peers |
| hub-mail-024 | typed-columns | A change naming a column the projection does not know | It is ignored; the row's known columns store normally |
| hub-mail-025 | typed-columns | `label_ids` arriving as the string `["INBOX"]`, then as the array `["INBOX"]` | Both read back as `["INBOX"]`, stored once as that text and once encoded |
| hub-mail-026 | messages-newest-first | A message whose stored `label_ids` is not valid JSON, under a label filter | The message matches no label filter and the query does not fail |
| hub-mail-027 | local-label-write | `applyLabels` adding `INBOX` to a message already labelled `INBOX` | The message carries `INBOX` once |
| hub-mail-028 | soft-delete | Delete a message, then read the table directly | The row remains with `deleted_at` set and its content columns intact |
| hub-mail-029 | numbers-never-trap | Upsert a label with `messages_total` 1e19, `messages_unread` 3.7 and `parent_name` 1e19 | `messagesTotal` nil, `messagesUnread` 3, `parentName` `1e+19` |
