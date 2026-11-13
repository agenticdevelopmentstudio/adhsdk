
Vectors derive from `MailToolSourceTests` (Swift Testing) and from the source where a vector is noted as having no test. `ScriptedMail` is the test double behind `MailClient`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-tool-source-001 | tool-list-order | `toolDefinitions()` (test `listsSevenTools`) | names equal the seven names in the stated order |
| mail-tool-source-002 | filter-mapping, date-only-expansion, timestamp-utc | `mail_list_messages` with account `me@example.com`, since `2026-01-01`, until `2026-01-31T10:00:00Z`, labels `Work`, `INBOX`, limit 25, cursor `50`, include_bodies true (test `listMessagesMapsArguments`) | not an error; one filter with since `2026-01-01T00:00:00.000Z`, until `2026-01-31T10:00:00.000Z`, the labels, limit 25, cursor `50`, includeBodies true |
| mail-tool-source-003 | timestamp-utc | since `2026-01-02T03:00:00+02:00` (test `timestampsAreConvertedToUTC`) | filter since is `2026-01-02T01:00:00.000Z` |
| mail-tool-source-004 | filter-mapping, string-array | `labels` `["STARRED"]`, `any_labels` `["INBOX","Job Search/00. Inbox"]` (test `listMessagesMapsAnyLabels`) | not an error; filter carries both lists |
| mail-tool-source-005 | string-array | `any_labels` is the string `INBOX` | error, content `any_labels must be an array of strings` |
| mail-tool-source-006 | filter-mapping | `query` `from:greenhouse` (test `listMessagesMapsQuery`) | not an error; filter query is `from:greenhouse` |
| mail-tool-source-007 | query-not-blank | `query` is two spaces | error, content `query must not be empty` |
| mail-tool-source-008 | integer-strict, boolean-strict, date-bounds, optional-string, no-client-call-on-bad-arguments | each of `limit` 0, `limit` true, `limit` 2.5, `limit` `"5"`, since `yesterday`, until `2026-02-30`, since 20260101, until true, cursor 5, include_bodies `"yes"` (test `badArgumentTypesAreErrors`) | every call is an error and the client receives no request |
| mail-tool-source-009 | integer-strict | `limit` true (test `badLimitMessage`) | content `limit must be a positive integer` |
| mail-tool-source-010 | required-string, no-client-call-on-bad-arguments | `mail_list_labels` with `{}` (test `missingArgumentIsError`) | error, content `missing required argument: account`, no request |
| mail-tool-source-011 | get-thread-call, json-format | `mail_get_thread` account `a`, id `m1`, then id `t1` with include_bodies true (test `getThreadMapsArguments`) | first result equals the encoded thread; requests are getThread with includeBodies false, then true |
| mail-tool-source-012 | required-string | `mail_get_thread` with only `account` | error, content `missing required argument: id` |
| mail-tool-source-013 | json-format, result-types | `mail_get_message` account `a`, id `m1` (test `resultsArePrettySortedJSON`) | content equals the pretty sorted encoding and `"account"` appears before `"id"` |
| mail-tool-source-014 | modify-needs-change | `mail_modify_labels` with `message_ids` `["m1"]` and neither `add` nor `remove` (test `modifyRequiresAddOrRemove`) | error, no request |
| mail-tool-source-015 | modify-call | `message_ids` `["m1","m2"]`, `add` `["Work"]` (test `modifyMapsArguments`) | not an error; request modifyLabels with remove empty |
| mail-tool-source-016 | service-error-result | client replies not found `No message matches “zz”` (test `notFoundIsAnErrorResult`) | error, content is that text |
| mail-tool-source-017 | service-error-result | client replies failure `unknown label: Nope` to `mail_list_accounts` (test `toolErrorSurfacesRemoteFailure`) | error, content `unknown label: Nope` |
| mail-tool-source-018 | move-from-absent, move-from-empty, move-call, json-format | `mail_move_messages` with no `from`, then `from` `["Later"]`, then `from` `[]` (test `moveMapsArguments`) | requests carry from nil, `["Later"]`, `[]`; first result equals the encoded results |
| mail-tool-source-019 | move-required, modify-ids-required, move-from-type | missing `to`; empty `message_ids`; `from` the string `INBOX` (test `moveRejectsBadArguments`) | contents `missing required argument: to`, `message_ids must not be empty`, `from must be an array of strings`; no request |
| mail-tool-source-020 | unknown-tool | `callTool` name `mail_nope`, `{}` | error, content `unknown tool mail_nope` (derived from source; no test) |
| mail-tool-source-021 | argument-decoding | `mail_list_labels` with data `not json` | error, content `missing required argument: account` (derived from source; no test) |
| mail-tool-source-022 | limit-clamp | `mail_list_messages` with limit 1000 | not an error; filter limit is 500 (derived from `MailMessageFilter.clamp`; no test) |

