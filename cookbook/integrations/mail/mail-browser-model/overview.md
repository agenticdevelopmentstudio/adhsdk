
`MailBrowserModel` is the state behind the mail window. It holds the accounts, each account's sidebar mailboxes, the selected mailbox's messages a page at a time, and the open message. The source comment says "Every action the window offers goes through here, so this is the tested unit; the view controllers only read it and call it."

It is a `@MainActor` `ObservableObject` built on a `MailClient` given at initialization. A mailbox is a Gmail label, or All Mail (a mailbox with no label id). The model also supplies the display text the list and reader show: the sender name, the list date and the full date. It reads the local mail store through the client and marks a message read when it is opened.

