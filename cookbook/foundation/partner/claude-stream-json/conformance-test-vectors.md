
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-stream-json-001 | decode-kind-mapping, blocks-from-array, block-text, block-tool-use | Test `decodesAssistantTextAndToolUse`: `{"type":"assistant","session_id":"s","message":{"role":"assistant","content":[{"type":"text","text":"hi"},{"type":"tool_use","id":"t1","name":"mcp__adkitchen__partner_notify","input":{}}]}}` | `kind == .assistant`, two blocks, and `blocks[1].name == "mcp__adkitchen__partner_notify"` |
| claude-stream-json-002 | decode-kind-mapping, decode-is-error, decode-subtype | Test `decodesResultError`: `{"type":"result","subtype":"error_max_turns","is_error":true,"result":"x","session_id":"s"}` | `kind == .result`, `isError == true`, `subtype == "error_max_turns"` |
| claude-stream-json-003 | decode-num-turns, decode-errors, reports-lost-session | Test `decodesClaudesUnknownSessionResult`: an error result with subtype `error_during_execution`, `num_turns` 0 and `errors` `["No conversation found with session ID: 11111111-2222-3333-4444-555555555555"]` | `numTurns == 0`, `errors` equals that one string, `reportsLostSession` is true |
| claude-stream-json-004 | lost-session-not-other-errors | Test `anOrdinaryResultDoesNotReportALostSession`: a `success` result (`is_error` false, `num_turns` 1) and an `error_max_turns` result (`is_error` true, `num_turns` 3) | `reportsLostSession` is false for both, and the success result's `errors` is empty |
| claude-stream-json-005 | lost-session-not-other-errors | Test `anErrorBeforeAnyTurnIsNotALostSessionUnlessItSaysSo`: an error result with `num_turns` 0 and `errors` `["Invalid API key"]` | `reportsLostSession` is false |
| claude-stream-json-006 | decode-kind-other | Test `unknownTypeIsOther`: `{"type":"stream_event","event":{}}` | `kind == .other("stream_event")` |
| claude-stream-json-007 | decode-not-json-throws | Test `nonJSONThrows`: the bytes `nope` | `decode` throws `DecodingError` |
| claude-stream-json-008 | decode-kind-mapping, decode-session-id | Test `systemInitDecodes`: `{"type":"system","subtype":"init","session_id":"s"}` | `kind == .systemInit` and `sessionID == "s"` |
| claude-stream-json-009 | user-message-shape, user-message-newline | Test `userMessageLineShape`: `userMessage("hello")` | Parsed JSON has `type` `"user"`, `message.role` `"user"` and `message.content[0].text` `"hello"`; `userMessage("x")` ends in byte `0x0A` |
| claude-stream-json-010 | decode-kind-other | `{"type":"system","subtype":"api_retry"}` | `kind == .other("system")` and `subtype == "api_retry"` |
| claude-stream-json-011 | decode-missing-type | `{}` | `kind == .other("")`, `blocks` empty, `isError == false`, `errors` empty |
| claude-stream-json-012 | decode-not-object-throws | `[1,2]` | Throws `DecodingError.dataCorrupted` described as "not a JSON object" |
| claude-stream-json-013 | decode-not-json-throws | An empty `Data` | Throws `DecodingError.dataCorrupted` described as "not JSON" |
| claude-stream-json-014 | blocks-from-string | `{"type":"user","message":{"role":"user","content":"plain"}}` | One `.text` block with `text == "plain"` |
| claude-stream-json-015 | block-thinking | Content element `{"type":"thinking","thinking":"hmm"}` | A `.thinking` block with `text == "hmm"` |
| claude-stream-json-016 | block-tool-result-string | Content element `{"type":"tool_result","tool_use_id":"t1","content":"ok"}` | A `.toolResult` block with `text == "ok"` and `toolUseID == "t1"` |
| claude-stream-json-017 | block-tool-result-parts | Content element `{"type":"tool_result","tool_use_id":"t1","content":[{"type":"text","text":"a"},{"type":"image"},{"type":"text","text":"b"}]}` | `text == "a\nb"` |
| claude-stream-json-018 | block-tool-result-no-content | Content element `{"type":"tool_result","tool_use_id":"t1"}` | A `.toolResult` block with `text == nil` |
| claude-stream-json-019 | block-other | Content element `{"type":"image"}` | A `.other` block with all fields `nil` |
| claude-stream-json-020 | decode-errors | `{"type":"result","errors":["a",1,"b"]}` | `errors == ["a", "b"]` |
| claude-stream-json-021 | user-message-slashes | `userMessage("a/b")` | The bytes contain `a/b` and not `a\/b` |

