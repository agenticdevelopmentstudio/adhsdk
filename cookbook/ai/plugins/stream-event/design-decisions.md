
**Decision**: `consume(_:)` and `finish()` are both non-throwing; a frame that cannot be decoded simply yields no event, with no distinct error signal.
**Rationale**: This keeps every conforming decoder simple — none of the five shipped decoders (`ClaudeSSEDecoder`, `OpenAIReplyDecoder`, `GeminiReplyDecoder`, `OpenAICompatibleReplyDecoder`, `PlainTextDecoder`) needs error-propagation plumbing — but it means a genuinely malformed, unrecoverable frame is indistinguishable from one that is merely incomplete and awaiting more bytes; both currently vanish silently. This is the same gap the behavior described under decode-failure-signal documents.
**Approved**: pending

**Decision**: `AIStreamEvent` declares five cases — `textDelta`, `thinkingDelta`, `toolUse`, `usage`, `end` — and reasoning and token usage are first-class events rather than metadata on `end`.
**Rationale**: An agent host streams the model's thinking separately from its answer and accounts for cost per request, so both must arrive while the response is still streaming. Reporting usage as a cumulative running total (not an increment) lets a consumer keep only the last value and makes a dropped or repeated usage event harmless. `ClaudeSSEDecoder` emits all five; `OpenAIReplyDecoder` and `OpenAICompatibleReplyDecoder` emit `toolUse`, `thinkingDelta` (from `reasoning_content`), and `usage` from their buffered replies. Consumers that only want text (`DaemonAIChat`, `AIPluginChatBackend`, `AIPluginLanguageModelProvider`) ignore the two new cases.
**Approved**: pending

**Decision**: `AIStreamDecoder` deliberately omits `Sendable`, unlike the sibling `AIPlugin` protocol, which requires it. (Apple platform implementation.)
**Rationale**: A decoder's whole purpose is to hold mutable per-response parsing state (buffered bytes, partial JSON); requiring `Sendable` would force every conformer to add locking for state that is, by design, never touched from more than one task. `AIPlugin` instances, by contrast, are commonly cached and reused across concurrent requests (see the sibling `AIPlugin` recipe's `concurrent-invocation-safety` requirement), so it needs `Sendable` where a decoder does not.
**Approved**: pending

**Decision**: `finish()` provides a default no-op implementation via a protocol extension rather than being a required method every conformer must implement. (Apple platform implementation.)
**Rationale**: A buffered whole-response decoder like `OpenAIReplyDecoder` needs an explicit `finish()` to emit its accumulated reply, but a decoder with no trailing state to flush (such as `LineDecoder` in `PluginTransportTests.swift`) has nothing useful to say when the stream closes; the default lets such a decoder omit the method entirely instead of writing a body that only returns `[]`.
**Approved**: pending

**Decision**: A permanently malformed frame is not observable by the host.
**Rationale**: There is no decode-error case or failure path, so a corrupt frame looks the same as an incomplete one; every current provider's wire format (server-sent-event lines, newline-delimited JSON, plain text) is line-oriented and resynchronizes on the next frame regardless of one bad line, so closing the gap takes a design decision on whether permanently malformed ever needs to be observable and, if so, an explicit decode-error case.
**Approved**: pending

