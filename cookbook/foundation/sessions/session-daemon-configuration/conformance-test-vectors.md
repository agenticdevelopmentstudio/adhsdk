
The test `SessionDaemonRuntimeTests` uses `SessionDaemonConfiguration.test(port: 0, root: root)` and asserts that after `openPhaseA()` the files at `databasePath` and `spoolPath` exist. The other vectors follow from the initializer and factory text.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-daemon-configuration-001 | subsystem-default | Initializer with `label: "a.b"` and no `subsystem` | `subsystem == "a.b"` |
| session-daemon-configuration-002 | explicit-overrides | Initializer with `label: "a.b"` and `subsystem: "c.d"` | `subsystem == "c.d"` |
| session-daemon-configuration-003 | database-default, spool-default | `supportDirectory` `/tmp/x` and no paths | `databasePath == "/tmp/x/sessions.db"`, `spoolPath == "/tmp/x/ingest.db"` |
| session-daemon-configuration-004 | errors-default | `dropDirectory` `/tmp/x/events` and no `errorsDirectory` | `errorsDirectory.path == "/tmp/x/events/errors"` |
| session-daemon-configuration-005 | retention-default, liveness-default, retention-check-default | Initializer with only required arguments | `retentionDays == 7`, `livenessCheckInterval == 10`, `retentionCheckInterval == 86400` |
| session-daemon-configuration-006 | claude-json-default, plugin-paths-default | Initializer with only required arguments | `claudeJSONPath == nil`, `pluginSearchPaths == []` |
| session-daemon-configuration-007 | test-root, test-paths, test-derived-defaults | `test(root: URL(fileURLWithPath: "/r"))` | `supportDirectory` is `/r`, `socketPath` is `/r/capture.sock`, `dropDirectory` is `/r/events`, `databasePath` is `/r/sessions.db`, `spoolPath` is `/r/ingest.db`, `errorsDirectory` is `/r/events/errors` |
| session-daemon-configuration-008 | test-identity, test-port, test-summaries-off | `test()` | `label == "test.session-daemon"`, `daemonVersion == "0.0.0-test"`, `httpPort == 0`, `summariesDefaultEnabled == false` |
| session-daemon-configuration-009 | test-hook, test-account-file | `test(root: /r)` | `hook.name == "session-daemon-test"`, `hook.marker == "# session-daemon-test-hook"`, `hook.settingsURL.path == "/r/settings.json"`, `claudeJSONPath == "/r/claude.json"` |
| session-daemon-configuration-010 | test-root | Two calls of `test()` with no `root` | The two `supportDirectory` values differ and each ends with a UUID after `session-daemon-test-` |
| session-daemon-configuration-011 | test-no-create | `test()` with no `root`, then check the file system; and `test(root:)` with a root that does not exist yet, then check the file system | No directory exists at either `supportDirectory` |
| session-daemon-configuration-012 | test-intervals | `test()` | `livenessCheckInterval == 1`, `retentionDays == 7`, `retentionCheckInterval == 86400` |
| session-daemon-configuration-013 | runtime-reads, test-derived-defaults | Test `testOpenPhaseALeavesTheDatabaseNotReady`: a runtime built from `test(port: 0, root: root)`, then `openPhaseA()` | Files exist at `databasePath` and `spoolPath` |
| session-daemon-configuration-014 | no-validation | `retentionDays: 0` and `httpPort: 0` | Both stored as given; no error |

