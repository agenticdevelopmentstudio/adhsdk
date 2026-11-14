
### Session id

- **session-id**: `sessionId` MUST return `hookData["session_id"]` when it is a string, and the empty string when the key is missing or not a string.
- **session-id-not-validated**: `sessionId` MUST NOT trim or validate the value; an empty result is what `ParseResult` later turns into `.skip`.

### Envelope encoding

- **envelope-signature**: `envelopeJSON()` MUST return the envelope as `Data` and MUST throw on failure.
- **envelope-required-keys**: The envelope MUST always carry `event` (the `eventType`, a JSON string), `timestamp` (the `timestamp` string written as given, with no re-formatting, so the encoder does not enforce ISO 8601), `hook_data` (the `hookData`, a JSON object) and `account_email` (the `accountEmail`, a JSON string that is empty when there is no account and never null).
- **envelope-context-when-present**: `context` MUST be written only when it is non-nil.
- **envelope-oauth-when-resolved**: `oauth_account_email` MUST be written only when `oauthAccountEmail` is non-nil, including when it is the empty string, so a round trip preserves the nil that means "this envelope never carried one".
- **envelope-round-trip**: `ParseResult.parse(envelopeJSON:)` of the encoded text, interpreted as UTF-8, MUST return `.event` carrying the same `eventType`, `timestamp`, `accountEmail`, `context` and `oauthAccountEmail` for any event whose `eventType` is non-empty and whose `hookData` has a non-empty string `session_id`.
- **envelope-round-trip-degenerate**: `envelopeJSON()` MUST encode without error an event with an empty `eventType`, which parses back as `.unparseable`, and one whose `hookData` has no non-empty `session_id`, which parses back as `.skip`; the encoder MUST NOT check either, as the parser decides what such an event is.
- **envelope-plain-serialization**: The encoded bytes MUST come from `JSONSerialization.data(withJSONObject:)` with no options, so key order and whitespace are unspecified and a reader MUST parse them as JSON and not compare text.

### Failure

- **not-serializable-pre-check**: Before encoding, `envelopeJSON()` MUST test the dictionary with `JSONSerialization.isValidJSONObject` and MUST throw `EnvelopeEncodingError.notSerializable(eventType)` when it is not valid (a payload holding a value `JSONSerialization` does not take, such as a `Date`, a non-finite number, or a dictionary with non-string keys).
- **other-errors-propagate**: An error thrown by `JSONSerialization.data(withJSONObject:)` after the check passes MUST propagate to the caller unchanged.
- **error-description**: `EnvelopeEncodingError.errorDescription` MUST be the event type followed by ` payload is not JSON-serializable`; for an empty event type the description therefore starts with a space, and the encoder adds no fallback text.
- **error-case**: `EnvelopeEncodingError` MUST have exactly one case, `notSerializable(String)`, whose associated value is the event type, and it MUST conform to `LocalizedError`.

### Concurrency and side effects

- **pure-encode**: `sessionId` and `envelopeJSON()` MUST NOT perform I/O, logging or notification; they read the event's immutable fields, so they MAY run concurrently on one event.
- **caller-handles-error**: The encoder MUST NOT log or retry; the caller that gets the thrown error MUST record the capture failure.

