
**Message shape**

- **message-fields**: `ClaudeStreamMessage` MUST carry `kind`, `subtype` (optional String), `sessionID` (optional String), `blocks` (an array of `Block`), `isError` (Bool), `resultText` (optional String), `numTurns` (optional Int) and `errors` (an array of String), and MUST be `Sendable` and `Equatable`.
- **message-init-defaults**: The `ClaudeStreamMessage` initializer MUST require `kind` and MUST default `subtype`, `sessionID`, `resultText` and `numTurns` to `nil`, `blocks` and `errors` to empty arrays and `isError` to `false`.
- **message-kinds**: `ClaudeStreamMessage.Kind` MUST have the cases `systemInit`, `assistant`, `user` and `result`, plus `other` carrying the original type string.
- **block-fields**: `ClaudeStreamMessage.Block` MUST carry `kind`, `text`, `name`, `id` and `toolUseID`, where all but `kind` are optional Strings, and its initializer MUST default each optional field to `nil`.
- **block-kinds**: `Block.Kind` MUST have the cases `text`, `toolUse`, `toolResult`, `thinking` and `other`.

**Decoding a line**

- **decode-not-json-throws**: `decode(_:)` MUST throw `DecodingError.dataCorrupted` with the debug description "not JSON" when the line is not parseable JSON, including an empty line, and MUST carry the parser error as the underlying error.
- **decode-not-object-throws**: `decode(_:)` MUST throw `DecodingError.dataCorrupted` with the debug description "not a JSON object" when the line parses but its top level is not an object.
- **decode-kind-mapping**: `decode(_:)` MUST map `type` `"assistant"` to `.assistant`, `"user"` to `.user`, `"result"` to `.result`, and `"system"` with `subtype` `"init"` to `.systemInit`.
- **decode-kind-other**: `decode(_:)` MUST map any other `type` to `.other(type)` with the type string unchanged, including a `"system"` message whose subtype is not `"init"`.
- **decode-missing-type**: `decode(_:)` MUST map an object with no string `type` to `.other("")`.
- **decode-subtype**: `decode(_:)` MUST copy a string `subtype` into `subtype` and leave it `nil` otherwise.
- **decode-session-id**: `decode(_:)` MUST read `sessionID` from the key `session_id` when it is a string.
- **decode-is-error**: `decode(_:)` MUST read `isError` from the key `is_error` when it is a Bool and MUST default it to `false` otherwise.
- **decode-result-text**: `decode(_:)` MUST read `resultText` from the key `result` when it is a string.
- **decode-num-turns**: `decode(_:)` MUST read `numTurns` from the key `num_turns` when it is an integer.
- **decode-errors**: `decode(_:)` MUST read `errors` from the key `errors` when it is an array, keeping only the string elements in order and dropping the others; it MUST yield an empty array when the key is missing or not an array.
- **decode-ignores-unknown**: `decode(_:)` MUST ignore keys it does not read; they cause no error.

**Content blocks**

- **blocks-from-array**: When `message.content` is an array of objects, `decode(_:)` MUST produce one `Block` per element, in order.
- **blocks-from-string**: When `message.content` is a string, `decode(_:)` MUST produce exactly one `.text` block carrying that string.
- **blocks-otherwise-empty**: `decode(_:)` MUST produce an empty `blocks` array when `message` is missing or not an object, or when its `content` is neither a string nor an array of objects.
- **block-text**: A content element with `type` `"text"` MUST become a `.text` block whose `text` is the element's `text` string.
- **block-thinking**: A content element with `type` `"thinking"` MUST become a `.thinking` block whose `text` is the element's `thinking` string.
- **block-tool-use**: A content element with `type` `"tool_use"` MUST become a `.toolUse` block carrying the element's `name` and `id`, and no text; the tool input is not carried.
- **block-tool-result-string**: A `"tool_result"` element whose `content` is a string MUST become a `.toolResult` block whose `text` is that string and whose `toolUseID` is the element's `tool_use_id`.
- **block-tool-result-parts**: A `"tool_result"` element whose `content` is an array of objects MUST become a `.toolResult` block whose `text` is the `text` strings of the parts that have one, joined with a newline.
- **block-tool-result-no-content**: A `"tool_result"` element whose `content` is neither a string nor an array of objects MUST become a `.toolResult` block with `text` of `nil`.
- **block-other**: A content element with any other `type`, or none, MUST become a `.other` block with every field `nil`.

**Lost session**

- **lost-session-text**: `ClaudeStreamMessage.lostSessionText` MUST equal `"No conversation found"`, which is what claude says on stdout and stderr alike when `--resume` names a session it does not have.
- **reports-lost-session**: `reportsLostSession` MUST be true only when `kind` is `.result`, `isError` is true and at least one entry of `errors` contains `lostSessionText` as a substring.
- **lost-session-not-other-errors**: `reportsLostSession` MUST be false for an error result whose `errors` do not contain `lostSessionText`, such as an authentication or quota failure before any turn ran.

**Input line**

- **user-message-shape**: `ClaudeStreamInput.userMessage(_:)` MUST return UTF-8 JSON for an object with `type` `"user"` and `message` an object with `role` `"user"` and `content` an array of one element `{"type":"text","text":<the text>}`.
- **user-message-newline**: `userMessage(_:)` MUST end its output with a single line feed byte (`0x0A`).
- **user-message-slashes**: `userMessage(_:)` MUST NOT escape forward slashes in the text.
- **user-message-key-order**: `userMessage(_:)` MUST NOT promise a key order; the source requests none.
- **user-message-cannot-fail**: `userMessage(_:)` MUST NOT return a failure for any Swift string; a serialisation failure is a programmer error that stops the process with a precondition failure, because a user message is plain strings and always serializes.

