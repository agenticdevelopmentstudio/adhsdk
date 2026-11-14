
This is the configuration surface of a daemon. The caller supplies:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `String` | required | Reverse-DNS label; log subsystem and launchd identity. |
| `subsystem` | `String?` | `label` | Log subsystem for the runtime's queues and threads. |
| `daemonVersion` | `String` | required | Version the daemon reports through its feature services. |
| `httpPort` | `UInt16` | required | The daemon's HTTP port; 0 lets the OS assign one. |
| `supportDirectory` | `URL` | required | Where the database and ingest spool live; the runtime creates it. |
| `databasePath` | `String?` | `supportDirectory/sessions.db` | The session database file. |
| `spoolPath` | `String?` | `supportDirectory/ingest.db` | The ingest spool file. |
| `socketPath` | `String` | required | Unix socket hook helpers deliver events to. |
| `dropDirectory` | `URL` | required | Directory hook helpers drop envelopes into. |
| `errorsDirectory` | `URL?` | `dropDirectory/errors` | Quarantine for events the daemon could not ingest. |
| `hook` | `ClaudeHookConfiguration` | required | The Claude Code hook registration this daemon installs. |
| `retentionDays` | `Int` | 7 | Days of sessions kept. |
| `livenessCheckInterval` | `TimeInterval` | 10 | Seconds between liveness checks. |
| `retentionCheckInterval` | `TimeInterval` | 86400 | Seconds between retention checks. |
| `claudeJSONPath` | `String?` | `nil` (`~/.claude.json`) | File the signed-in Claude account is read from. |
| `pluginSearchPaths` | `[URL]` | `[]` | Extra folders scanned for `.aiplugin` bundles. |
| `summariesDefaultEnabled` | `Bool` | required, no default | Whether AI summaries are on until the user chooses otherwise. |

No environment variables or settings keys are read by this file.

