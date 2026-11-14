
The left column of the mail window. It shows a source-list outline: each mail account is a group row labeled with its email address, and that account's mailboxes sit beneath it. A mailbox row carries a symbol, the mailbox title indented by nesting depth, and an unread count when there is one. It owns no mail state: it reads `accounts`, `mailboxes` and `selectedMailbox` from `MailBrowserModel`, and it calls `select(mailbox:)` on it when the user picks a mailbox.

The sidebar reads these fields from `MailBrowserModel` (see the model ingredient for the full type):

| Field | Type | Used for |
|-------|------|----------|
| account `id` | string | Key into `mailboxes`; matched against a mailbox's `accountId`. |
| account `email` | string | Account group row text. |
| mailbox `accountId` | string | Selection matching and the id sent to the model. |
| mailbox `labelId` | optional string | Symbol choice and selection matching; nil is All Mail. |
| mailbox `title` | string | Row text and accessibility label. |
| mailbox `depth` | integer | Row indent. |
| mailbox `unread` | optional integer | Trailing count. |
