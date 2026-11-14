
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-process-configuration-001 | session-flag, optional-model | Configuration with `resume` false and `model` empty; read `arguments`. | Contains `--session-id`, does not contain `--resume`, does not contain `--model` (test: argumentsForFirstStartAndResume). |
| partner-process-configuration-002 | session-flag, optional-model | The same configuration with `resume` true and `model` `opus`. | Contains `--resume` and `--model` (test: argumentsForFirstStartAndResume). |
| partner-process-configuration-003 | mcp-config, fixed-prefix | Read `arguments` of a configuration. | Contains `--strict-mcp-config` and `--replay-user-messages` (test: argumentsForFirstStartAndResume). |
| partner-process-configuration-004 | order, session-id-lowercase, optional-tools | `executable` `/x/claude`, a session ID, `resume` true, `model` `opus`, `permissionMode` `dontAsk`, tools `a` and `b`, `mcpConfigPath` `/m.json`, `systemPromptPath` `/p.md`. | `arguments` equals exactly: `-p`, `--verbose`, `--input-format`, `stream-json`, `--output-format`, `stream-json`, `--replay-user-messages`, `--resume`, the lowercase session ID, `--permission-mode`, `dontAsk`, `--mcp-config`, `/m.json`, `--strict-mcp-config`, `--append-system-prompt-file`, `/p.md`, `--model`, `opus`, `--allowedTools`, `a`, `b` (test: argumentsAreExactlyOrdered). |
| partner-process-configuration-005 | optional-tools, optional-model | `allowedTools` empty, `model` `opus`. | `arguments` has `--model` and `opus` and no `--allowedTools`. |
| partner-process-configuration-006 | permission-mode | `permissionMode` empty. | `--permission-mode` is followed by an empty string element. |
| partner-process-configuration-007 | working-directory-not-an-argument | `workingDirectory` `/work-sentinel`, with `mcpConfigPath` `/mcp-sentinel`, `systemPromptPath` `/prompt-sentinel` and `executable` `/exe-sentinel`. | No element of `arguments` equals `/work-sentinel` or `/exe-sentinel`; `/mcp-sentinel` and `/prompt-sentinel` each appear exactly once. |
| partner-process-configuration-008 | fixed-prefix | Any configuration. | `arguments` contains `--verbose` immediately after `-p`. |
| partner-process-configuration-009 | session-flag | `resume` false, then `resume` true, same session ID. | Each `arguments` has exactly one of `--session-id` and `--resume`, counted once, and never the other; the next element is the lowercase session ID. |

