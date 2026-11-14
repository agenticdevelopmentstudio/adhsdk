
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | `ClaudeHookConfiguration` | none | Supplies `name` (for the variable) and `dropDirectory` (the default location) |
| `environment` | string map | the current process environment | Where the override variable is looked up |
| `<NAME>_DROP_DIR` | environment variable | unset | Overrides the directory for the configuration whose name matches; tests only |
| `ClaudeHookConfiguration.dropDirectory` | string | for example `~/.claude/stenographer-events`, `~/.claude/adkd-events` | The tilde-form default directory |
| `directory` | string | none | The directory `writeDropFile` writes into; may begin with `~` |
| `envelope` | string-keyed map | none | The value to encode |

