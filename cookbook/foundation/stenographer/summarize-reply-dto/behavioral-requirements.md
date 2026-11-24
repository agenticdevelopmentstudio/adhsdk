
- **fields**: `SummarizeReplyDTO` MUST carry `sessionId` (String), `summary` (String, optional) and `error` (String, optional), all constants.
- **initializer**: The public initializer MUST take `sessionId` and default `summary` and `error` to nil.
- **success-shape**: A successful reply MUST carry the stored summary in `summary` and leave `error` nil.
- **failure-shape**: A failed reply MUST carry the failure description in `error` and leave `summary` nil.
- **session-id-always**: Every reply, successful or failed, MUST carry the `sessionId` of the session that was summarized.
- **codable-equatable**: The type MUST conform to `Codable`, `Sendable` and `Equatable`, so two replies with the same fields compare equal.
- **exclusivity-by-convention**: A producer MUST set exactly one of `summary` and `error`. The type does not enforce this: the initializer and the decoder accept both nil and both set (see the Design Decisions).
- **no-coding-keys**: The type MUST NOT declare `CodingKeys`, so its coded key names are its property names (`sessionId`, `summary`, `error`) under a default coder, and `session_id` only under a snake_case strategy.
- **wire-coders**: Anything that carries this type in the snake_case shape `{session_id, ...}` MUST encode and decode it with `StenographerWire.encoder()` and `StenographerWire.decoder()`; the snake_case shape depends on them.

