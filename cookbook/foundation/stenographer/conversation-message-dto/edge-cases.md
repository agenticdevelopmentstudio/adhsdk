
- **Empty conversation**: a session with no lines yields an empty `messages`, `isComplete` true and `nextAfterId` nil. The page MUST say so, per `testAnEmptyConversationIsCompleteAndEmpty`.
- **Cursor at the newest message**: asking after the newest id yields an empty page that is complete, with `nextAfterId` echoing the cursor asked with. This MUST hold so a follower can poll with the same id.
- **Unknown cursor id**: an `afterId` or `throughId` that names no message of the session is refused with `unknownMessageId`; it MUST NOT return an empty page. The daemon checks the transcript line the id falls in (the id divided by the block stride of 1000, per **row-identity** in Conversation Entry DTO ([adhsdk.ingredient.foundation.stenographer.conversation-entry-dto](cookbook:08d59319-de4b-438a-a144-dcf3912aa2e5)): id = line id × 1000 + block index), not the block index, so only an id whose line is absent from the session is refused.
- **Unknown kind**: a `kind` string the fold does not know maps to `model`, never to an error. This is the fold's default branch.
- **Shared timestamp**: two transcript entries with one timestamp are told apart by id, so paging stays exact; `testWalkingPageByPageGivesTheWholeConversation` walks across a shared second.
- **Cursor ordering**: ids are not ordered across a resumed session's files, so a reader MUST NOT compare ids as a measure of age or count.
- **Boundary limit**: this code does not bound `limit`; a limit of 0 or a negative value is not rejected here. The daemon's `ConversationStore.conversationMessages` raises it to 1 (`max(limit, 1)`), and an entry larger than the limit is returned whole.
- **Concurrent access**: all four types are immutable value types marked `Sendable`; there is no shared mutable state, so concurrent reads are safe.
- **Error and offline states**: these types make no network or database call; a failed read surfaces as the daemon's error, of which `ConversationRangeError` is the one case this code defines.

