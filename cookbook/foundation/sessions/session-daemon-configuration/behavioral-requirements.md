
**Shape**

- **config-value-type**: `SessionDaemonConfiguration` MUST be a `Sendable` struct whose stored properties are `var`s, so a caller can copy it and change a field, as the runtime test does with `hook`.
- **config-fields**: The struct MUST carry `label` (String), `subsystem` (String), `daemonVersion` (String), `httpPort` (UInt16), `supportDirectory` (URL), `databasePath` (String), `spoolPath` (String), `socketPath` (String), `dropDirectory` (URL), `errorsDirectory` (URL), `hook` (`ClaudeHookConfiguration`, Claude Hook Configuration ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871))), `retentionDays` (Int), `livenessCheckInterval` (TimeInterval), `retentionCheckInterval` (TimeInterval), `claudeJSONPath` (String?), `pluginSearchPaths` ([URL]) and `summariesDefaultEnabled` (Bool).
- **label-meaning**: Callers SHOULD pass a reverse-DNS `label`, which serves as the log subsystem and the launchd identity; the struct does not check it (see no-validation).
- **summaries-no-default**: `summariesDefaultEnabled` MUST have no default value in the initializer, so every daemon states its own.

**Required and defaulted initializer arguments**

- **init-required**: The initializer MUST require `label`, `daemonVersion`, `httpPort`, `supportDirectory`, `socketPath`, `dropDirectory`, `hook` and `summariesDefaultEnabled`.
- **subsystem-default**: When `subsystem` is `nil`, the stored `subsystem` MUST equal `label`.
- **database-default**: When `databasePath` is `nil`, the stored value MUST be the path of `sessions.db` inside `supportDirectory`.
- **spool-default**: When `spoolPath` is `nil`, the stored value MUST be the path of `ingest.db` inside `supportDirectory`.
- **errors-default**: When `errorsDirectory` is `nil`, the stored value MUST be an `errors` subdirectory of `dropDirectory`.
- **retention-default**: `retentionDays` MUST default to 7.
- **liveness-default**: `livenessCheckInterval` MUST default to 10 seconds.
- **retention-check-default**: `retentionCheckInterval` MUST default to 86400 seconds.
- **claude-json-default**: `claudeJSONPath` MUST default to `nil`, which means the signed-in Claude account is read from `~/.claude.json`.
- **plugin-paths-default**: `pluginSearchPaths` MUST default to an empty array, which means only the default plugin folders (`~/.agenticplugins` and the bundle's `PlugIns`) are scanned.
- **explicit-overrides**: A non-`nil` value for `subsystem`, `databasePath`, `spoolPath` or `errorsDirectory` MUST be stored unchanged.
- **no-validation**: The initializer MUST store every argument as given; it does not validate, normalize or create anything.

**Test factory**

- **test-root**: `test(port:root:)` MUST use `root` as the base directory when given, and otherwise a new directory named `session-daemon-test-` plus a fresh UUID under `NSTemporaryDirectory()`.
- **test-no-create**: `test(port:root:)` MUST NOT create the base directory; it only builds paths.
- **test-port**: `test` MUST default `port` to 0, which lets the OS assign one.
- **test-identity**: `test` MUST set `label` to `"test.session-daemon"` and `daemonVersion` to `"0.0.0-test"`.
- **test-paths**: `test` MUST set `supportDirectory` to the base, `socketPath` to `capture.sock` in the base, and `dropDirectory` to `events` in the base.
- **test-hook**: `test` MUST build a `ClaudeHookConfiguration` named `"session-daemon-test"` with marker `"# session-daemon-test-hook"`, helper path `helper` in the base, the drop directory's path, and `settingsURL` of `settings.json` in the base.
- **test-intervals**: `test` MUST set `livenessCheckInterval` to 1 second and leave `retentionDays` at 7 and `retentionCheckInterval` at 86400.
- **test-account-file**: `test` MUST set `claudeJSONPath` to `claude.json` in the base.
- **test-summaries-off**: `test` MUST set `summariesDefaultEnabled` to `false`.
- **test-derived-defaults**: `test` MUST take `databasePath`, `spoolPath` and `errorsDirectory` from the initializer defaults, giving `sessions.db`, `ingest.db` and `events/errors` in the base.

**How the runtime reads it**

- **runtime-reads**: `SessionDaemonRuntime` reads `databasePath`, `spoolPath`, `supportDirectory`, `dropDirectory`, `errorsDirectory`, `socketPath`, `subsystem`, `daemonVersion`, `hook`, `claudeJSONPath`, `pluginSearchPaths` and `summariesDefaultEnabled`; it MUST create `supportDirectory` with intermediate directories when it opens.
- **runtime-queue-label**: The runtime MUST label its queues and threads as the `subsystem`, a dot and a name.
- **runtime-daemon-name**: The runtime MUST report its daemon name as `configuration.hook.name`.
- **host-read-fields**: `label`, `httpPort`, `retentionDays`, `livenessCheckInterval` and `retentionCheckInterval` are carried for the host daemon, which owns the HTTP listener, the launchd registration and the timers that use them; the shared runtime MUST NOT depend on them.

