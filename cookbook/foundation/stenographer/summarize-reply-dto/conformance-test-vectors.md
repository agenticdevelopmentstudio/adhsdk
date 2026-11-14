
The source has no test of its own; `SummarizeReplyMappingTests` covers `StenographerSummarizing`, which maps the HTTP twin's `SummarizeDaemonFailure` to its error text. The vectors below are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| summarize-reply-dto-001 | initializer, success-shape | `SummarizeReplyDTO(sessionId: "s1", summary: "Fixed the bug")` | `sessionId` `s1`, `summary` `Fixed the bug`, `error` nil. |
| summarize-reply-dto-002 | initializer, failure-shape | `SummarizeReplyDTO(sessionId: "s1", error: "model too large")` | `summary` nil, `error` `model too large`. |
| summarize-reply-dto-003 | initializer | `SummarizeReplyDTO(sessionId: "s1")` | Both `summary` and `error` are nil. |
| summarize-reply-dto-004 | codable-equatable | Two replies built with the same three values. | They compare equal; changing any one field makes them unequal. |
| summarize-reply-dto-005 | no-coding-keys | Encode `SummarizeReplyDTO(sessionId: "s1", summary: "x")` with a default `JSONEncoder`. | An object with keys `sessionId` and `summary`; no `error` key. |
| summarize-reply-dto-006 | no-coding-keys, codable-equatable | Encode with `StenographerWire.encoder()` and decode with `StenographerWire.decoder()`. | The key is `session_id` and the decoded value equals the original. |
| summarize-reply-dto-007 | reason-surfaced | A reply with `error` `model too large`. | The consumer shows `model too large` (the in-repo HTTP path shows the same reason through `SummarizeDaemonFailure` and `StenographerSummarizing`; test: testDaemonReasonIsSurfaced in `SummarizeReplyMappingTests`, in the macOS tests). |
| summarize-reply-dto-008 | transport-failure-distinct | The XPC call returns nil. | The consumer shows the generic failure text, `the daemon could not generate a summary` (the in-repo equivalent is `StenographerSummarizing` mapping a non-`SummarizeDaemonFailure` error to that text; test: testTransportFailureHasGenericText in `SummarizeReplyMappingTests`). |
| summarize-reply-dto-009 | exclusivity-by-convention | `SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "y")` | The initializer accepts it; both fields are set (derived from the source; the type does not reject it). |

