
`SummarizeReplyDTO` is the reply payload for `summarizeSession`: `{session_id, summary}` on success and `{session_id, error}` on failure. Carrying the failure reason lets the app's manual Summarize show the daemon's own reason (for example the local-model memory guard's refusal) instead of a generic failure, which matches the HTTP twin's `error.localizedDescription`. A nil XPC reply remains "transport or encoding failed", a different case from a reply that carries an `error`.

The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SummarizeReplyDTO.swift`, which imports only `Foundation`. It is a `public struct` that is `Codable`, `Sendable` and `Equatable`, with three constants and a public initializer. The `{session_id, ...}` shape above is the snake_case spelling of `StenographerWire` ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)); under a default coder the keys are `sessionId`, `summary` and `error`.

No code in the repository builds or reads this type today. The in-repo path that carries the same information is HTTP: `StenographerHTTPClient.summarize` ([adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6)) throws `SummarizeDaemonFailure` with the daemon's reason.

Guidance for a consumer, which belongs to the consumer's own spec and is not a rule of this type: show a reply's `error` text as the failure reason in place of a generic message, and treat a missing reply (nil from the XPC call) as "transport or encoding failed", not as a reply with an `error`.

