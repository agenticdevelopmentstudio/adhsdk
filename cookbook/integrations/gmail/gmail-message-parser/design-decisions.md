
**Decision**: An unnamed `message/rfc822` is treated as an embedded message whose text is used only when the message has no body of its own, and a named part is always a file.
**Rationale**: A bounce's original or a forwarded `.eml` carries a body that is not this message's body. The source comments say nothing inside it "is this message's body, though the files inside it are still listed", while a wrapper with nothing but an embedded message would otherwise show empty.
**Approved**: pending

**Decision**: The embedded fallback is all or nothing: one own body of either kind suppresses both embedded bodies.
**Rationale**: The code gates on `hasOwnBody` (own text or own HTML) and then replaces both fields, so an own HTML-only message never takes the embedded plain text. This keeps the two bodies from coming from different messages.
**Approved**: pending

**Decision**: A named part without an `attachmentId` is neither the body nor an attachment.
**Rationale**: The source comment states "A named part is a file even when Gmail inlined it; it is never the message body." The cost is that an inlined named file is dropped from the record, because an `EmailAttachmentRef` needs an `attachmentId` to be fetched later.
**Approved**: pending

**Decision**: The declared charset wins when it decodes; otherwise the parser tries UTF-8, then ISO Latin-1.
**Rationale**: Test `decodesLatin1Charset` notes that bytes C3 A9 are valid UTF-8 and only the declared charset makes the result a different string. ISO Latin-1 is the last resort because it accepts any byte sequence, so decoding never fails after valid base64url.
**Approved**: pending

**Decision**: A message with no usable date sorts as now rather than as the epoch, and the `now` argument is injectable.
**Rationale**: The doc comment on `now` says the date is given so the message "sorts as new rather than as 1970". Injection makes the fallback testable.
**Approved**: pending

**Decision**: `internalDate` takes precedence over the `Date` header, and the header is read only in three fixed layouts after removing a trailing comment.
**Rationale**: `internalDate` is Gmail's own value and numeric when present, while the `Date` header is sender-controlled text. The layouts and comment stripping follow the doc comment "with or without the weekday and a trailing comment" and miss other legal RFC 5322 forms.
**Approved**: pending

**Decision**: Address splitting is a hand-written scanner that respects quotes and backslash escapes, and it does not parse mailboxes.
**Rationale**: Display names such as `"Doe, Jane"` contain commas, so a plain comma split is wrong. The splitter keeps each mailbox as raw text and leaves interpretation to callers. Unbalanced quotes are not repaired.
**Approved**: pending

**Decision**: Deliberate prudent debt: undecodable body data is dropped without a signal, and recursion over parts has no depth limit.
**Rationale**: Both affect malformed or hostile input only, and the source handles neither. Revisit the silent drop when the sync worker needs to show or count messages whose body failed to decode; revisit the depth limit when the parser reads messages from a source other than the Gmail API, or when a crash from a deeply nested message is reported. Until then a port copies both behaviors, or adds a deliberate signal or limit and says so.
**Approved**: pending

**Decision**: Whether a dropped body should be surfaced is open: today `undecodable-body-data` yields nil with no log, error or flag.
**Rationale**: Settling it needs the Gmail API contract for `data` and a decision from the owner of the sync worker. The recipe states the current behavior as a MUST until then.
**Approved**: pending

**Decision**: The parser is not pure: it keeps no shared state, but `createdAt`, `updatedAt` and the generated id read the wall clock and a random UUID inside `parse`, and `now` feeds only the date fallback.
**Rationale**: `EmailMessage` initializer defaults supply `createdAt` and `updatedAt`, and `UUID()` supplies the id, so none of them is injectable. The cost is that `record-defaults` and `generated-id` can only be asserted loosely. Feeding `now` into both timestamps and injecting an id generator would make them exact; revisit when a test needs exact values.
**Approved**: pending

