
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CLAUDE_CONFIG_DIR` | environment variable of the inspected process | unset, meaning `~/.claude` | Where `sessions/<pid>.json` is read. |
| `environment` | `[String: String]` or nil | none | The inspected process's environment, passed to `currentSessionId(ofPid:environment:)`. |
| `argv` | `[String]` or nil | none | The inspected process's arguments, passed to `isHeadless(argv:sessionFile:)`. |
| `sessionFile` | `Data` or nil | none | The raw session file, passed to `isHeadless(argv:sessionFile:)`. |
| `directory`, `isClaude`, `canonical` | functions | the kernel path read, the launch-path test, `canonicalPath` | Probes of `uniqueClaude`. |
| pid headroom | integer constant | 256 | Spare pid entries beyond the kernel's count. |
| accepted launch-path forms | rule | last component `claude`, or contains `/claude/` | The test for a Claude Code CLI. |

