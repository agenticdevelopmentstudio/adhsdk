
- **Malformed arguments**: Invalid JSON or a non-object JSON value MUST be read as an empty dictionary, so the call fails with the first missing required argument rather than a parse error. A tool that needs no arguments (`mail_list_accounts`) still runs.
- **Empty required string**: An empty `account`, `id` or `to` MUST be treated as missing.
- **Null values**: A JSON null for `limit` is neither a number nor a boolean and is therefore rejected with `limit must be a positive integer`; a null string is rejected with `<key> must be a string`.
- **Fractional or boolean limit**: `2.5` and `true` MUST be rejected; `limit` of zero or less MUST be rejected; a limit above 500 MUST be accepted and clamped to 500.
- **Impossible calendar date**: `2026-02-30` MUST be rejected, not rolled over into March.
- **Date-only until**: The upper bound covers the whole day through `23:59:59.999Z`.
- **Inverted range**: A `since` later than `until` is not checked; the component passes both on and the service decides.
- **Empty id arrays**: `message_ids` empty MUST be rejected for both write tools; an `add` or `remove` array containing empty strings is not checked here.
- **Both change lists empty**: `mail_modify_labels` with empty `add` and empty `remove` MUST be rejected.
- **Unknown or extra input**: An unknown tool name MUST be an error result; extra arguments MUST be ignored.
- **Unencodable result**: A result the encoder cannot encode, or whose bytes are not UTF-8, is thrown by the encoder and comes back as an error result with its description. No test double can produce one, so no vector covers it.
- **Error flow**: A service failure, a not-found reply, a thread request to an older service, a reply of the wrong shape or a query or `any_labels` the service ignored all arrive as a thrown `MailClientError` and MUST come back as an error result carrying its description.
- **Unreachable or slow service**: A transport failure surfaces as an error result with the transport error's `localizedDescription`; the component sets no timeout and does not retry. Offline behavior belongs to the transport.
- **Concurrent calls**: Calls are independent and unserialised. Two writes to the same message have whatever outcome the service gives them; this component adds no ordering rule.
- **Cancellation**: Cancelling the awaiting task is the client's business; the component installs no handler and does not catch cancellation separately.
- **Large results**: A page of up to 500 messages with bodies is returned whole as one string; the component does not truncate.

