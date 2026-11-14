
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-mail-bridge-001 | provider-configured | `providerStatus` | configured, no client id |
| hub-mail-bridge-002 | admin-refused | `signIn`, `removeAccount`, `updateSettings`, `importOAuthClient` | each `.failure`; the mirror is unchanged |
| hub-mail-bridge-003 | accounts-from-connections, account-address | Connection `c1` with a SENT message from `Me <Me@X.com>`, connection `c2` with none | accounts `c1` (`me@x.com`) and `c2` (`c2`), active |
| hub-mail-bridge-004 | account-lookup | `listLabels` for `ME@x.com`, then for `nobody` | the labels of `c1`; then not found |
| hub-mail-bridge-005 | labels-mapped | Labels `INBOX` (system) and `Label_1` "Work" | `INBOX`, then `Label_1` named "Work" |
| hub-mail-bridge-006 | messages-filtered, label-resolution | Filter `labels: ["Work"]` over messages with and without `Label_1` | only the `Label_1` messages |
| hub-mail-bridge-007 | messages-filtered, any-labels-applied | `anyLabels: ["INBOX", "SENT"]` | messages carrying either, `appliedAnyLabels` true |
| hub-mail-bridge-008 | messages-filtered | `since`/`until` around one of three dates | only that message |
| hub-mail-bridge-009 | opaque-cursor | Three messages, limit 2, then the cursor back | 2 then 1, the second page's cursor nil |
| hub-mail-bridge-010 | opaque-cursor | Cursor `"zzz"` | `.failure("bad cursor")` |
| hub-mail-bridge-011 | query-refused | `query: "from:a"` | `.failure`; `query: "  "` lists normally |
| hub-mail-bridge-012 | label-resolution | `labels: ["Nope"]` | `.failure("unknown label: Nope")` |
| hub-mail-bridge-013 | bodies-on-request, message-mapping | `getMessage` by provider id for a message with only an HTML body | the hub row id, the provider id, the label names, the HTML read as text |
| hub-mail-bridge-014 | bodies-on-request | `listMessages` without `includeBodies` | no bodies |
| hub-mail-bridge-015 | thread-lookup | `getThread` by a message id of a three-message thread | the three, oldest first, `id` the thread id |
| hub-mail-bridge-016 | modify-through-hub, mirror-write | Add "Work", remove `INBOX` on one message | one write with the provider id, `["Label_1"]`, `["INBOX"]`; the answer and a re-read show the new labels; the row's sync version is unchanged |
| hub-mail-bridge-017 | modify-through-hub | Nothing to add or remove | no write; the message unchanged |
| hub-mail-bridge-018 | move-through-hub | Move two messages, one already in "Work" and out of INBOX, to "Work" | one write for the other message only; results name `Work` added and `INBOX` removed for it, nothing for the first |
| hub-mail-bridge-019 | move-through-hub | Move to INBOX from `["INBOX"]` | `.failure` |
| hub-mail-bridge-020 | write-failure | The writer throws | `.failure` with its message; the mirror unchanged |
| hub-mail-bridge-021 | sync-now | `syncNow(account: nil)` | the pull ran once; `.ok` |
| hub-mail-bridge-022 | client-transport | `MailClient` from `client` calls `accounts()` | the same accounts as `listAccounts` |

