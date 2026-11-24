
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversation-entry-dto-001 | is-from-user | `kind` is `prompt`. | `isFromUser` is true (derived from the source expression; no direct test). |
| conversation-entry-dto-002 | is-from-user | `kind` is `reply`. | `isFromUser` is false (derived from the source expression; no direct test). |
| conversation-entry-dto-003 | work-output-kinds, is-work-output | `kind` is `progress`, then `thinking`. | `isWorkOutput` is true for both (derived from the source; no direct test). |
| conversation-entry-dto-004 | is-work-output | `kind` is `prompt`, `reply` or `notice`. | `isWorkOutput` is false for each (derived from the source; no direct test). |
| conversation-entry-dto-005 | tolerant-decode-term-program | Decode JSON with all eight always-present keys and no `termProgram`. | Decoding succeeds and `termProgram` is the empty string (derived from the source; no direct test). |
| conversation-entry-dto-006 | tolerant-decode-required-keys | Decode JSON lacking `gitBranch`. | Decoding throws `keyNotFound` (derived from the source; no direct test). |
| conversation-entry-dto-007 | coding-keys, encode-synthesized | Encode a DTO with `termProgram` of `iTerm.app` and decode it back. | The result equals the original (derived from the conformances; no direct test). |
| conversation-entry-dto-008 | initializer-default | Build with no `termProgram` argument. | `termProgram` is the empty string (derived from the source default; no direct test). |
| conversation-entry-dto-009 | row-identity, row-identity-unfiltered-index | The daemon builds entries from a `transcript_lines` row with id 7 that yields blocks at offsets 0 and 2 after filtering. | The entries have ids 7000 and 7002 (source: the daemon's `ConversationStore`, which computes the id as the row id times its maximum lines per entry of 1000 plus the offset; tests in `ConversationFeedTests`: testIdsAreUniqueAcrossBlocksOfTheSameEntry and testAnIdDoesNotMoveWhenTheWorkOutputFilterChanges). |
| conversation-entry-dto-010 | shared-work-list | The daemon's `ConversationExtractor.Kind.progress.isWorkOutput` and `.reply.isWorkOutput`. | True and false, read from `workOutputKinds` (source: `ConversationExtractor`; no direct test). |
| conversation-entry-dto-011 | tolerant-decode-term-program | Decode JSON with `termProgram` set to null. | `termProgram` is the empty string (derived from `decodeIfPresent`; no direct test). |

