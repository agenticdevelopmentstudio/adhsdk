
### Session id

- **session-id**: `sessionId` MUST return `hookData["session_id"]` when it is a string, and the empty string when the key is missing or not a string.
- **session-id-not-validated**: `sessionId` MUST NOT trim or validate the value; an empty result is what `ParseResult` later turns into `.skip`.

### Envelope encoding

- **envelope-signature**: `envelopeJSON()` MUST return the envelope as `Data` and MUST throw on failure.
- **envelope-required-keys**: The envelope MUST always carry `event` (the `eventType`), `timestamp`, `hook_data` (the `hookData`) and `account_email` (the `accountEmail`).
- **envelope-context-when-present**: `context` MUST be written only when it is non-nil.
- **envelope-oauth-when-resolved**: `oauth_account_email` MUST be written only when `oauthAccountEmail` is non-nil, including when it is the empty string, so a round trip preserves the nil that means "this envelope never carried one".
- **envelope-round-trip**: `ParseResult.parse(envelopeJSON:)` of the encoded text, interpreted as UTF-8, MUST return `.event` carrying the same `eventType`, `timestamp`, `accountEmail`, `context` and `oauthAccountEmail` for any event whose `eventType` is non-empty and whose `hookData` has a non-empty string `session_id`.
- **envelope-round-trip-degenerate**: An event with an empty `eventType` encodes successfully but parses back as `.unparseable`, and one whose `hookData` has no non-empty `session_id` parses back as `.skip`; the encoder does not check either, as the parser decides what such an event is.
- **envelope-plain-serialization**: The encoded bytes MUST come from `JSONSerialization.data(withJSONObject:)` with no options, so key order and whitespace are unspecified and a reader MUST parse them as JSON and not compare text.
- **envelope-at-capture-time**: A caller MUST build the envelope at capture time, on the hook delivery with the event in hand, and not at drain time; the type cannot enforce this and relies on its callers.

### Failure

- **not-serializable-pre-check**: Before encoding, `envelopeJSON()` MUST test the dictionary with `JSONSerialization.isValidJSONObject` and MUST throw `EnvelopeEncodingError.notSerializable(eventType)` when it is not valid (a payload holding a value `JSONSerialization` does not take, such as a `Date`, a non-finite number, or a dictionary with non-string keys).
- **not-serializable-reason**: The check runs on the hook delivery so a bad payload costs one logged capture failure, not a stored row that fails to decode on every drain forever.
- **other-errors-propagate**: An error thrown by `JSONSerialization.data(withJSONObject:)` after the check passes MUST propagate to the caller unchanged.
- **error-description**: `EnvelopeEncodingError.errorDescription` MUST be the event type followed by ` payload is not JSON-serializable`.
- **error-case**: `EnvelopeEncodingError` MUST have exactly one case, `notSerializable(String)`, whose associated value is the event type, and it MUST conform to `LocalizedError`.

### Concurrency and side effects

- **pure-encode**: `sessionId` and `envelopeJSON()` MUST NOT perform I/O, logging or notification; they read the event's immutable fields, so they MAY run concurrently on one event.
- **caller-handles-error**: The encoder does not log or retry; the caller that gets the thrown error records the capture failure.

