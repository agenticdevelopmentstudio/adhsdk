
### Construction and conformance

- **client-injection**: The component MUST be constructed with exactly one `MailClient` and MUST perform every mail operation through it.
- **tool-source-conformance**: The component MUST conform to the host's tool-source contract by providing a tool-definition list and a call operation taking a tool name and the argument bytes. The host's contract also has a variant of the call operation that takes an optional caller identifier; the component does not implement it, so the contract's default forwards to the plain operation.
- **caller-ignored**: When the host supplies a caller identifier through the contract's caller variant, the component MUST ignore it.
- **stateless**: The component MUST hold no mutable state; each call MUST be independent of every earlier call.

### Tool definitions

- **tool-list-order**: `toolDefinitions()` MUST return exactly seven definitions in this order: `mail_list_accounts`, `mail_list_labels`, `mail_list_messages`, `mail_get_message`, `mail_get_thread`, `mail_modify_labels`, `mail_move_messages`.
- **schema-shape**: Each definition's `parametersJSONSchema` MUST be a JSON object schema with a `properties` map and a `required` array.
- **list-accounts-schema**: `mail_list_accounts` MUST declare no properties and no required arguments.
- **account-argument**: Every tool except `mail_list_accounts` MUST declare a string property `account` ("The account's connection id or email address.") and MUST list it as required.
- **list-labels-required**: `mail_list_labels` MUST require only `account`.
- **list-messages-schema**: `mail_list_messages` MUST declare, besides `account`, the properties `since`, `until`, `cursor` and `query` (strings), `labels` and `any_labels` (string arrays), `limit` (integer) and `include_bodies` (boolean).
- **get-message-required**: `mail_get_message` MUST require `id` as well as `account`, and MUST NOT declare `include_bodies`.
- **get-thread-schema**: `mail_get_thread` MUST require `id` (string) as well as `account`, and MUST declare `include_bodies` (boolean).
- **modify-labels-schema**: `mail_modify_labels` MUST require `message_ids` (string array) as well as `account`, and MUST declare `add` and `remove` (string arrays).
- **move-messages-schema**: `mail_move_messages` MUST require `message_ids` (string array) and `to` (string) as well as `account`, and MUST declare `from` (string array).
- **tool-descriptions**: Each definition MUST carry the description text below, and each property MUST carry its description text, so a model sees the same advertised schema on every platform. Properties not listed here (`account` is covered by **account-argument**) have no description beyond their type.

| Tool or property | Description text |
|------------------|------------------|
| `mail_list_accounts` | Lists the connected mail accounts. |
| `mail_list_labels` | Lists an account's labels. |
| `mail_list_messages` | Lists an account's synced messages, newest first, one page at a time. With query, searches Gmail itself instead, beyond the synced mail. |
| `mail_list_messages` `since` | Earliest date: YYYY-MM-DD or an ISO-8601 timestamp. |
| `mail_list_messages` `until` | Latest date: YYYY-MM-DD or an ISO-8601 timestamp. |
| `mail_list_messages` `labels` | Label ids or names; a message must carry all of them. |
| `mail_list_messages` `any_labels` | Label ids or names; a message must carry at least one of them. Combines with labels. |
| `mail_list_messages` `limit` | Page size, 1 to 500. Defaults to 50. |
| `mail_list_messages` `cursor` | The nextCursor of the previous page. |
| `mail_list_messages` `include_bodies` | Include message bodies. |
| `mail_list_messages` `query` | A Gmail search, in Gmail's syntax (from:greenhouse). since, until and labels narrow it; any_labels can't be combined with it (write {label:a label:b} in the query). |
| `mail_get_message` | Gets one message, with its body. |
| `mail_get_message` `id` | The message id. |
| `mail_get_thread` | Gets a whole conversation from Gmail, oldest message first. A message labelled SENT is one the account wrote. |
| `mail_get_thread` `id` | A thread id, or the id of any message in the thread. |
| `mail_get_thread` `include_bodies` | Include message bodies. |
| `mail_modify_labels` | Adds and removes labels on messages, in Gmail. Give at least one of add or remove. |
| `mail_modify_labels` `message_ids` | The messages to change. |
| `mail_modify_labels` `add` | Label ids or names to add. |
| `mail_modify_labels` `remove` | Label ids or names to remove. |
| `mail_move_messages` | Moves messages to a label, in Gmail: one change that adds the label and removes INBOX, or every label in from. Reports what each message really lost and gained. |
| `mail_move_messages` `message_ids` | The messages to move. |
| `mail_move_messages` `to` | The label id or name to move them to. |
| `mail_move_messages` `from` | Label ids or names to move them out of. Omitted: INBOX (nothing when to is INBOX); empty: nothing, so the label is only added. |

- **schema-not-enforced**: The component MUST NOT rely on the advertised schema for validation; required and typed arguments are checked again when a call arrives.

### Call dispatch

- **argument-decoding**: `callTool` MUST parse `argumentsJSON` as a JSON object; when the data is not valid JSON, or is JSON but not an object, the component MUST treat the arguments as an empty dictionary.
- **result-shape**: `callTool` MUST return a `(content, isError)` pair and MUST NOT throw.
- **success-result**: On success the component MUST return the encoded result with `isError` false.
- **argument-error-result**: A rejected argument MUST return the error's message text as `content` with `isError` true.
- **service-error-result**: Any other error, including a `MailClientError` from the client, MUST return the error's user-facing message as `content` with `isError` true.
- **unknown-tool**: A name outside the seven MUST return `unknown tool <name>` with `isError` true and MUST NOT call the client.
- **no-client-call-on-bad-arguments**: When argument validation fails, the component MUST NOT call the client.

### Result encoding

- **json-format**: A result MUST be encoded by the shared mail JSON encoder as pretty-printed JSON with sorted keys, so object keys appear in alphabetical order regardless of declaration order. The indent width, the date and number encoding and the handling of nil fields are those of `MailJSON` in [adhsdk.ingredient.integrations.service.mail-command-support](cookbook:3d12c073-edc3-44fb-a988-5edec20575e0), which also says that ports need not match Swift byte for byte.
- **result-types**: `mail_list_accounts` MUST return the encoded array of `MailAccount`; `mail_list_labels` the array of `MailLabel`; `mail_list_messages` a `MailMessagePage`; `mail_get_message` a `MailMessage`; `mail_get_thread` a `MailThread`; `mail_modify_labels` an array of `MailMessage`; `mail_move_messages` an array of `MailMoveResult`.
- **encoding-failure**: A value that cannot be encoded, or whose bytes are not UTF-8, MUST surface as an error result through the service-error path.

### Argument parsing

- **required-string**: A required string argument MUST be present, MUST be a JSON string and MUST be non-empty; otherwise the error is `missing required argument: <key>` when absent or empty, or `<key> must be a string` when present with another type.
- **optional-string**: An optional string argument that is absent MUST yield no value; when present with a non-string type the error MUST be `<key> must be a string`.
- **string-array**: An array argument that is absent MUST yield an empty array; when present and not an array of strings the error MUST be `<key> must be an array of strings`.
- **boolean-strict**: `include_bodies` MUST default to false when absent; a JSON number MUST NOT count as a boolean, and a non-boolean MUST yield `include_bodies must be a boolean`.
- **integer-strict**: `limit` MUST be a JSON number with no fractional part that fits a 64-bit signed integer (so `1e10` is accepted) and MUST NOT be a boolean; otherwise, or when it is zero or negative, the error MUST be `limit must be a positive integer`. A number too large for 64 bits, such as `1e30`, is rejected the same way.
- **date-bounds**: `since` and `until` MUST be read by the shared date-bound normaliser, with `since` at the start edge and `until` at the end edge; a value that is not `YYYY-MM-DD` or an accepted ISO-8601 timestamp (see **timestamp-forms**), or a calendar date that does not exist, MUST yield `<key> must be YYYY-MM-DD or an ISO-8601 timestamp`.
- **date-only-expansion**: A `YYYY-MM-DD` value MUST become `<date>T00:00:00.000Z` for `since` and `<date>T23:59:59.999Z` for `until`, the start and end of that UTC day.
- **timestamp-forms**: An accepted timestamp has the form `YYYY-MM-DDTHH:MM:SS`, optionally followed by fractional seconds, and then a required zone designator: `Z` or `z`, or a numeric offset such as `+02:00` or `+0200`. A timestamp with no offset (`2026-01-01T10:00:00`), one without seconds (`2026-01-01T10:00Z`), one with a space or a lowercase `t` in place of `T`, and any other form MUST be rejected with the date-bounds error.
- **timestamp-utc**: An ISO-8601 timestamp, with or without fractional seconds, MUST be converted to UTC in the form `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
- **unknown-arguments-ignored**: An argument the tool does not declare MUST be ignored.

### mail_list_messages

- **filter-mapping**: The component MUST build one `MailMessageFilter` from `account`, `since`, `until`, `labels`, `any_labels`, `limit`, `cursor`, `include_bodies` and `query`, and call `client.messages` once with it.
- **limit-default**: When `limit` is absent the filter MUST keep `MailMessageFilter.defaultLimit` (50).
- **limit-clamp**: A positive `limit` above 500 that passes **integer-strict** MUST be accepted by the tool and clamped into `MailMessageFilter.limitRange` (1 to 500) by the filter, not rejected.
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
- **move-from-absent**: When `from` is absent the component MUST pass `nil` to the client, which the schema description defines as INBOX (when `from` is absent and `to` is INBOX, no label is removed).
- **move-from-empty**: When `from` is present and empty the component MUST pass an empty array, which the schema description defines as "nothing, so the label is only added".
- **move-from-type**: A `from` that is present and not an array of strings MUST yield `from must be an array of strings`.
- **move-call**: A valid call MUST invoke `client.moveMessages` once with the account, ids, destination and `from`.

### Concurrency, persistence and side effects

- **concurrency**: The component MUST be safe to share across concurrent tasks (in Swift, `Sendable`), and every operation that reaches the client MUST be asynchronous.
- **no-serialisation**: The component MUST NOT serialise concurrent calls; any ordering between them is the service's.
- **no-persistence**: The component MUST NOT write files or keep tokens; its only side effects are the `MailClient` requests.
- **write-tools**: Each `mail_modify_labels` or `mail_move_messages` call MUST make exactly one client request, with no idempotency key, and MUST return the service's response unchanged; both change the user's mail at the mail service.
- **no-timeout-no-retry**: The component MUST NOT add a timeout, cancellation hook or retry around the client call; those belong to the `MailClient` transport and the host.

