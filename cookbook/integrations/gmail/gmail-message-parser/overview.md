
`GmailMessageParser` is a caseless `enum` of static functions that converts one decoded Gmail API message (`GmailMessageDTO`, requested with `format=full`) into an `EmailMessage` record. It has no state, performs no I/O and raises no errors: every malformed or missing input degrades to an empty value or a fallback. Use it wherever a Gmail message is mirrored into local storage.

The input is a tree of `GmailPart` values (`mimeType`, `filename`, `headers`, `body`, `parts`). `GmailBody` carries `attachmentId`, `size` and base64url `data`. The output is a flat record: sender, recipients, subject, snippet, plain and HTML bodies, label ids, an ISO 8601 date, the history id, a list of attachment references (`EmailAttachmentRef`) and a `MailClass` derived by `MailClassifier.classify` from the label ids. `MailClassifier` and the persistence of the record are separate components.

