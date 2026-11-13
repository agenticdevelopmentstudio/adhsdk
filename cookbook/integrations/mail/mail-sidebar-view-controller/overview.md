
The left column of the mail window. It shows a source-list outline: each mail account is a group row labeled with its email address, and that account's mailboxes sit beneath it. A mailbox row carries a symbol, the mailbox title indented by nesting depth, and an unread count when there is one. It owns no mail state: it reads `accounts`, `mailboxes` and `selectedMailbox` from `MailBrowserModel`, and it calls `select(mailbox:)` on it when the user picks a mailbox.

