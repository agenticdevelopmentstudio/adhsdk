
`AIInteractionDTO` is one LLM call the daemon made: a summarizer or oversight completion, logged at the shared `DaemonAIChat` chokepoint so the AI Log window (over XPC) and `GET /ai/interactions` (over HTTP) can show exactly what was asked and answered. It is an immutable, `Codable`, `Sendable`, `Equatable` value type with fourteen fields and one derived property, `isFailure`.

List reads truncate the three long text fields (`systemPrompt`, `userPrompt`, `response`) SQL-side, setting `truncated` to true when anything was cut. A by-id read returns the full text with `truncated` false. The type itself performs no truncation; it only carries the result.

