
`ParsedEventEnvelope.swift` extends `ParsedEvent` with two members and declares one error. `sessionId` reads the session the event belongs to from its payload, so a spool row can be indexed by session without decoding every envelope. `envelopeJSON()` re-encodes the event as the drop-file envelope, the same shape `ParseResult.parse(envelopeJSON:)` reads. The spool stores that one opaque blob and round-trips it through the parser every other capture path already uses, so spooling adds no second format and no second decoder. `EnvelopeEncodingError` says why an event could not be written to the spool.

The envelope is built at capture time, never at drain time: the envelope builder resolves the live `claude` process by cwd and reads its environment, so the facts in `context` are only true when the hook fires, and a later build would attribute an event to whatever process holds that cwd minutes afterwards.

