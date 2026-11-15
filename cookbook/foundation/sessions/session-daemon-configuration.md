---
id: 706313bb-1a26-4477-9250-62ad50aff110
title: "Session Daemon Configuration"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Value struct holding one session daemon's names, paths, intervals and hook registration, with derived defaults and a temp-rooted test factory."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - daemon
  - configuration
depends-on: []
related:
  - 9eb46f78-0ceb-455f-9584-b6b43ddf0871
references: []
approved-by: ""
approved-date: ""
---

# Session Daemon Configuration

## Overview

`SessionDaemonConfiguration` is everything that makes one session daemon's runtime its own: names, paths, intervals and the Claude Code hook registration it installs (Claude Hook Configuration ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871))). The runtime and the retention service read it; their own behavior is not specified here. A daemon builds one and hands it to the session runtime (`SessionDaemonRuntime`); nothing in the shared code spells a daemon's name or directory itself.

It is a `Sendable` struct of `var` fields with one initializer that derives several defaults from other arguments, and one static factory, `test(port:root:)`, that roots every path and the hook's `settings.json` under a directory so a test never touches the real Claude Code settings.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a configuration value, not a visual component.

## States

Not applicable — this is a configuration value, not a visual component. The struct has no runtime state machine; it is built once and read.

## Accessibility

Not applicable — this is a configuration value, not a visual component.

## Conformance Test Vectors

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

## Edge Cases

- **Empty or relative paths**: stored as given under `#requirements/no-validation`; a failure surfaces later where the path is used.
- **Zero or negative retention**: stored as given under `#requirements/no-validation`, including 0 and negative values; what such a value means is up to `RetentionService`.
- **Zero or negative intervals**: stored as given under `#requirements/no-validation`.
- **Port 0**: accepted under `#requirements/no-validation`; it means the OS assigns a port, and `test` uses it (`#requirements/test-port`).
- **Boundary values of `httpPort`**: The `UInt16` type limits the port to 0 through 65535 at compile time; a larger literal does not compile.
- **Default derived from a nil argument only**: A default for `databasePath`, `spoolPath` or `errorsDirectory` is computed once from the arguments passed to the same call (`#requirements/database-default`, `#requirements/spool-default`, `#requirements/errors-default`); changing `supportDirectory` later on the `var` does not update `databasePath`, `spoolPath` or `errorsDirectory`.
- **Shared settings file**: Two daemons whose `hook.settingsURL` point at the same `settings.json` coexist because each hook marker is distinct; the marker rules belong to `ClaudeHookConfiguration`.
- **Concurrent access**: Not applicable: the struct is a `Sendable` value type, copied on assignment, so no two holders share mutable state.
- **Error states, offline, cancellation**: Not applicable: building the value does no I/O and cannot throw.

## Configuration

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

## Deep Linking

Not applicable: the struct holds paths and a port, not URL routes for a user to open.

## Localization

Not applicable: the struct holds no user-facing strings; `test` sets only identifiers and paths.

## Accessibility Options

Not applicable: the struct is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the struct reads no flags. `summariesDefaultEnabled` is a required daemon setting that sets a default and is not a flag key.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the struct holds paths, a port, intervals and a boolean, with no credentials or personal data. `claudeJSONPath` only names the file the account is read from; the file's contents are read elsewhere.

## Logging

Not applicable: the struct makes no log calls; `subsystem` is the name other code logs under.

## Platform Notes

- **SwiftUI**: Nothing to port: the Swift struct in `Core/Sessions` is Foundation-only, built by a daemon's `main` and shared as is. A SwiftUI host app shows none of it; it reads the daemon's state through the daemon's API.
- **Compose**: Port as a Kotlin `data class` with default parameter values and `copy()` for changes. Derive the defaults in a secondary constructor or factory that takes nullable arguments, as the Swift initializer does. A `UShort`-like port needs an `Int` range check or `UShort`.
- **React/Web**: Port as a TypeScript interface plus a `makeConfiguration(options)` function that fills the derived defaults. Use `Readonly` and spread for copies. A browser has no sockets or files, so this is meaningful only in a Node daemon.
- **AppKit / UIKit**: A macOS menu bar app or `LaunchAgent` host builds the value once, from bundle info and `FileManager` support directories, and passes it to the runtime. Nothing in it is UI.
- **WinUI 3**: Port as a C# `record` (or `sealed record class`) with `init` properties and `with` expressions for copies, so it is immutable and thread-safe like the Swift struct. Use `Uri` or `string` for paths, `ushort` for the port, `TimeSpan` for intervals, and `Windows.Storage.ApplicationData.Current.LocalFolder.Path` or `Environment.GetFolderPath` for the support directory. The Unix socket path becomes a named pipe name or a `UnixDomainSocketEndPoint` (supported in .NET on Windows 10 and later). Bind defaults from `IConfiguration` with `IOptions<T>` when the daemon is an `IHostedService`. Port the `test` factory as a static method that builds a unique path under `Path.GetTempPath()` without creating the directory, as `test-no-create` requires. Keep "no default" for `summariesDefaultEnabled` by making it a primary-constructor parameter without a default value, or a `required init` property.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/SessionDaemonConfiguration.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKDatabaseTests/Daemon/Core/SessionDaemonRuntimeTests.swift` | confirmed (1.0.2) |

## Design Decisions

**Decision**: A daemon builds one configuration and hands it to the shared runtime; the shared code spells no daemon name or directory.
**Rationale**: The doc comment on `SessionDaemonConfiguration` in `SessionDaemonConfiguration.swift` says so directly ("nothing in the shared code spells a daemon's name or directory itself"). It lets several daemons share one runtime while each keeps its own paths, hook marker and identity.
**Approved**: pending

**Decision**: `summariesDefaultEnabled` has no default.
**Rationale**: The doc comment on `summariesDefaultEnabled` in `SessionDaemonConfiguration.swift` says every daemon states its own: a daemon that must not double LLM spend over sessions another daemon already summarizes passes `false`. A default would let that mistake happen by omission.
**Approved**: pending

**Decision**: Paths and the subsystem are derived from other arguments when the caller passes `nil`, and the initializer stores them as plain values.
**Rationale**: Most daemons want `sessions.db`, `ingest.db` and `errors` in the usual places and a subsystem equal to the label, while still allowing overrides. The cost is that later edits to `supportDirectory` or `label` do not move the derived values.
**Approved**: pending

**Decision**: No argument is validated and the initializer creates nothing on disk.
**Rationale**: The value is cheap and side-effect free; the runtime creates `supportDirectory` when it opens. The cost is that a bad path or interval fails at the point of use instead of at construction.
**Approved**: pending

**Decision**: `test(port:root:)` roots every path, and the hook's `settings.json`, in one directory.
**Rationale**: The doc comment on `test(port:root:)` in `SessionDaemonConfiguration.swift` says a test must never touch the real Claude Code settings. It also uses port 0 so parallel tests do not collide, a 1-second liveness interval so tests do not wait, and `summariesDefaultEnabled` of `false`.
**Approved**: pending

**Decision**: `httpPort`, `label`, `retentionDays` and the two intervals are carried for the host daemon and are not depended on by the shared runtime.
**Rationale**: The host daemon owns the listener, the launchd registration and the timers; the shared struct exists so one value describes the whole daemon.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |

Separation of concerns passes: the struct only holds values and derives defaults, and the runtime, hook installer and services read it. Unit-test coverage passes: `SessionDaemonConfigurationTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Sessions/SessionDaemonConfigurationTests.swift`) tests vectors 001-012 and 014 directly, one test per vector, and `SessionDaemonRuntimeTests` covers vector 013. Secure data storage passes because the struct stores no secrets; it only names paths.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionDaemonConfigurationTests.swift, 13 of 14 vectors; 013 already covered by SessionDaemonRuntimeTests); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Reworded label-meaning as a caller obligation and host-read-fields as a design fact, replaced edge-case MUSTs with references to no-validation and the default requirements, fixed the WinUI and SwiftUI notes, added retentionCheckInterval and root-not-created checks to vectors 011 and 012, named the test class for the untested vectors, linked ClaudeHookConfiguration and emptied references. |
