
- **Optional columns null**: a nil optional property (`deletedAt`, `lastError`, `bodyText`, `color`) is stored as SQL NULL and read back as nil.
- **Empty collections**: an empty `toAddresses`, `ccAddresses`, `labelIds` or `attachments` is the default and round-trips as an empty array.
- **Empty label ids**: an `EmailMessage` built with `labelIds: []` and no `mailClass` gets `.archived`, because `MailClassifier.classify` finds no filing label.
- **Unknown enum text**: a stored `status` or `mail_class` that is not a known raw value fails to decode through the synthesized `Codable`; the records add no fallback, so the fetch raises the decoding error to the caller.
- **Missing table or column**: a missing table raises the GRDB error to the caller. A row lacking a column that maps to a required property fails to decode with a decoding error; a column that maps to an optional property reads as nil. The schema lives in the store, not here.
- **Free-string fields**: `EmailLabel.type` and `ActionLog.status` accept any text; the documented value sets are comments, not checks.
- **Concurrent access**: records are `Sendable` value types with no shared mutable state, so concurrent use needs no ordering rule; serialisation of database writes belongs to the store.
- **Offline or network failure**: not applicable; the records never touch the network.
- **Boundary values**: `size`, `messagesTotal` and `messagesUnread` are unbounded `Int`s with no range check; range limits for sync settings belong to `MailSyncSettings`.
- **Clock sampling**: default timestamps are read at each initializer call, so two records built in quick succession can differ in the fractional digits.

