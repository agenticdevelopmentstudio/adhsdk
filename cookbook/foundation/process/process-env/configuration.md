
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxHops` | integer | 16 | Most parent steps one token walk takes. |
| `maxEntries` | integer constant | 128 | Cache ceiling; matches `HookEnvCache`. |
| token lifetime | seconds, private constant | 30 | How long a cached token or negative result is used. |
| `hookShellNames` | set of strings | `sh`, `bash`, `zsh`, `dash` | Shells a hook command line may run through. |
| `claudeProcessNames` | set of strings | `claude`, `node` | Names a `claude` process answers to (native binary or npm install). |
| `parentOf`, `namesOf` | functions | `parentPid(of:)`, `processNames(of:)` | Replaceable lookups for `claudePid(aboveHookParent:)`. |
| environment variable read | `CLAUDE_CODE_OAUTH_TOKEN` | none | The only variable the token walk looks for. |

