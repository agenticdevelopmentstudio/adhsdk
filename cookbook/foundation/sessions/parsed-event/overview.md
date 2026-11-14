
`ParsedEvent` is a struct holding one Claude Code hook event in the form the daemon ingests: the event type string, a timestamp string, the hook's payload (`hookData`), an optional `context` of facts about the live `claude` process, the `accountEmail` the event was fingerprinted to, and an optional `oauthAccountEmail`. It is produced by the drop-file parser (`ParseResult.parse(envelopeJSON:)`) or the envelope builder (the Unix socket path) and consumed by the daemon's ingestion handler.

It is `@unchecked Sendable`: the dictionaries are built once and never mutated afterwards, so the value can cross task boundaries even though the compiler cannot prove it. The type has no behavior beyond storing its fields; the envelope encoding and `sessionId` accessor live in an extension in `ParsedEventEnvelope.swift`.

