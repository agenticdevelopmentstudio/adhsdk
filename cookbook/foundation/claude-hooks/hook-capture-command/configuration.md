
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `arguments` | list of strings | none | The arguments after the subcommand: `--event <Type>` and optionally `--ppid <int>` |
| `stdin` | bytes | none | The payload Claude Code piped in |
| `environment` | string map | none | The environment the headless check, `term_program`, `term_session_id`, token fallback and drop-directory override read |
| `configuration` | `ClaudeHookConfiguration` | none | Supplies the drop directory and the override variable name (see `HookDropWriter`) |
| `accountName` | closure from optional token to string | none | Maps an OAuth token to its account name, empty when unknown |
| `oauthEmail` | closure returning string | returns the empty string | Reads the machine login's account |
| `claudePid` | closure returning optional Int32 | `ProcessEnv.claudePid(aboveHookParent:)`: the hook's parent, or that parent's parent when it is a `sh`, `bash`, `zsh` or `dash` shell, accepted only when its name is `claude` or `node`, else nil | Finds Claude's pid when no `--ppid` was passed |
| `ADH_SDK_HEADLESS` | environment variable | unset | Any value, even empty, suppresses tracking |
| `TERM_PROGRAM`, `TERM_SESSION_ID` | environment variables | empty string | Lifted onto `hook_data` |
| `CLAUDE_CODE_OAUTH_TOKEN` | environment variable | absent | Fallback token source |

