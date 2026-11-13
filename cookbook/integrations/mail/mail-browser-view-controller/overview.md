
The content of the mail window. It lays out three panes side by side: a sidebar of mailboxes, the selected mailbox's message list, and a reader for the open message. A host app puts it in a window; it needs only a mail client, which it hands to a `MailBrowserModel` that holds all state and actions (the three pane controllers read and call that model).

This controller owns three things the panes do not: the split layout (pane order, widths, remembered divider positions), a background poll that reloads the model when a sync has finished, and the alert that reports the model's error message. It is the composition root for the mail window, not a place for mail logic.

