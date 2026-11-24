---
id: b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
title: "Stenographer Identifiers"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The one place Stenographer's launchd label, ports, keychain services and on-disk paths are spelled, with legacy names that are read and migrated but never written."
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
  - 1d48ed86-5704-4631-b643-36f7450c1c83
references: []
approved-by: ""
approved-date: ""
---

# Stenographer Identifiers

## Overview

`StenographerIdentifiers` and `StenographerPaths` are the single spelling of every name the Stenographer daemon owns: its launchd label, log subsystems, keychain services, localhost ports, and the directories and files it uses on disk. The daemon, the app and the `steno` tool read these values instead of spelling them again.

Stenographer 1.0.173 renamed the product's identifiers. The `legacy*` values are the pre-1.0.173 Stenographer names: they are read, matched and migrated, and never written. Because the daemon migrates the legacy support directory to the current one at its own pace, `StenographerPaths` resolves which directory holds the user's data at the moment it is asked, and offers `writeSupportFile` to follow the directory if it moves under a write.

`StenographerIdentifiers` is a caseless enum of static constants and one function. `StenographerPaths` is a `Sendable` struct that derives every path from one injectable home directory and one injectable existence check.

## Behavioral Requirements

- **label-value**: `StenographerIdentifiers.label` MUST be `com.agenticdevelopmentstudio.stenographer`.
- **legacy-label-values**: `legacyLabel` MUST be `com.agentic-cookbook.stenographer` and `legacyMenubarLabel` MUST be `com.agentic-cookbook.stenographer.menubar`.
- **subsystem-is-label**: `StenographerIdentifiers.subsystem` MUST equal `label`.
- **subsystem-suffix**: `subsystem(_:)` MUST return the label, a dot and the given suffix, with no escaping or validation of the suffix.
- **keychain-service-values**: `keychainService` MUST equal `label`, `daemonKeychainService` MUST be the label followed by `.daemon`, and `legacyDaemonKeychainService` MUST be `com.agentic-cookbook.stenographer.daemon`.
- **http-port**: `httpPort` MUST be `22847`, and `httpBaseURL` MUST be `http://127.0.0.1:` followed by `httpPort`.
- **router-port**: `routerPort` MUST be `22848` and `routerBaseURL` MUST be `http://127.0.0.1:` followed by `routerPort`; it is where `ANTHROPIC_BASE_URL` points when account routing is used and MUST NOT be the same listener as `httpPort`.
- **file-names**: `StenographerPaths.databaseFileName` MUST be `stenographer.db`, `launchdStdoutLogName` MUST be `stdout.log` and `launchdStderrLogName` MUST be `stderr.log`.
- **home-injection**: `StenographerPaths.init(home:exists:)` MUST default `home` to the current user's home directory and `exists` to a file-system check of the URL's path, and every path property MUST be derived from them.
- **support-directories**: `currentSupportDirectory` MUST be `Library/Application Support/` followed by the label, and `legacySupportDirectory` the same with the legacy label, both under home.
- **plugin-directories**: `pluginDirectories` MUST return two URLs in order, the `Plugins` directory under `currentSupportDirectory` and then the one under `legacySupportDirectory`, whether or not either exists.
- **plugin-directories-both**: `pluginDirectories` MUST NOT be reduced to the resolved `supportDirectory`, because the daemon may move the legacy directory after the app has discovered plugins at launch.
- **support-directory-resolution**: `supportDirectory` MUST be the current directory when the file `stenographer.db` exists in it; otherwise the legacy directory when that directory exists; otherwise the current directory.
- **empty-current-does-not-hide**: An existing current directory without the database file MUST NOT be chosen over an existing legacy directory.
- **write-support-file**: `writeSupportFile(named:attempts:_:)` MUST call the closure with the named file inside `supportDirectory`, then resolve `supportDirectory` again, and repeat the write at the new location when the resolved URL changed.
- **write-support-file-attempts**: `writeSupportFile` MUST write at most `max(attempts, 1)` times (default 3), MUST stop as soon as the resolved URL matches the one just written, and MUST return the URL resolved after its last write. That is where the file was last written when the directory settled; when the attempts run out while the directory is still moving, it is the newly resolved URL that no write reached, and the function raises no error and gives the caller no other signal that it gave up (see the Design Decisions).
- **write-support-file-errors**: `writeSupportFile` MUST rethrow the closure's error unchanged and MUST NOT retry after a throw.
- **logs-directories**: `currentLogsDirectory` MUST be `Library/Logs/` followed by the label, `legacyLogsDirectory` the same with the legacy label, and `logsDirectory` MUST be the current one when it exists, else the legacy one when it exists, else the current one.
- **launch-agent-plists**: `launchAgentPlist`, `legacyLaunchAgentPlist` and `legacyMenubarLaunchAgentPlist` MUST be `Library/LaunchAgents/<label>.plist` under home for the label, legacy label and legacy menubar label.
- **legacy-never-written**: Callers MUST NOT use the legacy names to create new files; they exist so the daemon and app can read, recognise and migrate old installs. These types only return names and paths, so they cannot enforce this; it is guidance for their callers.
- **existence-only-for-resolution**: `StenographerPaths` MUST touch the file system only through the injected `exists` closure, and only in `supportDirectory` and `logsDirectory`; every other property is a pure derivation.
- **logs-directory-no-sentinel**: `logsDirectory` MUST decide by whether the directory exists, not by whether it holds any file, so an existing but empty current logs directory is chosen over a populated legacy one. This differs from `supportDirectory` on purpose (see the Design Decisions).
- **sendability**: `StenographerPaths` MUST be `Sendable`, so the `exists` closure is `@Sendable`.

## Appearance

Not applicable — this is a set of identifier constants and path derivations, not a visual component.

## States

Not applicable — this is a set of identifier constants and path derivations, not a visual component.

## Accessibility

Not applicable — this is a set of identifier constants and path derivations, not a visual component.

## Conformance Test Vectors

The source has no test file of its own. `ADKDIdentifiersTests` (the Kitchen daemon's identifiers, [adhsdk.ingredient.foundation.stenographer.adkd-identifiers](cookbook:1d48ed86-5704-4631-b643-36f7450c1c83)) builds `StenographerPaths(home:exists:)` with `exists` always false and compares several of its values with the Kitchen daemon's; all other vectors are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-identifiers-001 | http-port | `httpPort`, `httpBaseURL` | `22847` and `http://127.0.0.1:22847`. |
| stenographer-identifiers-002 | router-port | `routerPort`, `routerBaseURL` | `22848` and `http://127.0.0.1:22848`, different from the HTTP port. |
| stenographer-identifiers-003 | label-value, keychain-service-values | The label and keychain constants. | `com.agenticdevelopmentstudio.stenographer`; `daemonKeychainService` `com.agenticdevelopmentstudio.stenographer.daemon`; legacy daemon service `com.agentic-cookbook.stenographer.daemon`. |
| stenographer-identifiers-004 | subsystem-suffix | `subsystem("db")` and `subsystem("")` | `com.agenticdevelopmentstudio.stenographer.db` and the label followed by a trailing dot. |
| stenographer-identifiers-005 | support-directory-resolution | `exists` is true only for `<current>/stenographer.db` | `supportDirectory` is `<home>/Library/Application Support/com.agenticdevelopmentstudio.stenographer`. |
| stenographer-identifiers-006 | support-directory-resolution, empty-current-does-not-hide | `exists` is true for the legacy directory and for the current directory but not for the database file. | `supportDirectory` is the legacy directory. |
| stenographer-identifiers-007 | support-directory-resolution | `exists` is always false (the fresh-install case that `ADKDIdentifiersTests` builds). | `supportDirectory` is the current directory; `logsDirectory` is the current logs directory. |
| stenographer-identifiers-008 | plugin-directories, plugin-directories-both | Any `home`. | Two URLs, the current then the legacy `Plugins` directory, in that order. |
| stenographer-identifiers-009 | write-support-file, write-support-file-attempts | The closure creates the file; `exists` flips to make the legacy directory resolve to the current one after the first write. | The closure runs twice, the second time in the current directory, and the returned URL is the current one. |
| stenographer-identifiers-010 | write-support-file-attempts | `attempts: 0` and a directory that never stabilises. | The closure runs once (`max(attempts, 1)`), and the returned URL is the one resolved after that write, not a location written to. |
| stenographer-identifiers-011 | write-support-file-errors | The closure throws. | The error propagates and the closure has run once. |
| stenographer-identifiers-012 | launch-agent-plists | Any `home`. | `Library/LaunchAgents/` plus the label, legacy label and legacy menubar label, each with `.plist`. |
| stenographer-identifiers-013 | label-value, http-port, keychain-service-values, file-names, support-directories, logs-directories, launch-agent-plists | Compare with `ADKDIdentifiers` (test: testNothingCollidesWithStenographer). | The label, port, keychain service, database name, support directory, logs directory and launch-agent plist all differ. |
| stenographer-identifiers-014 | write-support-file-attempts | `attempts: 3` and a directory that changes every time it resolves. | The closure runs three times and the returned URL is the one resolved after the last write, not a location written to (derived from the source; no test). |
| stenographer-identifiers-015 | legacy-label-values | `legacyLabel` and `legacyMenubarLabel`. | `com.agentic-cookbook.stenographer` and `com.agentic-cookbook.stenographer.menubar` (derived from the source; no test). |
| stenographer-identifiers-016 | subsystem-is-label | `StenographerIdentifiers.subsystem` and `label`. | The two strings are equal (derived from the source; no test). |
| stenographer-identifiers-017 | home-injection | `StenographerPaths()` with no arguments, and `StenographerPaths(home: URL(fileURLWithPath: "/h"), exists: { _ in false })`. | The first derives its paths from the current user's home; the second from `/h` (derived from the source; no test). |
| stenographer-identifiers-018 | support-directories | `StenographerPaths(home: /h)`. | `currentSupportDirectory` is `/h/Library/Application Support/com.agenticdevelopmentstudio.stenographer` and `legacySupportDirectory` is the same under `com.agentic-cookbook.stenographer` (derived from the source; no test). |
| stenographer-identifiers-019 | existence-only-for-resolution | A counting `exists` closure; read `launchAgentPlist` and `pluginDirectories`, then `supportDirectory`. | The closure is not called for the first two and is called only for `supportDirectory` and `logsDirectory` (derived from the source; no test). |
| stenographer-identifiers-020 | logs-directories | `exists` is true only for the legacy logs directory. | `logsDirectory` is the legacy logs directory (derived from the source; no test). |
| stenographer-identifiers-021 | logs-directories, logs-directory-no-sentinel | `exists` is true for the current logs directory (empty) and the legacy logs directory. | `logsDirectory` is the current logs directory (derived from the source; no test). |
## Edge Cases

- **Null / empty input**: `subsystem("")` returns the label plus a trailing dot; the suffix is not validated. `writeSupportFile(named: "")` writes to the support directory itself; the name is not validated. `attempts` of 0 or less is raised to 1.
- **Boundary values**: `attempts` has no upper bound; a directory that moves on every resolution makes `writeSupportFile` run the closure `attempts` times and return the URL resolved after the last write (a location the closure never wrote to), with no error. The ports are fixed constants and the type does not check that they are free.
- **Concurrent access**: `StenographerPaths` is `Sendable` and holds only immutable values, so it may be shared across tasks. The file system under it is not serialised: the daemon may migrate the legacy directory at any moment, which `writeSupportFile` handles by re-resolving after each write, but a write that races a migration more than `attempts` times can still land in a directory the next read does not look in.
- **Error states**: No property throws or returns an optional. `writeSupportFile` rethrows the closure's error. A directory that is missing is not an error; resolution falls through to the current directory.
- **Empty current logs directory**: Unlike `supportDirectory`, `logsDirectory` checks no sentinel file. An existing empty current logs directory hides a populated legacy one, and `logsDirectory` returns the current directory.
- **Offline / disconnected state**: Not applicable: the types perform no network access; the base URLs are strings naming the loopback address.
- **Existing empty current directory**: An empty current directory next to a populated legacy one resolves to the legacy one, so a user's real data is never hidden.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| home | `URL` | the current user's home directory | The root every `StenographerPaths` property derives from. |
| exists | `@Sendable (URL) -> Bool` | file-system existence of the path | Injected by tests to simulate fresh, legacy and migrated installs. |
| attempts | `Int` | 3 | Maximum writes made by `writeSupportFile`. |

The types read no environment variable or settings key.

## Deep Linking

Not applicable: the types define no URL scheme or route; the base URLs address the daemon and router listeners, not navigation destinations.

## Localization

Not applicable: the types hold identifiers and file names, none shown to a user.

## Accessibility Options

Not applicable: the types present no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: Names and paths only. The keychain service names say where credentials live, but the types store or read no credential.
- **Storage**: None, apart from the closure the caller passes to `writeSupportFile`, which decides what is written.
- **Transmission**: None; the base URLs are loopback strings.
- **Retention**: Not applicable: no data is kept.

## Logging

Not applicable: the types call no logging API; `subsystem(_:)` only builds the subsystem string callers pass to their own loggers.

## Platform Notes

- **SwiftUI**: Source is `Core/Stenographer/StenographerIdentifiers.swift`, importing only `Foundation`. `StenographerIdentifiers` is a caseless `enum` of `static let` constants and one `static func`; `StenographerPaths` is a `Sendable` struct with computed `URL` properties built with `appendingPathComponent(_:isDirectory:)`. Nothing is SwiftUI-specific.
- **Compose**: Use a Kotlin `object` with `const val` strings and ports, and a class taking a `File` home and an existence function. Android has no launchd or per-user Library, so paths would derive from `Context.filesDir` and the launchd and plist members would not apply.
- **React/Web**: A frozen module-level object for the constants and a function taking a home path and an existence callback, joined with `path.join` under Node. A browser has no file system, so only the string constants and base URLs translate.
- **AppKit / UIKit**: Same source; `FileManager.default.homeDirectoryForCurrentUser` is macOS-only, and on iOS the app sandbox container replaces the home directory.
- **WinUI 3**: Use a `static class` with `const string` and `const int` members, and a class taking a base path and a `Func<string, bool>` that defaults to `Directory.Exists` or `File.Exists`, with `Path.Combine` for paths. Default the base to `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)` or `Windows.Storage.ApplicationData.Current.LocalFolder` for packaged apps. Map the label to a Windows service or scheduled-task name and the keychain services to `Windows.Security.Credentials.PasswordVault` resource names. Port `writeSupportFile` as a method taking an `Action<string>` and an attempt count, looping the same way.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerIdentifiers.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every launchd, log, keychain and path name is spelled once in these types.
**Rationale**: The aim is stated in the doc comment on `StenographerIdentifiers` in `StenographerIdentifiers.swift`: one place, so the daemon, app and tool cannot drift. The alternative is for each target to spell its own names, which is the drift the type exists to prevent.
**Approved**: pending

**Decision**: `supportDirectory` prefers a current directory that holds the database, then an existing legacy directory, then the current one.
**Rationale**: The comment on `StenographerPaths.supportDirectory` in `StenographerIdentifiers.swift` states that an empty new directory must not hide the user's real data while the daemon has not migrated yet. A plain existence check on the current directory, as `logsDirectory` uses, would let an empty current directory win.
**Approved**: pending

**Decision**: `pluginDirectories` returns both directories rather than the resolved one.
**Rationale**: The comment on `StenographerPaths.pluginDirectories` in `StenographerIdentifiers.swift` states the app discovers plugins once at launch and the daemon may move the legacy directory afterwards, so a single resolved path would point at a folder that has since moved.
**Approved**: pending

**Decision**: `writeSupportFile` re-resolves the directory after each write and repeats it if it moved, up to 3 times, and when the attempts run out it returns the newly resolved URL without raising an error.
**Rationale**: The comment on `StenographerPaths.writeSupportFile` in `StenographerIdentifiers.swift` states that a file written into the legacy directory just before the daemon migrates it could land where the next read never looks; the bound keeps the loop finite. Returning a result that says whether the directory settled would let a caller tell "settled" from "gave up", but the source returns a plain `URL`, so the silent case is accepted for now.
**Approved**: pending

**Decision**: `logsDirectory` checks only that a directory exists, with no sentinel file, while `supportDirectory` checks for `stenographer.db`.
**Rationale**: The source gives `logsDirectory` the simple existence rule in `StenographerIdentifiers.swift`, and it has no sentinel file to test because log files are not a fixed name. The asymmetry means an empty current logs directory hides a populated legacy one; checking for a log file would align the two, and the source does not do that.
**Approved**: pending

**Decision**: The legacy names are read, matched and migrated, never written.
**Rationale**: The comment on the `legacy*` values in `StenographerIdentifiers.swift` states this for the pre-1.0.173 Stenographer names so old installs stay recognised without new files appearing under old names.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the types only name things and resolve which directory exists; creating directories, registering with launchd and opening the keychain stay with callers. `unit-test-coverage` passes because every vector has a test in `StenographerIdentifiersConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/StenographerIdentifiersConformanceTests.swift`), covering directory resolution, `writeSupportFile` and the legacy paths; `ADKDIdentifiersTests` also keeps the collision check against the Kitchen daemon.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (StenographerIdentifiersConformanceTests.swift, 21 of 21 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Recorded the silent give-up and the logs-directory asymmetry as decisions, cited each decision's source symbol, added eight test vectors and the ADKDIdentifiers link, and named the product version. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
