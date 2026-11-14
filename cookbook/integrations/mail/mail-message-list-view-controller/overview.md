
The middle column of the mail window. It shows the selected mailbox's messages as a single-column table with no header. Each row carries the sender, the date, the subject and a snippet, and an unread message is drawn in bold with an accent dot. It owns no mail state: it reads `messages`, `selectedMessageId`, `loading` and `hasMore` from `MailBrowserModel` ([adhsdk.ingredient.integrations.mail.mail-browser-model](cookbook:b3edb32d-7473-464b-acfb-c19cdd44e99e)), and it calls `select(messageId:)` and `loadMore()` on it. Reaching the last row loads the next page.

