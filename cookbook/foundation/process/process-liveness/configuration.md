
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CLAUDE_CONFIG_DIR` | environment variable of the inspected process | unset, meaning `~/.claude` | Where `sessions/<pid>.json` is read. |
| `environment` | `[String: String]` or nil | none | The inspected process's environment, passed to `currentSessionId(ofPid:environment:)`. |
| `argv` | `[String]` or nil | none | The inspected process's arguments, passed to `isHeadless(argv:sessionFile:)`. |
| `sessionFile` | `Data` or nil | none | The raw session file, passed to `isHeadless(argv:sessionFile:)`. |
| `directory`, `isClaude`, `canonical` | functions | the kernel path read, the launch-path test, `canonicalPath` | Probes of `uniqueClaude`. |

Constants, not options (no override exists): the pid headroom of 256 spare entries beyond the kernel's count, and the launch-path test for a Claude Code CLI (last component `claude`, or contains `/claude/`).
