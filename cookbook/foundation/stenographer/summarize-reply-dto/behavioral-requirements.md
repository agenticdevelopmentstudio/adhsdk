
- **fields**: `SummarizeReplyDTO` MUST carry `sessionId` (String), `summary` (String, optional) and `error` (String, optional), all constants.
- **initializer**: The public initializer MUST take `sessionId` and default `summary` and `error` to nil.
- **success-shape**: A successful reply MUST carry the stored summary in `summary` and leave `error` nil.
- **failure-shape**: A failed reply MUST carry the failure description in `error` and leave `summary` nil.
- **session-id-always**: Every reply, successful or failed, MUST carry the `sessionId` of the session that was summarized.
- **reason-surfaced**: A consumer that receives a reply with an `error` MUST show that text as the failure reason in place of a generic message.
- **transport-failure-distinct**: A missing reply (nil from the XPC call) MUST be treated as "transport or encoding failed", not as a reply with an `error`.
- **codable-equatable**: The type MUST conform to `Codable`, `Sendable` and `Equatable`, so two replies with the same fields compare equal.
- **exclusivity-by-convention**: The type does not enforce that exactly one of `summary` and `error` is set; the initializer accepts both nil and both set, and the producer MUST set exactly one.
- **no-coding-keys**: The type declares no `CodingKeys`, so its coded key names are its property names (`sessionId`, `summary`, `error`) under a default coder, and `session_id` only under a snake_case strategy.

