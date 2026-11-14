
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `event` | string | none | The hook event type; empty yields nil |
| `payload` | bytes | none | The hook payload JSON |
| `ppid` | integer | none (full build); recovered pid or 0 (payload-only) | Claude's pid |
| `env` | string map | none | The environment the hook script forwarded or recovered from the process |
| `parsedPayload` | optional string-keyed map | nil | A payload already parsed, to avoid a second parse |
| `claudePid` | closure from cwd to optional Int32 | `HookEnvCache.pid(inCwd:)` | Finds the `claude` process for a working directory |
| `environment` | closure from pid to optional string map | `HookEnvCache.env(forPid:)` | Reads a process's environment |
| `daemonCwd` | string | `daemonWorkingDirectory` | The daemon's own canonical working directory |
| `accountName` | closure from optional token to string | returns the empty string | Maps a token to its account |
| `oauthEmail` | closure returning string | returns the empty string | The machine login's account |
| `HookEnvCache` time to live | seconds | 3 | How long a cached lookup is served |
| `HookEnvCache` size threshold | entries | 128 | Above this, expired entries are purged |
| `ADH_SDK_HEADLESS` | environment key | absent | Any value drops the event |

