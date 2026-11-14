
The repository has no test that names this type. The vectors are derived from the source; the resolve closure and the session are test doubles.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-tool-source-001 | tool-names, definitions-all | `toolDefinitions()` | Three definitions named run_terminal_command, wait_for_terminal_output, interrupt_terminal, in that order. |
| terminal-chat-tool-source-002 | run-schema | The run definition's schema | An object whose properties are only `command` (string) and whose required list is `["command"]`. |
| terminal-chat-tool-source-003 | wait-definition, interrupt-definition | The wait and interrupt schemas | Objects with empty properties and empty required lists. |
| terminal-chat-tool-source-004 | run-definition | The run description | Mentions typing and Return, the prompt in the output and that pseudonyms are used as given. |
| terminal-chat-tool-source-005 | no-chat | Any tool call with the closure returning nil | An error asking for a Terminal Chat pane and Connect to Terminal Chat. |
| terminal-chat-tool-source-006 | no-chat-before-unknown | `callTool` named "bogus" with no chat | The missing-chat error, not "Unknown tool". |
| terminal-chat-tool-source-007 | run-call | Run with `{"command":"ls"}` and a session that answers "files" | Content "files", not an error; the session was run with "ls". |
| terminal-chat-tool-source-008 | run-needs-command | Run with `{}`, `{"command":""}`, `{"command":5}` and `not json` | The needs-a-command error for each; nothing typed. |
| terminal-chat-tool-source-009 | wait-call | Wait with arguments `{"x":1}` | The session's wait output, not an error; arguments ignored. |
| terminal-chat-tool-source-010 | interrupt-call | Interrupt | The session's interrupt-and-wait output, not an error. |
| terminal-chat-tool-source-011 | unknown-tool | `callTool` named "bogus" with a chat | "Unknown tool: bogus", an error. |
| terminal-chat-tool-source-012 | resolve-per-call | Call with no chat, connect one, call again | The first call errors; the second reaches the session. |
| terminal-chat-tool-source-013 | session-text-passthrough | The session answers with the still-running line | That text, unchanged, as a non-error. |

