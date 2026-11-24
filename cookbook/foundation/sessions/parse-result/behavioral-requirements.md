
### Cases

- **four-cases**: The enum MUST have exactly the cases `.event(ParsedEvent)`, `.skip(reason: String)`, `.lostEvent` and `.unparseable`.
- **sendable**: `ParseResult` MUST be `Sendable`; its `ParsedEvent` ([adhsdk.ingredient.foundation.sessions.parsed-event](cookbook:81735174-d7d7-4103-87df-7be5944c78cc)) payload is `@unchecked Sendable`, so the guarantee rests on `ParsedEvent` never being mutated, which holds because every stored property of `ParsedEvent` is a `let`.

### Parsing

- **parse-signature**: `ParseResult.parse(envelopeJSON:)` MUST take the envelope as a `String` and return a `ParseResult`; it MUST NOT throw.
- **empty-is-lost**: Text that is empty or only whitespace and newlines MUST return `.lostEvent`, decided before any JSON parsing, so the live scan and the quarantine retry cannot disagree on what "empty" means.
- **not-an-object-is-unparseable**: Text that is not a JSON object (invalid JSON, a JSON array, string, number or `null`, or valid JSON followed by trailing text) MUST return `.unparseable`.
- **missing-event-is-unparseable**: An object whose `event` key is missing, not a string or an empty string MUST return `.unparseable`.
- **event-check-before-session-check**: The `event` check MUST come first, so an object with no usable `event` is `.unparseable` even when it also has no `session_id`.
- **missing-session-is-skip**: An object with a usable `event` whose `hook_data.session_id` is missing, not a string or empty MUST return `.skip(reason: "no session_id — not a trackable session event")`; this is a deliberate discard, never an error (a StatusLine drop that carries only `term_session_id` is the example).
- **hook-data-fallback**: A `hook_data` that is missing or not an object MUST be read as an empty object, which then fails the session check and returns `.skip`.
- **event-fields**: A parseable envelope MUST return `.event` whose `eventType` is the `event` string and whose `hookData` is the `hook_data` object unchanged.
- **timestamp-default**: `timestamp` MUST be the envelope's string value, and the empty string when the key is missing or not a string.
- **context-optional**: `context` MUST be the envelope's `context` object when it is an object, and nil otherwise; it is present in v5+ drops and absent in legacy v4 drops and hand-written fixtures.
- **account-email-default**: `accountEmail` MUST be the `account_email` string, and the empty string when the key is missing or not a string.
- **oauth-email-nil-when-absent**: `oauthAccountEmail` MUST be the `oauth_account_email` string when present, including an empty string, and nil when the key is missing or not a string; nil means the envelope predates the field and empty means "resolved, no oauth login".
- **json-null-is-absent**: A JSON `null` value for any key the parser reads MUST be treated as that key being absent.
- **extra-keys-ignored**: Keys the parser does not read MUST be ignored without error.
- **no-session-id-on-result**: The result MUST NOT store `session_id`; callers MUST read it from `hookData` or `ParsedEvent.sessionId`.

### Ordering and side effects

- **pure-function**: `parse(envelopeJSON:)` MUST be a pure function of its argument: no file, network, log or notification effect, so it MAY be called concurrently from any thread.
- **single-decoder**: Every capture path that reads an envelope (drop-file scan, spool drain, quarantine retry) MUST decode through this function; this type only classifies the text, and callers act on the outcome themselves.

