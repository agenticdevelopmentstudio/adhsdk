
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` | `String?` | nil | The session's working directory; nil samples the inherited one |
| `recentCommitCount` | fixed | `5` | Commits in the log sample; a constant, not a caller option (`sample-recent-count`) |
| `payloadKey` | `String` | `stenographer_git` | Key the fingerprint is nested under; any future injected key carries the same prefix |
| status flags | fixed | `-unormal --no-renames` with `core.quotePath=true` | Pinned against user configuration |
| log flags | fixed | `--oneline --no-decorate` with `log.showSignature=false` | Pinned against user configuration |

