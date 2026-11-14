
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-interaction-dto-001 | is-failure | `outcome` is `ok`. | `isFailure` is false (test: testOkRowStillShowsResponse, through the result column). |
| ai-interaction-dto-002 | is-failure, failure-reason | `outcome` is `guard_blocked`, `response` empty, `error` a block-threshold message. | `isFailure` is true; the AI Log result column shows a warning glyph and the reason (test: testGuardBlockedRowShowsReasonWithWarningGlyph). |
| ai-interaction-dto-003 | is-failure, failure-reason | `outcome` is `guard_deferred`, `response` empty, `error` a memory-pressure message. | `isFailure` is true; the result column shows the warning glyph and the reason (test: testGuardDeferredRowShowsReason). |
| ai-interaction-dto-004 | is-failure | `outcome` is `error`. | `isFailure` is true (derived from the source; the AI Log result column's failure path). |
| ai-interaction-dto-005 | is-failure | `outcome` is `surprise`, outside the documented vocabulary. | `isFailure` is true (derived from the source expression; no test). |
| ai-interaction-dto-006 | is-failure-case-sensitive | `outcome` is `OK`. | `isFailure` is true (derived from the source expression; no test). |
| ai-interaction-dto-007 | codable-keys, field-set | Encode a DTO and decode the result. | The decoded value equals the original (derived from the synthesized conformance; no test of the DTO round trip). |
| ai-interaction-dto-008 | decode-all-required | Decode JSON that lacks `truncated`. | Decoding throws `keyNotFound` (derived from the synthesized conformance; no test). |
| ai-interaction-dto-009 | truncated-list | List read of a row whose `userPrompt` is longer than the truncation length (default 300 characters, in the daemon's store). | `truncated` is true and the three text fields are cut to that length (source: the daemon's `fetchAIInteractions`; test: testListTruncatesLongTextAndFlagsIt, which asserts a 400-character `userPrompt` reads back as 300 characters with `truncated` true). |
| ai-interaction-dto-010 | truncated-detail | By-id read of the same row. | Full text with `truncated` false (source: the daemon's `fetchAIInteraction`; test: testListTruncatesLongTextAndFlagsIt, which asserts the by-id text equals the original and `truncated` is false). |

