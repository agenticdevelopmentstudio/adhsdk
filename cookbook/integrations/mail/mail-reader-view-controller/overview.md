
The reader pane of the mail window. It shows the open message's headers (subject, sender, recipients, date) above the message body, and a placeholder reading "No message selected" when no message is open. A host puts it in the reader slot of the mail window and gives it the shared `MailBrowserModel`; it reads the model's open message and holds no mail logic of its own.

The body is shown in a web view with JavaScript off and every remote load blocked, so opening a message never tells its sender it was read (tracking pixels) and never runs the message's scripts. A "Load Remote Images" button lifts the block for the message on screen only. Links open in the default browser, never inside the reader. The privacy and navigation rules are the purpose of this component; the headers are a plain label stack.

