
The shapes have no test beside them. The vectors come from the source's own logic, and from `ConversationMessagesTests` (in the database test target), which asserts these shapes as the daemon's `ConversationStore.conversationMessages` returns them.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversation-message-dto-001 | type-for-kind-prompt | `type(forKind: "prompt")` | `user` |
| conversation-message-dto-002 | type-for-kind-notice | `type(forKind: "notice")` | `notice` |
| conversation-message-dto-003 | type-for-kind-default | `type(forKind: "reply")`, `"progress"`, `"thinking"`, `"mystery"` | `model` for each |
| conversation-message-dto-004 | message-from-entry, message-from-entry-type, message-from-entry-agent | a `ConversationEntryDTO` with id 5000, kind `reply`, text `hi`, timestamp `2026-09-01T10:00:00Z`; `init(entry:)` | id 5000, type `model`, kind `reply`, content `hi`, time `2026-09-01T10:00:00Z`, agentId nil |
| conversation-message-dto-005 | range-error-description | `ConversationRangeError.unknownMessageId(42).errorDescription` | `No message 42 in this conversation.` |
| conversation-message-dto-006 | range-error-case, range-error-equatable | a page asked after id 999999000 in a session with four messages (`testAnIdFromNowhereIsRefused`) | the thrown error equals `ConversationRangeError.unknownMessageId(999999000)` |
| conversation-message-dto-007 | page-order, message-type-values, page-is-complete, page-next-after-id | the whole four-line dialogue (`testTheWholeConversationComesBackOldestFirstWithUserAndModelTypes`) | contents `hello claude`, `hello`, `how can I help`, `thanks`; types `user`, `model`, `model`, `user`; `isComplete` true; `nextAfterId` is the last message's id |
| conversation-message-dto-008 | query-after-exclusive, query-through-inclusive | `afterId` = first message's id, `throughId` = second message's id (`testAfterIsExclusiveAndThroughIsInclusive`) | one message, `hello` |
| conversation-message-dto-009 | query-limit, page-is-complete, page-paging-by-id | `limit` 1 over four messages, then ask after the returned `nextAfterId` (`testAFullPageSaysWhereToContinue`) | first page `hello claude` with `isComplete` false; second page `hello`, `how can I help`, `thanks` with `isComplete` true |
| conversation-message-dto-010 | page-next-after-id, page-is-complete | ask after the newest message's id (`testTheNewestIdAsksForNothingMore`) | empty `messages`, `isComplete` true, `nextAfterId` equals the id asked with |
| conversation-message-dto-011 | page-next-after-id, page-is-complete | a session with no transcript lines (`testAnEmptyConversationIsCompleteAndEmpty`) | empty `messages`, `isComplete` true, `nextAfterId` nil |
| conversation-message-dto-012 | query-include-work-output | `includeWorkOutput` false, then true, over a dialogue with a progress line (`testWorkOutputIsLeftOutUnlessAskedFor`) | `looking around` absent when false, present when true |
| conversation-message-dto-013 | message-agent-id | work output over a session with one subagent transcript (`testWorkOutputWeavesInTheSubagentsTranscripts`) | `agentId` values nil for the session's own message and `a48` for the subagent's |
| conversation-message-dto-014 | message-agent-id-optional | decode a message JSON object with no `agentId` key | decodes with `agentId` nil |
| conversation-message-dto-015 | message-memberwise-init | `ConversationMessageDTO(id: 1, type: "user", kind: "prompt", content: "x", time: "t")` | `agentId` nil |

