
The middle column of the mail window. It shows the selected mailbox's messages as a single-column table with no header. Each row carries the sender, the date, the subject and a snippet, and an unread message is drawn in bold with an accent dot. It owns no mail state: it reads `messages`, `selectedMessageId`, `loading` and `hasMore` from `MailBrowserModel`, and it calls `select(messageId:)` and `loadMore()` on it. Reaching the last row loads the next page.

