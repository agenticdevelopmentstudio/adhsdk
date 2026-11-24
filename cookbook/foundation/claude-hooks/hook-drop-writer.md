---
id: f3326f3a-cccd-4ac5-8dc1-84d660ed4581
title: "Hook Drop Writer"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Chooses a configuration's drop directory, with a per-configuration override variable, and writes each hook envelope there as one atomically renamed JSON file."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - drop-file
  - atomic-write
  - file-system
depends-on: []
related:
  - 826153e3-cae8-4917-a1d3-c298a54ab558
  - 704d4ae9-e344-44d4-b19c-eadfec082077
  - 9eb46f78-0ceb-455f-9584-b6b43ddf0871
references: []
approved-by: ""
approved-date: ""
---

# Hook Drop Writer

## Overview

`HookDropWriter` is where a hook helper writes its drop files and how it writes them. A drop file is the hook helper's fallback transport: when no daemon is listening, the envelope lands in the configuration's drop directory and the daemon scans it in later.

The type is a caseless enum with three public static functions. `dropDirectoryVariable` names the environment variable that overrides the directory for one configuration. `dropDirectory` picks the override when it is set and non-empty, otherwise the configuration's own directory. `writeDropFile` encodes an envelope and puts it in a directory as a new, uniquely named JSON file, written to a temporary name first and then renamed so that a scanner never sees a half-written file.

It is called by the hook capture command (HookCaptureCommand ([adhsdk.ingredient.foundation.claude-hooks.hook-capture-command](cookbook:826153e3-cae8-4917-a1d3-c298a54ab558))) and by the status-line feed (StatusLineCapture ([adhsdk.ingredient.foundation.claude-hooks.status-line-capture](cookbook:704d4ae9-e344-44d4-b19c-eadfec082077))) when the daemon refuses a post. Both pass the environment explicitly, which is how tests redirect output to a temporary directory.

## Behavioral Requirements

### Override variable

- **variable-name**: `dropDirectoryVariable` MUST return the configuration's `name` upper-cased, with every Unicode scalar that is not an ASCII letter or digit replaced by one `_`, followed by `_DROP_DIR`.
- **variable-per-configuration**: Two configurations with different names MUST yield different variables, so one daemon's override is never read by another.
- **variable-empty-name**: An empty `name` currently yields `_DROP_DIR` because the source adds no validation of the name; a port MAY reject an empty name instead.

### Directory choice

- **override-wins**: `dropDirectory` MUST return the value of the configuration's override variable from the supplied environment when that variable is present and not the empty string.
- **empty-override-ignored**: `dropDirectory` MUST return `configuration.dropDirectory` when the override variable is absent or is the empty string.
- **other-variable-ignored**: `dropDirectory` MUST NOT read the override variable of any other configuration.
- **tilde-preserved**: `dropDirectory` MUST return its result without expanding a leading `~`; expansion is the job of `writeDropFile`.
- **environment-default**: The `environment` parameter of `dropDirectory` MUST default to the current process environment.
- **production-no-override**: Production hooks SHOULD NOT set the override variable; it exists so tests can route output to a temporary directory without rewiring installed hooks.

### Writing

- **tilde-expansion**: `writeDropFile` MUST expand a leading `~` in the directory to the user's home directory before use.
- **directory-created**: `writeDropFile` MUST create the directory, with any missing intermediate directories, before writing, and MUST NOT fail when it already exists.
- **json-encoding**: `writeDropFile` MUST encode the envelope as a single JSON object with default options as a single compact line; key order is unspecified.
- **file-name**: The final file name MUST be the current Unix time in milliseconds (base 10, no padding or sign), a hyphen, eight lowercase hexadecimal characters taken from a fresh random UUID, and the extension `.json`, so it matches `^\d+-[0-9a-f]{8}\.json$`.
- **unique-names**: Two calls MUST produce different names even within the same millisecond, because of the random suffix.
- **atomic-publish**: `writeDropFile` MUST write the encoded bytes to a file named like the final one with `.tmp` appended, and MUST then move that file to the final name, so that no file with the `.json` extension is ever partially written.
- **errors-thrown**: `writeDropFile` MUST throw, and not return a status, when the directory cannot be created, the encoder reports a Swift error for the envelope, the temporary file cannot be written, or the move fails; the caller decides whether to ignore the error.
- **no-overwrite**: The move to the final name MUST fail rather than replace an existing file of that name.
- **temp-left-on-move-failure**: When the move fails, the `.tmp` file is currently left in place because the source does not remove it; a port MAY remove it on a best-effort basis.
- **envelope-serializable**: NEEDS REVIEW: Not implemented in source. `writeDropFile` never checks that the envelope is valid JSON before encoding, and the encoder reports an unrepresentable value by raising an Objective-C exception that a Swift error handler cannot catch, so the declared `throws` contract does not cover it; a test passing a `Date` or a NaN value would show whether the process aborts.

### Concurrency

- **stateless**: The type MUST hold no shared mutable state; concurrent callers in one or many processes coordinate only through the file system and the unique names.

## Appearance

Not applicable — this is a file-writing helper with no visible output, not a visual component.

## States

Not applicable — this is a stateless helper with no visual states, not a visual component.

## Accessibility

Not applicable — this is a non-interactive file-writing helper, not a visual component.

## Conformance Test Vectors

Derived from `HookCaptureTests` where a test is named, and from the source otherwise.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| drop-001 | variable-name, variable-per-configuration | Configurations named `stenographer` and `adkd` (test `testEachConfigurationReadsItsOwnDropDirectoryVariable`) | `STENOGRAPHER_DROP_DIR` and `ADKD_DROP_DIR` |
| drop-002 | variable-name | A configuration named `my-app.v2` | `MY_APP_V2_DROP_DIR` |
| drop-003 | variable-name | A configuration named `café` | `CAF__DROP_DIR` (the accented letter is not ASCII, so it becomes `_`) |
| drop-004 | variable-empty-name | A configuration named with the empty string | `_DROP_DIR` |
| drop-005 | override-wins | Configuration `adkd`, environment `ADKD_DROP_DIR=/tmp/x` (test `testTheVariableOverridesTheConfiguredDirectoryOnlyWhenNonEmpty`) | `/tmp/x` |
| drop-006 | empty-override-ignored, tilde-preserved | Configuration `adkd`, environment `ADKD_DROP_DIR=` (empty) | `~/.claude/adkd-events`, unexpanded |
| drop-007 | other-variable-ignored | Configuration `adkd`, environment `STENOGRAPHER_DROP_DIR=/tmp/y` (same test) | `~/.claude/adkd-events` |
| drop-008 | empty-override-ignored | Configuration `adkd`, empty environment | `~/.claude/adkd-events` |
| drop-009 | directory-created, json-encoding, file-name, atomic-publish | `writeDropFile` of an envelope with event `Stop` into a directory that does not exist (`testRunWritesADropFileForTheEvent` asserts the file count and the event; the rest follows from the source) | The directory exists afterwards; it holds exactly one file ending in `.json` (asserted by the test) and no `.tmp` file; the name matches the pattern of digits, a hyphen, eight lowercase hex characters, and `.json`; the file is one line of compact JSON that parses as an object whose `event` is `Stop` (asserted by the test) |
| drop-010 | tilde-expansion | `writeDropFile` with directory `~/drop-test` (no test; derived from the source) | The file is created under the user's home directory, not in a directory literally named `~` |
| drop-011 | unique-names | Two `writeDropFile` calls in quick succession into one directory | Two distinct `.json` files |
| drop-012 | errors-thrown | `writeDropFile` with a directory path whose parent is a regular file | Throws; no file is created |
| drop-013 | errors-thrown, directory-created | `writeDropFile` into an existing directory twice | Both calls succeed; two files |
| drop-014 | no-overwrite, temp-left-on-move-failure | A file with the chosen final name already exists when the move runs (source inspection only today; with an injected clock and suffix source, pre-create that name) | The move throws and the `.tmp` file remains |
| drop-015 | atomic-publish | A scanner lists the directory for `.json` files while a write is in progress (source inspection only; it cannot be reproduced deterministically) | It never sees a partial file; only complete `.json` files or the `.tmp` name |
| drop-016 | override-wins, directory-created | `StatusLineCapture.feed` with `ADKD_DROP_DIR` set and `post` returning false (test `testAFeedTheDaemonRefusesIsDroppedInTheConfigurationsDirectory`) | One drop file with event `StatusLine` appears in the override directory |
| drop-017 | environment-default | `dropDirectory` called without an `environment` argument while the process environment holds the configuration's override variable | The override value is returned |
| drop-018 | stateless | Twenty `writeDropFile` calls from concurrent threads into one directory | Twenty distinct `.json` files, no errors |

SHOULD requirement `production-no-override` has no vector: it constrains how hooks are installed, not what this code returns, and its rationale is the third entry under Design Decisions. The open question on `envelope-serializable` has no vector because the behavior it asks about is undefined.

## Edge Cases

- **Null and empty input**: an empty override value is treated as unset (MUST). An empty directory string is not checked by the source; a relative or empty path resolves against the process working directory through the file URL initializer, and the source defines nothing further. An empty envelope encodes to the two-character object and is written like any other.
- **Boundary values**: a configuration name with no ASCII letters or digits yields a variable made only of underscores plus the suffix (MUST, per `variable-name`). Names are upper-cased before filtering, so a lowercase ASCII letter keeps its letter.
- **Tilde forms**: `expandingTildeInPath` handles a leading `~` and a leading `~user`; a `~` anywhere else is literal (MUST, per `tilde-expansion`).
- **Concurrent access**: concurrent writers into one directory (many hook processes at once) cannot collide on a name except by a repeated millisecond and a repeated 32-bit random suffix; if they did, the second move would throw and leave its `.tmp` file (MUST, per `no-overwrite`). No lock is taken.
- **Error states**: a directory that cannot be created, a full disk, a permission failure or a failed move surface as thrown errors, never as return values (`errors-thrown`). The caller `HookCaptureCommand` swallows them; the status-line feed also swallows them with `try?`.
- **Leftover temporary files**: a crash or a move failure between the write and the rename leaves a `.tmp` file that nothing in this component removes or reports; scanners that filter on the `.json` extension ignore it (see `temp-left-on-move-failure`).
- **Unrepresentable envelope**: see the open question on `envelope-serializable`.
- **Offline or disconnected state**: not applicable — the component only touches the local file system and never uses the network; its purpose is to work when no daemon is reachable.
- **File permissions**: the directory and file are created with the file system's default permissions; the source sets no mode.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | `ClaudeHookConfiguration` | none | Supplies `name` (for the variable) and `dropDirectory` (the default location) |
| `environment` | string map | the current process environment | Where the override variable is looked up |
| `<NAME>_DROP_DIR` | environment variable | unset | Overrides the directory for the configuration whose name matches; tests only |
| `ClaudeHookConfiguration.dropDirectory` | string | for example `~/.claude/stenographer-events`, `~/.claude/adkd-events` | The tilde-form default directory |
| `directory` | string | none | The directory `writeDropFile` writes into; may begin with `~` |
| `envelope` | string-keyed map | none | The value to encode |

## Deep Linking

Not applicable: the component writes files and registers no URL scheme or route.

## Localization

Not applicable: the component produces no user-facing text; file names are a numeric and hexadecimal machine format.

## Accessibility Options

Not applicable: the component has no visual or motion output.

## Feature Flags

Not applicable: the source reads no feature-flag service; the override variable is a test hook, not a flag.

## Analytics

Not applicable: the component sends no analytics events.

## Privacy

- **Data collected**: none of its own; it writes whatever envelope the caller passes, which the hook capture command fills with the hook payload, account names and process context.
- **Storage**: one JSON file per call in the drop directory, with default file-system permissions; the source sets no restrictive mode and applies no encryption.
- **Transmission**: none; the file stays on the machine.
- **Retention**: the component never deletes a file; the daemon that scans the directory owns removal, and a `.tmp` leftover is never removed by this code.

## Logging

Not applicable: the component makes no log call; failures are thrown to the caller.

## Platform Notes

- **SwiftUI**: not used; this is a Foundation-only helper with no view layer.
- **Compose**: not used. An Android or JVM port starts from `java.nio.file.Files.createDirectories`, `Files.write` to a `.tmp` path and `Files.move` with `StandardCopyOption.ATOMIC_MOVE`, which throws `FileAlreadyExistsException` or `AtomicMoveNotSupportedException` instead of replacing; `System.getenv` supplies the override, and `System.currentTimeMillis` and `UUID.randomUUID().toString().replace("-", "").take(8)` supply the name.
- **React/Web**: a Node.js port uses `fs.mkdirSync` with `recursive: true`, `fs.writeFileSync` to a `.tmp` name and `fs.renameSync`, which silently replaces an existing file on POSIX (use `fs.linkSync` then `fs.unlinkSync`, or `fs.copyFileSync` with `COPYFILE_EXCL`, to keep the no-overwrite rule); `Date.now()` and `crypto.randomUUID()` supply the name; `os.homedir()` replaces tilde expansion. A browser has no file system.
- **AppKit / UIKit**: this is the source platform. File: `Core/ClaudeHooks/HookDropWriter.swift`, exercised by `HookCaptureTests`. It uses `NSString.expandingTildeInPath`, `FileManager.createDirectory(at:withIntermediateDirectories:)`, `JSONSerialization.data(withJSONObject:)`, `Data.write(to:options:)` with `.atomic` (which itself writes through a hidden temporary and renames) followed by `FileManager.moveItem`, and `UUID` for the suffix. Nothing touches AppKit or UIKit.
- **WinUI 3**: implement as a static class in a .NET library. Read the override with `Environment.GetEnvironmentVariable`; replace tilde expansion by testing for a leading `~` and joining the rest to `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)` with `Path.Combine`, because .NET does not expand `~`. Create the directory with `Directory.CreateDirectory`, which is idempotent and creates intermediates. Encode with `System.Text.Json.JsonSerializer.SerializeToUtf8Bytes` over a `JsonObject` or a dictionary, whose encoder throws a catchable `NotSupportedException` or `JsonException` for unsupported values (unlike the Objective-C exception here). Name the file with `DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()` and `Guid.NewGuid().ToString("N")[..8]`. Write with `File.WriteAllBytes` to the `.tmp` path and publish with `File.Move(tmp, final, overwrite: false)`, which throws `IOException` when the destination exists and is a same-volume rename on NTFS. Under a packaged WinUI app, a path in the user's profile is writable, but `Windows.Storage.ApplicationData` locations are virtualised for MSIX apps, so a helper that must share a directory with a daemon should use a real profile path rather than `ApplicationData.Current.LocalFolder`. Replace the dotted `.claude` convention with whatever directory the daemon scans.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/HookDropWriter.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Files are written to `<final>.tmp` and then renamed to `<final>`.
**Rationale**: The daemon scans the directory while hooks write into it; a scanner that filters on the `.json` extension never sees a partial file. The source states this sequence in the doc comment on `writeDropFile`.
**Approved**: pending

**Decision**: The name is a millisecond timestamp plus eight random hex characters.
**Rationale**: The timestamp orders files roughly by arrival and the random suffix keeps concurrent hook processes from colliding.
**Approved**: pending

**Decision**: The override variable is derived from the configuration name.
**Rationale**: Several daemons share one machine and one `settings.json`; a per-name variable lets a test redirect one daemon's drops without affecting another's, and the source comment states production hooks never set it.
**Approved**: pending

**Decision**: `dropDirectory` leaves a leading `~` unexpanded.
**Rationale**: The configuration stores the tilde form that hooks use; expansion happens once, at the point of writing, so the choice of directory stays testable as a string.
**Approved**: pending

**Decision**: Temporary files left by a failed move are not cleaned up, and no error is reported beyond the throw.
**Rationale**: The source has no cleanup path. Because the temporary name does not end in `.json`, scanners ignore it, so the cost is leaked disk space rather than a wrong read.
**Approved**: pending

**Decision**: The directory and the file are created with the file system's default permissions, not owner-only (0700 directory, 0600 file).
**Rationale**: The envelope carries account emails and process context, so owner-only permissions may be warranted; the source sets no mode today, and this is recorded as an open choice.
**Approved**: pending

**Decision**: A port gives `writeDropFile` an injectable clock and suffix source.
**Rationale**: The source reads the clock and a random UUID directly, so the name and collision vectors cannot be asserted deterministically; injection lets a test pre-create the target name.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | partial | privacy-and-data |

The component separates concerns cleanly: directory choice and file publication are three small functions whose only side effects are creating the directory and publishing the file. Unit-test coverage is partial: `HookCaptureTests` and `HookDropWriterConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/HookDropWriterConformanceTests.swift`) cover drop-001 to drop-013, drop-016, drop-017 and drop-018; drop-014 (no overwrite of an existing final name) is skipped because the name comes from the wall clock and a random suffix that cannot be injected, and drop-015 (a scanner never sees a partial file) is skipped because a write in progress cannot be observed deterministically. Explicit error handling is partial because the functions throw, but an unencodable envelope raises an exception outside that channel (the open question on `envelope-serializable`). Data integrity is passed because publication is a write followed by a rename. Secure data storage is partial because the file takes default permissions and the source applies no mode or encryption to payloads that carry account emails and process context. Data retention is partial because the component deletes nothing, including its own `.tmp` leftovers.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (HookDropWriterConformanceTests.swift, 16 of 18 vectors; drop-014 and drop-015 skipped); unit-test-coverage stays partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved source paths out of references, linked sibling recipes, downgraded accidental-gap MUSTs to current behavior, pinned the file-name regex and key-order wording, and added pending decisions on permissions and an injectable clock. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
