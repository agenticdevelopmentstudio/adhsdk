
- **Null / empty input**: Missing context is carried as the empty string (`projectName`, `gitBranch`, `sessionName`, `termProgram`), never as null in the model. `text` may be empty. A decoder MUST NOT treat these empty strings as missing.
- **Boundary values**: `id` is the row id times 1000 plus an offset, so an offset of 1000 would collide with the next row's first id. The daemon prevents it by keeping only the first 1000 blocks of an entry, counted before the work-output filter (`maxLinesPerConversationEntry`, a private constant in `ConversationStore`); later blocks are dropped (test: testAnEntryLongerThanTheIdStrideCannotCollideWithTheNextOne). The DTO itself does not check.
- **Concurrent access**: Not applicable: the type is an immutable value and `Sendable`.
- **Error states**: A missing always-present key fails decoding, and with a list payload that fails the whole decode of the array, not only one row. A missing `termProgram` is tolerated. An unknown `kind` decodes, and `isFromUser` and `isWorkOutput` are false for it.
- **Offline / disconnected state**: Not applicable: the type does no networking; transport failures belong to the HTTP client and XPC service.
- **Older daemon, newer app**: The app can be newer than the daemon answering it; the tolerant decode keeps the feed rendering with an empty `termProgram` rather than blanking it. A daemon newer than the app simply sends keys the app ignores.
- **Page boundaries**: Pages are cut on `timestamp`, and every block of one transcript entry carries the same timestamp, so a page holds whole entries, except that an entry larger than the page limit is emitted whole. This is the daemon's rule and not the DTO's; the DTO's `id` is never a page cursor.

