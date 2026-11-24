---
id: 1d48ed86-5704-4631-b643-36f7450c1c83
title: "ADKD Identifiers"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The one place the Kitchen daemon's launchd label, ports, keychain service, hook names and every on-disk path are spelled, distinct from the Stenographer daemon's."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - identifiers
  - paths
depends-on: []
related:
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
references: []
approved-by: ""
approved-date: ""
---

# ADKD Identifiers

## Overview

`ADKDIdentifiers` and `ADKDPaths` are the single spelling of every name the Kitchen daemon (`adkd`) owns: its launchd label, log subsystems, keychain service, localhost HTTP port, hook and lock names, executable names, and every file and directory it uses on disk. The daemon, its command-line tool and the app that hosts it all read these values instead of spelling them again. The daemon has no history, so there are no legacy names to read or migrate.

The values that could collide differ from the Stenographer daemon's (`StenographerIdentifiers`, `StenographerPaths`); only the launchd output file names `stdout.log` and `stderr.log` are the same, and they sit in separate logs directories. Both daemons run on one machine without sharing a label, a port, a hook marker or a directory. `ADKDIdentifiers` is a caseless enum of static constants. `ADKDPaths` is a `Sendable` struct that derives every path from one injectable home directory.

## Behavioral Requirements

- **label-value**: `ADKDIdentifiers.label` MUST be `com.agenticdevelopmentstudio.adkd`.
- **subsystem-is-label**: `ADKDIdentifiers.subsystem` MUST equal `label`.
- **subsystem-suffix**: `ADKDIdentifiers.subsystem(_:)` MUST return the label, a dot and the given suffix, with no escaping or validation of the suffix.
- **keychain-service**: `ADKDIdentifiers.keychainService` MUST be the label followed by `.daemon`.
- **http-port**: `ADKDIdentifiers.httpPort` MUST be `22849`.
- **http-base-url**: `ADKDIdentifiers.httpBaseURL` MUST be `http://127.0.0.1:` followed by `httpPort`, so the URL always carries the port constant.
- **hook-marker**: `ADKDIdentifiers.hookMarker` MUST be `# adkd-hook`, the text that marks a hook command as installed by this daemon.
- **hook-name**: `ADKDIdentifiers.hookName` MUST be `adkd`, the name its hook and status-line entries carry in Claude Code's settings.
- **hook-lock-name**: `ADKDIdentifiers.ownHookLockName` MUST be `.adkd-hooks.lock`, the lock file that serialises edits to Claude Code's hook settings.
- **cli-name**: `ADKDIdentifiers.cliName` MUST be `adk`, the tool at `Contents/Helpers/adk` in the app bundle.
- **daemon-executable-name**: `ADKDIdentifiers.daemonExecutableName` MUST be `adkd`, the executable at `Contents/MacOS/adkd` in the app bundle.
- **no-collision-with-stenographer**: Each of the following MUST differ from its Stenographer counterpart, and this list is the full contract: label, HTTP port, keychain service, hook marker, database file name, support directory, logs directory, launch-agent plist, drop directory name, socket file name and hook lock name.
- **storage-token**: `ADKDPaths.storageToken` MUST be `AgenticDeveloperKitchen`, the app's display name with non-alphanumerics dropped.
- **storage-token-duplicated**: The storage token is spelled in `ADKDPaths` because Core cannot import the database layer that derives it; the two spellings MUST agree.
- **storage-token-agreement-test**: A port MUST carry a test that asserts its spelled storage token equals the value the database layer derives from the display name.
- **display-name**: `ADKDPaths.displayName` MUST be `Agentic Developer Kitchen`, the name of the app's folder under Application Support.
- **file-names**: The database file MUST be named `adkd.db`, the ingest spool `ingest.db`, the launchd output files `stdout.log` and `stderr.log`, and the user-stop marker `daemon-stopped-by-user`. The type defines only the two launchd output file names (`launchdStdoutLogName`, `launchdStderrLogName`), not a path for them; callers choose the directory.
- **home-injection**: `ADKDPaths.init(home:)` MUST take the home directory as a parameter defaulting to the current user's home directory, and every path property MUST be derived from it.
- **storage-directory**: `storageDirectory` MUST be `.` followed by the lowercased storage token, directly under home (`~/.agenticdeveloperkitchen`).
- **support-directory**: `supportDirectory` MUST be the `adkd` directory under `storageDirectory`.
- **data-file-locations**: `databaseURL` and `spoolURL` MUST be the database and spool files inside `supportDirectory`, and `errorsDirectory` MUST be its `errors` subdirectory.
- **plugin-directories**: `pluginDirectories` MUST return exactly one URL: `Library/Application Support/Agentic Developer Kitchen/Plugins` under home.
- **claude-directory**: `claudeDirectory` MUST be `.claude` directly under home.
- **drop-directory**: `dropDirectory` MUST be `adkd-events` under `claudeDirectory`, where Claude Code's hooks drop events for the daemon to ingest.
- **socket-url**: `socketURL` MUST be `adkd.sock` under `claudeDirectory`.
- **logs-directory**: `logsDirectory` MUST be `Library/Logs/` followed by the label, under home.
- **launch-agent-plist**: `launchAgentPlist` MUST be `Library/LaunchAgents/` followed by the label and `.plist`, under home.
- **stop-marker-location**: `stopMarkerURL` MUST be the stop-marker file inside `supportDirectory`, beside the data the daemon owns.
- **pure-derivation**: The paths MUST be computed without touching the file system; nothing in the type creates, reads or checks a file or directory.

## Appearance

Not applicable — this is a set of identifier constants and path derivations, not a visual component.

## States

Not applicable — this is a set of identifier constants and path derivations, not a visual component.

## Accessibility

Not applicable — this is a set of identifier constants and path derivations, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| adkd-identifiers-001 | home-injection, storage-directory, support-directory, data-file-locations | `ADKDPaths(home: /tmp/adkd-home)` | `storageDirectory` is `/tmp/adkd-home/.agenticdeveloperkitchen`; `supportDirectory` ends `/adkd`; `databaseURL` ends `/adkd/adkd.db`; `spoolURL` ends `/adkd/ingest.db`; `errorsDirectory` ends `/adkd/errors` (test: testEveryPathIsTheExpectedAbsolutePath). |
| adkd-identifiers-002 | plugin-directories | Same home. | `pluginDirectories` is the one path `/tmp/adkd-home/Library/Application Support/Agentic Developer Kitchen/Plugins` (test: testEveryPathIsTheExpectedAbsolutePath). |
| adkd-identifiers-003 | claude-directory, drop-directory, socket-url | Same home. | `/tmp/adkd-home/.claude`, `/tmp/adkd-home/.claude/adkd-events`, `/tmp/adkd-home/.claude/adkd.sock` (test: testEveryPathIsTheExpectedAbsolutePath). |
| adkd-identifiers-004 | logs-directory, launch-agent-plist, stop-marker-location | Same home. | `/tmp/adkd-home/Library/Logs/com.agenticdevelopmentstudio.adkd`, `/tmp/adkd-home/Library/LaunchAgents/com.agenticdevelopmentstudio.adkd.plist`, `/tmp/adkd-home/.agenticdeveloperkitchen/adkd/daemon-stopped-by-user` (test: testEveryPathIsTheExpectedAbsolutePath). |
| adkd-identifiers-005 | storage-directory, storage-token | `ADKDPaths.storageToken` | The last component of `storageDirectory` equals a dot plus the lowercased token (test: testTheStorageDirectoryIsTheDotLowercasedToken). |
| adkd-identifiers-006 | http-port, http-base-url | `httpPort`, `httpBaseURL` | `22849` and `http://127.0.0.1:22849`; the URL text contains the port (test: testTheBaseURLIsBuiltFromThePort). |
| adkd-identifiers-007 | label-value, subsystem-suffix, keychain-service, hook-marker, hook-lock-name, cli-name, daemon-executable-name | The static constants and `subsystem("db")`. | `com.agenticdevelopmentstudio.adkd`; `com.agenticdevelopmentstudio.adkd.db`; `com.agenticdevelopmentstudio.adkd.daemon`; `# adkd-hook`; `.adkd-hooks.lock`; `adk`; `adkd` (test: testTheNamesAreFixed). |
| adkd-identifiers-008 | no-collision-with-stenographer | Compare against `StenographerIdentifiers` and `StenographerPaths` for the same home. | Label, port, keychain service, hook marker, database file name, support directory, logs directory, launch-agent plist, drop directory name, socket file name and lock name all differ (test: testNothingCollidesWithStenographer). |
| adkd-identifiers-009 | subsystem-suffix | `subsystem("")` | The label followed by a trailing dot: `com.agenticdevelopmentstudio.adkd.` (test: testV9_anEmptySuffixLeavesATrailingDot). |
| adkd-identifiers-010 | pure-derivation | `ADKDPaths(home:)` with a home directory that does not exist. | Every property still returns a URL; nothing is created (test: testV10_aMissingHomeStillYieldsEveryPathAndCreatesNothing). |
| adkd-identifiers-011 | subsystem-is-label, hook-name | `ADKDIdentifiers.subsystem`, `ADKDIdentifiers.hookName` | `com.agenticdevelopmentstudio.adkd` and `adkd` (test: testV11_theSubsystemPropertyIsTheLabelAndTheHookNameIsAdkd). |
| adkd-identifiers-012 | display-name, storage-token | `ADKDPaths.displayName`, `ADKDPaths.storageToken` | `Agentic Developer Kitchen` and `AgenticDeveloperKitchen` (test: testV12_theDisplayNameAndStorageTokenAreSpelledOut). |
| adkd-identifiers-013 | file-names | `ADKDPaths.launchdStdoutLogName`, `ADKDPaths.launchdStderrLogName` | `stdout.log` and `stderr.log` (test: testV13_theLaunchdLogFileNamesAreFixed). |
## Edge Cases

- **Null / empty input**: `subsystem("")` returns the label plus a trailing dot; the suffix is not validated (the type MUST NOT reject it). A `home` that does not exist yields URLs for nonexistent paths without error.
- **Boundary values**: `httpPort` is fixed at `22849`; the type does not check that the port is free. No numeric input is accepted.
- **Concurrent access**: Not applicable: every member is an immutable constant or a pure computed property over an immutable `home`, and `ADKDPaths` is `Sendable`.
- **Error states**: Not applicable: no member throws, returns an optional or touches the file system.
- **Offline / disconnected state**: Not applicable: the type performs no network access; `httpBaseURL` is only a string naming the loopback address.
- **Drift between the two storage-token spellings**: `storageToken` is a hand-written copy of a value the database layer derives from the display name. The doc comment on `ADKDPaths.storageToken` in `ADKDIdentifiers.swift` says a test in the app's own target checks the two agree; that test is outside the sources given here, so a port carries its own check (see `storage-token-agreement-test`).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| home | `URL` | the current user's home directory | The root every `ADKDPaths` property derives from; injected by tests. |

The type reads no environment variable or settings key.

## Deep Linking

Not applicable: the type defines no URL scheme or route; `httpBaseURL` addresses the daemon's own HTTP port, not a navigation destination.

## Localization

Not applicable: the type holds identifiers, file names and the folder name `Agentic Developer Kitchen`, which names a directory on disk and is never shown through a localization table.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Names and paths only. `keychainService` names a keychain service but the type stores or reads no credential.
- **Storage**: None; the type writes nothing.
- **Transmission**: None; `httpBaseURL` is a loopback address string.
- **Retention**: Not applicable: no data is kept.

## Logging

Not applicable: the type calls no logging API; `subsystem(_:)` only builds the subsystem string that callers pass to their own loggers.

## Platform Notes

- **SwiftUI**: Source is `Core/Stenographer/ADKDIdentifiers.swift`, importing only `Foundation`. `ADKDIdentifiers` is a caseless `enum` of `static let` constants and one `static func`; `ADKDPaths` is a `Sendable` struct with a private `home` and computed `URL` properties built with `appendingPathComponent(_:isDirectory:)`. Nothing is SwiftUI-specific.
- **Compose**: Use a Kotlin `object` with `const val` for the strings and port, and a class taking a `File` home. Android has no per-user home or launchd, so paths would come from `Context.filesDir` and the launchd, hook and socket members would not apply.
- **React/Web**: A frozen module-level object for the constants and a function taking a home path string, joined with `path.join` under Node. A browser has no file system, so only the string constants and `httpBaseURL` translate.
- **AppKit / UIKit**: Identical to the SwiftUI note: the source is UI-framework-agnostic and uses `FileManager.default.homeDirectoryForCurrentUser`, which is macOS-only; on iOS the app sandbox container replaces the home directory.
- **WinUI 3**: Use a `static class` with `const string` and `const int` members, and a class taking a base `DirectoryInfo` or string, building paths with `Path.Combine`. Default the base to `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)`, with `Windows.Storage.ApplicationData.Current.LocalFolder` for packaged apps. The launchd plist, `Library/Logs` and keychain names have no Windows equivalent: map the label to a Windows service or scheduled-task name, the keychain service to a `Windows.Security.Credentials.PasswordVault` resource name, and the Unix socket to a named pipe or a loopback port.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/ADKDIdentifiers.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every launchd, log, keychain, hook, port and path name is spelled once, in this type, and read by the daemon, CLI and host app.
**Rationale**: The doc comment on `ADKDIdentifiers` in `ADKDIdentifiers.swift` states the aim: the three binaries never spell them twice, so a rename or a collision fix lands in one place.
**Approved**: pending

**Decision**: Every identifier and path that could collide differs from the Stenographer daemon's, and a test asserts it.
**Rationale**: The launchd output file names `stdout.log` and `stderr.log` are shared but live in separate logs directories. Both daemons run on one machine; sharing a label, port, hook marker or directory would make them overwrite each other's state.
**Approved**: pending

**Decision**: The storage token is duplicated in `ADKDPaths` instead of derived.
**Rationale**: Core cannot import the database layer that derives it; the duplicate is accepted and its agreement is checked by a test in another target.
**Approved**: pending

**Decision**: There are no legacy names and no migration.
**Rationale**: The doc comment on `ADKDIdentifiers` in `ADKDIdentifiers.swift` states the daemon has no history, so nothing needs to be read from an older location.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |

`separation-of-concerns` passes because the type only names things; creating directories, registering with launchd and opening the keychain stay with callers. `unit-test-coverage` passes: `ADKDIdentifiersTests` (`ADKDIdentifiersTests.swift`) asserts every path, the base URL, the fixed names, the empty-suffix and nonexistent-home behaviors, the `subsystem`, `hookName`, `displayName`, storage-token and launchd log file name literals, and the absence of collisions with the Stenographer daemon. The agreement of the storage token with the database layer is a requirement for the app's own target, not a vector here. `ADKDIdentifiersTests` asserts every path, the base URL, the fixed names and the absence of collisions with the Stenographer daemon, but the empty-suffix and nonexistent-home behaviors, the `subsystem`, `hookName`, `displayName`, storage-token and launchd log file name literals, and the agreement of the storage token with the database layer have no test here. `no-hardcoded-strings` passes because none of the strings is shown to a user; they are identifiers and file names.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ADKDIdentifiersTests.swift, 13 of 13 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Reworded the collision requirement as a full list, cited source comments, made the storage-token agreement test a named requirement, added vectors for the untested literals, downgraded unit-test-coverage to partial, and linked Stenographer Identifiers. |
