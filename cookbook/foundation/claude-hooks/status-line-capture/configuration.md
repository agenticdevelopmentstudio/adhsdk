
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `captureOnly` | boolean | none | Runs the feed only; prints nothing and exits 0 |
| `payload` | bytes | none | The status-line JSON Claude Code piped in |
| `environment` | string map | none | This process's environment |
| `configuration` | `ClaudeHookConfiguration` | none | Supplies `name` (the lock name), `hookBinaryPath` (the helper name), `statusLineArguments` (default `["statusline"]`) and the drop directory |
| `post` | `@Sendable` closure from event and payload to boolean | none | Sends one hook event; true when the daemon accepted it |
| `accountName` | `@Sendable` closure from optional token to string | none | The account lookup the drop envelope carries |
| `oauthEmail` | `@Sendable` closure returning string | returns the empty string | The machine login's account |
| `render` | closure from payload and optional token to exit status | none | Prints the status line; not called with `captureOnly` |
| `executable` | optional string | main bundle's executable path | The program `detachFeed` starts |
| `feedDeadline` | seconds | 20 | The longest a feed may run |
| `captureOnlyFlag` | string | `--capture-only` | The argument that selects the feed-only run |
| token walk hop limit | integer | 16 | `maxHops` of `ProcessEnv.oauthTokenWalkingUp` |
| token walk cache | seconds | 30 | `ttl` in `ProcessEnv`, per start pid |
| session id cut | scalars | 128 | Scalars of the session id kept in the lock file name; see `lock-name-sanitised` |
| `CLAUDEHELPERS_STATUSLINE_PARENT_PID` | environment variable | absent | The pid that ran the status line, set by the dispatcher and by this command for the feed it detaches |
| `CLAUDE_CODE_OAUTH_TOKEN` | environment variable | scrubbed by Claude Code | Carried to a detached feed |
| `<NAME>_DROP_DIR` | environment variable | the configuration's `dropDirectory` | Overrides the drop directory for the configuration when set and non-empty (`HookDropWriter`) |

