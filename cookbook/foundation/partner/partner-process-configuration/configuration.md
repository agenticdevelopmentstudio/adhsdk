
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `executable` | String | none, required | Path to the `claude` executable. |
| `sessionID` | UUID | none, required | The conversation session; written lowercase. |
| `resume` | Bool | none, required | True resumes the session; false starts it under that ID. |
| `model` | String | none, required; empty omits the option | Model name passed to `--model`. |
| `permissionMode` | String | none, required | Passed to `--permission-mode`; the tests use `dontAsk`. |
| `allowedTools` | [String] | none, required; empty omits the option | Tool names passed after `--allowedTools`. |
| `mcpConfigPath` | String | none, required | The MCP config file; only this config is used because of `--strict-mcp-config`. |
| `systemPromptPath` | String | none, required | File appended to the system prompt. |
| `workingDirectory` | String | none, required | The child's current directory; not part of `arguments`. |

