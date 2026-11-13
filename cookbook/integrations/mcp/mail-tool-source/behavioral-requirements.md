
### Construction and conformance

- **client-injection**: The component MUST be constructed with exactly one `MailClient` and MUST perform every mail operation through it.
- **tool-source-conformance**: The component MUST conform to `ChatToolSource` by implementing `toolDefinitions()` and the two-argument `callTool(name:argumentsJSON:)`; the caller-aware overload is inherited and forwards to it, so the caller identifier is ignored.
- **stateless**: The component MUST hold no mutable state; each call MUST be independent of every earlier call.

### Tool definitions

- **tool-list-order**: `toolDefinitions()` MUST return exactly seven definitions in this order: `mail_list_accounts`, `mail_list_labels`, `mail_list_messages`, `mail_get_message`, `mail_get_thread`, `mail_modify_labels`, `mail_move_messages`.
- **schema-shape**: Each definition's `parametersJSONSchema` MUST be a JSON object schema built by `ToolJSONSchema.object`, with a `properties` map and a `required` array.
- **list-accounts-schema**: `mail_list_accounts` MUST declare no properties and no required arguments.
- **account-argument**: Every tool except `mail_list_accounts` MUST declare a string property `account` ("The account's connection id or email address.") and MUST list it as required.
- **list-labels-required**: `mail_list_labels` MUST require only `account`.
- **list-messages-schema**: `mail_list_messages` MUST declare `account` (required), `since`, `until`, `labels`, `any_labels`, `cursor`, `query` (strings or string arrays as named), `limit` (integer) and `include_bodies` (boolean).
- **get-message-required**: `mail_get_message` MUST require `account` and `id`, and MUST NOT declare `include_bodies`.
- **get-thread-schema**: `mail_get_thread` MUST declare `account`, `id` (both required) and `include_bodies`.
- **modify-labels-schema**: `mail_modify_labels` MUST declare `account`, `message_ids` (both required), `add` and `remove`.
- **move-messages-schema**: `mail_move_messages` MUST declare `account`, `message_ids`, `to` (all required) and `from`.
- **schema-not-enforced**: The component MUST NOT rely on the advertised schema for validation; required and typed arguments are checked again when a call arrives.

### Call dispatch

- **argument-decoding**: `callTool` MUST parse `argumentsJSON` as a JSON object; when the data is not valid JSON, or is JSON but not an object, the component MUST treat the arguments as an empty dictionary.
- **result-shape**: `callTool` MUST return a `(content, isError)` pair and MUST NOT throw.
- **success-result**: On success the component MUST return the encoded result with `isError` false.
- **argument-error-result**: A rejected argument MUST return the error's message text as `content` with `isError` true.
- **service-error-result**: Any other error, including a `MailClientError` from the client, MUST return the error's `localizedDescription` as `content` with `isError` true.
- **unknown-tool**: A name outside the seven MUST return `unknown tool <name>` with `isError` true and MUST NOT call the client.
- **no-client-call-on-bad-arguments**: When argument validation fails, the component MUST NOT call the client.

### Result encoding

- **json-format**: A result MUST be encoded by `MailJSON.encode` as pretty-printed JSON with sorted keys, so object keys appear in alphabetical order regardless of declaration order.
- **result-types**: `mail_list_accounts` MUST return the encoded array of `MailAccount`; `mail_list_labels` the array of `MailLabel`; `mail_list_messages` a `MailMessagePage`; `mail_get_message` a `MailMessage`; `mail_get_thread` a `MailThread`; `mail_modify_labels` an array of `MailMessage`; `mail_move_messages` an array of `MailMoveResult`.
- **encoding-failure**: A value that cannot be encoded, or whose bytes are not UTF-8, MUST surface as an error result through the service-error path.

### Argument parsing

- **required-string**: A required string argument MUST be present, MUST be a JSON string and MUST be non-empty; otherwise the error is `missing required argument: <key>` when absent or empty, or `<key> must be a string` when present with another type.
- **optional-string**: An optional string argument that is absent MUST yield no value; when present with a non-string type the error MUST be `<key> must be a string`.
- **string-array**: An array argument that is absent MUST yield an empty array; when present and not an array of strings the error MUST be `<key> must be an array of strings`.
- **boolean-strict**: `include_bodies` MUST default to false when absent; a JSON number MUST NOT count as a boolean, and a non-boolean MUST yield `include_bodies must be a boolean`.
- **integer-strict**: `limit` MUST be a JSON number with no fractional part and MUST NOT be a boolean; otherwise, or when it is zero or negative, the error MUST be `limit must be a positive integer`.
- **date-bounds**: `since` and `until` MUST be read by `MailDateBound.normalize`, with `since` at the start edge and `until` at the end edge; a value that is not `YYYY-MM-DD` or an ISO-8601 timestamp, or a calendar date that does not exist, MUST yield `<key> must be YYYY-MM-DD or an ISO-8601 timestamp`.
- **date-only-expansion**: A `YYYY-MM-DD` value MUST become `<date>T00:00:00.000Z` for `since` and `<date>T23:59:59.999Z` for `until`, the start and end of that UTC day.
- **timestamp-utc**: An ISO-8601 timestamp, with or without fractional seconds, MUST be converted to UTC in the form `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
- **unknown-arguments-ignored**: An argument the tool does not declare MUST be ignored.

### mail_list_messages

- **filter-mapping**: The component MUST build one `MailMessageFilter` from `account`, `since`, `until`, `labels`, `any_labels`, `limit`, `cursor`, `include_bodies` and `query`, and call `client.messages` once with it.
- **limit-default**: When `limit` is absent the filter MUST keep `MailMessageFilter.defaultLimit` (50).
- **limit-clamp**: A positive `limit` above 500 MUST be accepted by the tool and clamped into `MailMessageFilter.limitRange` (1 to 500) by the filter, not rejected.
- **query-not-blank**: A `query` that is present and, once trimmed of whitespace and newlines, empty MUST yield `query must not be empty`; a non-blank query MUST be passed to the filter as written, untrimmed.
- **any-labels-with-query**: The tool MUST pass `any_labels` and `query` through together without checking the combination; `MailClient.messages` rejects the service reply when the service did not apply them.

### mail_get_message and mail_get_thread

- **get-message-call**: `mail_get_message` MUST call `client.message` with the required `account` and `id`.
- **get-thread-call**: `mail_get_thread` MUST call `client.thread` with `account`, `id` and the parsed `include_bodies` (false by default).

### mail_modify_labels

- **modify-ids-required**: `message_ids` MUST be a non-empty array of strings; an empty array MUST yield `message_ids must not be empty`.
- **modify-needs-change**: At least one of `add` or `remove` MUST be non-empty, otherwise the error is `give at least one label in add or remove`.
- **modify-validation-order**: The component MUST read `account`, `message_ids`, `add` and `remove` (type errors first) before it checks that `message_ids` is non-empty and then that `add` or `remove` is non-empty.
- **modify-call**: A valid call MUST invoke `client.modifyLabels` once with the account, ids, `add` and `remove`.

### mail_move_messages

- **move-required**: `account`, `message_ids` and `to` MUST be present; an empty `message_ids` MUST yield `message_ids must not be empty`.
- **move-from-absent**: When `from` is absent the component MUST pass `nil` to the client, which the schema description defines as INBOX (nothing when `to` is INBOX).
- **move-from-empty**: When `from` is present and empty the component MUST pass an empty array, which the schema description defines as "nothing, so the label is only added".
- **move-from-type**: A `from` that is present and not an array of strings MUST yield `from must be an array of strings`.
- **move-call**: A valid call MUST invoke `client.moveMessages` once with the account, ids, destination and `from`.

### Concurrency, persistence and side effects

- **concurrency**: The type is `Sendable`, all work is `async`, and the component serialises nothing; concurrent calls run independently and any ordering between them is the service's.
- **no-persistence**: The component MUST NOT write files, cache results or keep tokens; its only side effects are the `MailClient` requests.
- **write-tools**: `mail_modify_labels` and `mail_move_messages` change the user's mail in Gmail through the service; each call sends one request with no idempotency key and the service's response surfaces unchanged.
- **no-timeout-no-retry**: The component MUST NOT add a timeout, cancellation hook or retry around the client call; those belong to the `MailClient` transport and the host.

