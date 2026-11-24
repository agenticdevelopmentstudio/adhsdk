
`ParsedEvent` is a struct holding one Claude Code hook event in the form the daemon ingests: the event type string, a timestamp string, the hook's payload (`hookData`), an optional `context` of facts about the live `claude` process, the `accountEmail` the event was fingerprinted to, and an optional `oauthAccountEmail`. The oauth login is resolved when the hook fires and carried on the event, not looked up at write time; that capture-time requirement belongs to the hook-capture producer, and the reasoning is in Design Decisions.

It is produced by the drop-file parser (`ParseResult.parse(envelopeJSON:)`, Parse Result ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1))) or the envelope builder (the Unix socket path) and consumed by the daemon's ingestion handler.

It is `@unchecked Sendable`: the dictionaries are built once and never mutated afterwards, so the value can cross task boundaries even though the compiler cannot prove it. The type has no behavior beyond storing its fields; the envelope encoding and `sessionId` accessor live in an extension in `ParsedEventEnvelope.swift` (Parsed Event Envelope ([adhsdk.ingredient.foundation.sessions.parsed-event-envelope](cookbook:7dfeb441-3681-45d3-a11b-049294168607))).

