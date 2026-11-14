
`ParseResult` is a `Sendable` enum that reports what `ParseResult.parse(envelopeJSON:)` made of one drop-file's text. It replaces an overloaded `nil` with four cases so a valid but untracked event can never be mistaken for a malformed one: `.event(ParsedEvent)` is to be ingested, `.skip(reason:)` is well-formed but intentionally not tracked (no `session_id`) and is discarded quietly, `.lostEvent` is an empty file whose writer died before filling it, and `.unparseable` is malformed JSON or a missing event type and is a real error to quarantine.

The parser reads the envelope `{"event": "PreToolUse", "timestamp": "...", "hook_data": {...}, "context": {...}}` plus the optional `account_email` and `oauth_account_email` keys. It is the inverse of `ParsedEvent.envelopeJSON()`; the spool, the quarantine retry and the live drop scan all go through it, so there is one decoder.

