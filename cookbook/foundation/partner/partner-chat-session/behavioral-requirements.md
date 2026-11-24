
Construction and transcript

- **transcript-seed**: The session MUST start with the `initial` messages passed to its initializer as its transcript, in the given order.
- **transcript-grows-by-owner-lines**: The session MUST append each message passed to `noteUserMessage` to the end of its transcript.
- **transcript-grows-by-assistant-text**: The session MUST append each assistant reply it creates in `apply` to the end of its transcript.
- **transcript-never-cleared**: `clear()` MUST be a no-op: the session MUST leave its transcript unchanged when it is called.

Event stream

- **event-payloads**: The events the session emits MUST carry these payloads: `.transcriptLoaded([ChatMessage])`, `.userMessage(ChatMessage)`, `.stateChanged(ChatSessionState)`, `.responseStarted(messageID)`, `.responseDelta(messageID, text)`, `.toolCall(messageID, name, phase)` with phase `.started` or `.completed`, `.responseFinished(messageID, stopReason)` and `.turnFailed(ChatError)`, where `messageID` is a string id and `ChatError` carries a `message` and an `isRetryable` flag.
- **events-replay-transcript**: Each stream returned by `events()` MUST yield `.transcriptLoaded` carrying the transcript as it stood at the moment of the call as its first event.
- **events-single-subscriber**: A call to `events()` MUST finish the stream returned by the previous call, so that only the newest stream receives later events.
- **events-no-buffer-without-subscriber**: An event emitted while no stream is attached (before the first `events()` call, or after `close()`) MUST NOT be buffered or replayed; only the transcript is replayed to a new stream.
- **state-not-replayed**: A stream MUST NOT receive the state set by an earlier `setState` call; a new stream sees `.transcriptLoaded` followed only by later events.
- **events-never-throw**: The stream MUST report a failed turn as `.turnFailed` and keep the stream open, never by ending the stream with an error.

Outbound and lifecycle operations

- **send-forwarding**: `send(_:)` MUST call the injected send closure exactly once with the text unchanged.
- **send-no-local-effect**: `send(_:)` MUST NOT append to the transcript and MUST NOT emit an event; the owner's line enters the transcript only through `noteUserMessage`.
- **interrupt-forwarding**: `interrupt()` MUST call the injected interrupt closure exactly once.
- **close-signals-closed**: `close()` MUST yield `.stateChanged(.closed)` to the attached stream and then finish that stream.
- **close-detaches**: After `close()`, the session MUST hold no stream, so later events are dropped until `events()` is called again.
- **close-without-stream-silent**: `close()` with no attached stream MUST emit nothing.
- **use-after-close**: After `close()` the session MUST keep accepting `apply`, `noteUserMessage` and `setState` without failing; their events go to no stream until a new one is attached by `events()`.
- **close-keeps-transcript**: `close()` MUST NOT modify the transcript.
- **note-user-message**: `noteUserMessage(_:)` MUST append the message to the transcript and then emit `.userMessage` carrying that message.
- **set-state-emits**: `setState(_:)` MUST emit `.stateChanged` carrying the given `ChatSessionState` to the attached stream.

Folding stream messages (`apply`)

- **apply-returns-persistable**: `apply` MUST return the assistant `ChatMessage` values it appended during that call, in block order, and MUST return an empty array for every message that appended none.
- **assistant-text-block**: For each assistant block of kind `.text` whose text is non-nil and non-empty, `apply` MUST create one `ChatMessage` with role `.assistant` and that text.
- **assistant-text-events**: For each such reply, `apply` MUST emit `.responseStarted`, then one `.responseDelta` carrying the whole text, then `.responseFinished` with `stopReason` nil, all with the reply's message id.
- **assistant-empty-text-skipped**: `apply` MUST skip an assistant text block whose text is nil or empty: no message, no event.
- **assistant-current-id**: `apply` MUST record the id of the newest assistant reply as the current assistant message id.
- **tool-use-started**: For each assistant block of kind `.toolUse`, `apply` MUST emit `.toolCall` with phase `.started`, the block's name (or `"tool"` when the name is nil), and the current assistant message id.
- **tool-name-registry**: When a `.toolUse` block has both an `id` and a `name`, `apply` MUST remember the name under that id for later tool results; a block missing either MUST NOT be remembered.
- **assistant-other-blocks-ignored**: `apply` MUST ignore assistant blocks of any kind other than `.text` and `.toolUse` (thinking, tool result, other).
- **tool-result-completed**: For each block of kind `.toolResult` in a message of kind `.user`, `apply` MUST emit `.toolCall` with phase `.completed`, the name remembered for the block's `toolUseID` (or `"tool"` when the id is nil or unknown), and the current assistant message id.
- **user-other-blocks-ignored**: `apply` MUST emit nothing for a `.user` message's blocks of any kind other than `.toolResult`, and MUST return an empty array; this is why the owner's replayed line produces no event.
- **fresh-message-id**: When a tool event is emitted and no current assistant message id exists, the session MUST mint a new globally unique string identifier, keep it as the current id, and reuse it for later tool events in the same turn; no `.responseStarted` is emitted for that id.
- **result-ends-turn**: For a message of kind `.result`, `apply` MUST clear the current assistant message id.
- **result-failure-text**: When a `.result` has `isError` true, `apply` MUST emit `.turnFailed` carrying a `ChatError` whose message is the first available of `resultText`, `subtype`, and the literal `"error"`.
- **result-failure-retryable**: The `ChatError` emitted for an error `.result` MUST have `isRetryable` true.
- **result-ready**: For every `.result`, error or not, `apply` MUST emit `.stateChanged(.ready)` after any `.turnFailed`.
- **system-init-and-other-ignored**: `apply` MUST emit nothing and return an empty array for messages of kind `.systemInit` and `.other`.

Concurrency

- **lock-guarded-state**: The session MUST guard its transcript, attached stream, tool-name registry and current assistant message id with one lock so that any thread may call any operation. The type is `@unchecked Sendable` for this reason, and the send and interrupt closures are `@Sendable`.
- **yield-outside-lock**: The session MUST deliver events to the stream after releasing the lock, so a consumer's work never runs while the lock is held.
- **cross-thread-event-order**: Callers MUST NOT rely on the order of events across threads: the session does not make a state change and its matching event one atomic step, so when two threads call it at once, the order of their events on the stream is the order in which each call reaches its yield, not necessarily the order in which their changes were applied to the transcript. The partner controller, which is `@MainActor`, is the only caller of `apply`, `noteUserMessage` and `setState` in the source, so in practice those calls are serialised by the main actor.

