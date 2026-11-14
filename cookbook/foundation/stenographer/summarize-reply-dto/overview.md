
`SummarizeReplyDTO` is the reply payload for `summarizeSession`: `{session_id, summary}` on success and `{session_id, error}` on failure. Carrying the failure reason lets the app's manual Summarize show the daemon's own reason (for example the local-model memory guard's refusal) instead of a generic failure, which matches the HTTP twin's `error.localizedDescription`. A nil XPC reply remains "transport or encoding failed", a different case from a reply that carries an `error`.

It is a `Codable`, `Sendable`, `Equatable` value type with three constants.

