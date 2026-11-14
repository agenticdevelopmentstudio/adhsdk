---
id: 517adfce-44e7-404e-8a7b-b1e304da32e7
title: "Claude Status Line"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The file side of Claude Code's shared statusLine slot: installs a versioned dispatcher and registers each tool as a renderer or tap entry beside it."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - foundation
  - status-line
depends-on:
  - 9c81ac1c-ee1e-45b1-824c-deee1850037c
related:
  - fc622208-1504-421f-8892-c5869820550c
references:
  - https://code.claude.com/docs/en/statusline
  - https://docs.python.org/3/library/shlex.html#shlex.quote
approved-by: ""
approved-date: ""
---

# Claude Status Line

## Overview

Claude Code has one `statusLine` slot in `settings.json`, and several tools want it. `ClaudeStatusLine` is the file side of the shared-dispatcher contract that lets them share it. The slot runs one dispatcher script (`~/.claude/claudehelpers/statusline/dispatch.sh`); each tool owns one file beside it, `renderers/<name>` (its output is shown) or `taps/<name>` (it only reads the payload), whose whole content is one shell command. A broken tool drops out of the line instead of blanking it, so no tool refuses or wraps another's command.

The type installs the dispatcher by version, registers and unregisters this tool's own entry, adopts a foreign command found in the slot, lists entries, and reads the dispatcher's per-entry failure record. It does not edit `settings.json`; the hook installer decides what a tool registers and edits that file under the shared lock. The value is a `Sendable` struct built from the Claude directory and the bundled dispatcher's location. It quotes the dispatcher path through [adhsdk.ingredient.foundation.process.shell-quoting](cookbook:9c81ac1c-ee1e-45b1-824c-deee1850037c), and [adhsdk.ingredient.foundation.claude-hooks.claude-hook-installer](cookbook:fc622208-1504-421f-8892-c5869820550c) is the type that holds it and edits `settings.json`. A Python implementation in claudehelpers (`external/claudehelpers/scripts/statuslinedispatcher/`) is the reference peer; it shares the conformance cases in `external/claudehelpers/tests/fixtures/statusline_conformance.json`.

## Behavioral Requirements

### Layout

- **directory-layout**: The dispatcher directory MUST be `claudehelpers/statusline` under the Claude directory, with the dispatcher at `dispatch.sh`, entries under `renderers/` and `taps/`, and failure records under `errors/`.
- **dispatcher-command**: `dispatcherCommand` MUST be `sh ` plus the dispatcher path (shell-quoted only when needed, matching Python's `shlex.quote`) plus ` # claudehelpers-statusline`, byte for byte the string claudehelpers' Python implementation writes, so the two never fight over the slot. For a dispatcher at `/Users/me/.claude/claudehelpers/statusline/dispatch.sh` the string is `sh /Users/me/.claude/claudehelpers/statusline/dispatch.sh # claudehelpers-statusline`.
- **settings-lock-name**: The shared lock name MUST be `.settings.lock`, the lock every `settings.json` editor that follows the contract holds across its read-modify-write.

### Recognising commands and names

- **dispatcher-command-shape**: `isDispatcherCommand(_:)` MUST be true for a trimmed command that starts with `sh `, ends with ` # claudehelpers-statusline` and has a non-empty path between, whichever directory it runs from, and false for a command that only mentions the marker elsewhere (such a command is some tool's own).
- **adopted-name**: `isAdoptedName(_:)` MUST be true for `adopted` and for `adopted-` followed by one or more ASCII digits, and false for any other name, including one that merely starts with the word (`adoptedtheme`) and one with an empty or non-numeric suffix.
- **valid-name**: `isValidName(_:)` MUST accept only a non-empty name whose first character is an ASCII letter or digit and whose every character is an ASCII letter, digit, `.`, `_` or `-`.
- **dispatcher-version**: `dispatcherVersion(_:)` MUST return the integer on the first line of the form `# claudehelpers-statusline-dispatch <N>` whose remainder, after trimming spaces, is one or more ASCII digits, MUST skip a line with a non-numeric or empty remainder and keep looking, and MUST return nil when no line qualifies.

### Installing the dispatcher

- **install-writes-newer**: `installDispatcher()` MUST write the bundled dispatcher to `dispatch.sh` with mode `0755` when none is installed or the installed version is lower than the bundled version, and MUST report the installed and offered versions and that it wrote.
- **install-never-downgrades**: `installDispatcher()` MUST NOT write when the installed version is the same or newer, because a newer copy came from a newer tool that relies on it.
- **install-replaces-unversioned**: An installed copy with no version line MUST read as no installed version and be replaced.
- **install-missing-bundle**: When the bundled dispatcher is unreadable, `installDispatcher()` MUST return without writing and with no offered version if a versioned copy is installed, and MUST throw `dispatcherMissing` carrying the bundled path when none is.
- **install-unversioned-bundle**: When the bundled dispatcher has no version line, `installDispatcher()` MUST return without writing if a versioned copy is installed, and MUST throw `dispatcherUnversioned` carrying the bundled path when none is.

### Entries

- **entry-content**: An entry file MUST hold exactly its command followed by one newline, and `entries()` and `entry(named:)` MUST return the command with surrounding whitespace trimmed.
- **register-replaces**: `register(_:name:command:)` MUST write the entry under the requested kind, remove the same name from the other kind, and return true when it changed any file and false when the entry already held exactly that command and nothing was removed.
- **register-name-precondition**: `register` MUST fail a precondition on an invalid name.
- **unregister-both**: `unregister(_:)` MUST remove the name from both kinds and delete its recorded error, and MUST return true only when an entry was present. It does not validate the name, so callers pass only names they own or names read from `entries()` (see **own-name-only**).
- **entries-listing**: `entries()` MUST list `renderers` before `taps`, each in name order, and MUST skip names that are not valid and files that cannot be read as text.
- **entry-utf8**: An entry file that is not valid UTF-8 MUST read as absent, so `entries()` skips it and `entry(named:)` returns nil.
- **settings-lock-held**: Callers MUST hold the shared `.settings.lock` across any sequence that reads the slot and writes entries; the type takes no lock itself, and each write is atomic so a reader never sees a half-written entry.
- **own-name-only**: `register` and `unregister` MUST be called only with the calling tool's own name, or a name read from `entries()`; the one removal of another entry is **adopt-replaces-earlier**'s removal of earlier `adopted*` renderers.
- **entry-lookup**: `entry(named:)` MUST return nil for an invalid name and otherwise the first match, checking `renderers` before `taps`.

### Adoption

- **adopt-keeps-command**: `adopt(_:)` MUST keep a command found in the slot as a renderer under the first free name of `adopted`, `adopted-2`, `adopted-3` and so on, free meaning absent from both kinds, and MUST return the name used.
- **adopt-noop**: `adopt(_:)` MUST return nil and write nothing when the trimmed command is empty or when some entry of either kind already runs exactly that command.
- **adopt-replaces-earlier**: Before writing, `adopt(_:)` MUST remove every earlier renderer with an adopted name, because the slot holds one command and the one found there replaced whatever was adopted before, so no line the person replaced comes back.
- **adopt-spares-taps**: `adopt(_:)` MUST NOT remove a tap, even one with an adopted name.

### Failure record

- **last-error**: `lastError(of:)` MUST return the trimmed text of `errors/<name>`, and nil when the name is invalid, the file is missing or unreadable, or the trimmed text is empty.
- **error-record-meaning**: This is a note on the dispatcher's contract, not behavior of this type: the dispatcher writes `errors/<name>` on a non-zero exit, a timeout or a failure to run, and deletes it when the entry next succeeds, so a record means "the entry is failing now and is missing from the line". This type only reads the record through **last-error**.
- **dispatcher-contract**: The dispatcher MUST run every renderer in name order and show its output; this type only supplies the files it reads and does not run them.

### Storage

- **owner-only-tree**: The tree MUST be owner-only because an adopted command may carry a token: directories `0700`, entries `0600`, each file created at its final mode before it becomes visible, through an atomic write. The one exception is the dispatcher `dispatch.sh`, which **install-writes-newer** writes at `0755` because it holds no secret and must be executable.
- **write-creates-parents**: Every write MUST create the entry's directory with intermediate directories and mode `0700` first.
- **write-failure-propagates**: A failed write or removal inside `installDispatcher`, `register`, `unregister` or `adopt` MUST throw to the caller.

### Errors

- **error-descriptions**: `Failure.dispatcherMissing` MUST describe "The status-line dispatcher this build carries is missing at <path>.", and `dispatcherUnversioned` MUST describe "The status-line dispatcher this build carries has no version line at <path>."
- **sendable-value**: The type MUST be a `Sendable` struct holding no mutable state; every call reads or writes the file system.
- **downward-dependencies**: The type MUST depend on nothing above `ShellQuoting` and `AtomicFile`.

## Appearance

Not applicable — this is a file-registration helper, not a visual component.

## States

Not applicable — this is a file-registration helper, not a visual component.

## Accessibility

Not applicable — this is a file-registration helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-status-line-001 | install-writes-newer | No installed copy, a versioned bundled copy; `testInstallWritesAnExecutableDispatcher` | `dispatch.sh` written with an executable mode and `wrote` true |
| claude-status-line-002 | install-never-downgrades, install-writes-newer | Installed version higher, then lower; `testInstallUpgradesButNeverDowngrades` | Higher installed copy kept; lower one replaced |
| claude-status-line-003 | install-replaces-unversioned | Installed copy without a version line; `testAnUnversionedInstalledDispatcherIsReplaced` | Replaced by the bundled copy |
| claude-status-line-004 | install-missing-bundle | Bundle absent with and without an installed copy; `testAMissingBundledDispatcherThrowsOnlyWhenNoneIsInstalled` | `dispatcherMissing` thrown only when none is installed |
| claude-status-line-005 | install-unversioned-bundle | Bundle without a version line; `testAnUnversionedBundledDispatcherThrowsOnlyWhenNoneIsInstalled` | `dispatcherUnversioned` thrown only when none is installed |
| claude-status-line-006 | dispatcher-command | Dispatcher path under a temp directory; `testTheDispatcherCommandMatchesClaudeHelpers` | Equals the string claudehelpers' Python writes for the same path |
| claude-status-line-007 | register-replaces, unregister-both | Register as renderer, re-register as tap, unregister; `testRegisterSwitchesKindsAndUnregisterClearsTheError` | One file at a time; unregister removes the entry and its error record |
| claude-status-line-008 | register-replaces | Register the same command twice; `testRegisterSaysWhetherItChangedAnything` | First call true, second false |
| claude-status-line-009 | valid-name, entries-listing | Folder holding an invalid name; `testEntriesSkipInvalidNames` | The invalid name is not listed |
| claude-status-line-010 | owner-only-tree | Adopted entry; `testAnAdoptedEntryIsOwnerOnly` | Entry `0600`, directories `0700` |
| claude-status-line-011 | adopt-spares-taps | A tap named like the adopted name; `testAdoptNeverRemovesATapOfTheSameName` | The tap stays and the adopted renderer takes the next free name |
| claude-status-line-012 | adopt-keeps-command, adopt-noop, adopt-replaces-earlier | The `adopt` cases in `external/claudehelpers/tests/fixtures/statusline_conformance.json` (each lists starting entries, the command, the expected name and the expected renderers); `testAdoptFollowsTheSharedCases` | Names, replacements and no-op results match the Python implementation's cases |
| claude-status-line-013 | dispatcher-command-shape, adopted-name, dispatcher-version | The `isDispatcherCommand`, `isAdoptedName`, `isValidName` and `shellQuote` cases in `external/claudehelpers/tests/fixtures/statusline_conformance.json`; `testConformanceWithClaudeHelpers` | Each predicate and the version reading give the same answers as the Python implementation |
| claude-status-line-014 | dispatcher-contract | Adopted and own renderers run by the real dispatcher; `testTheDispatcherRunsAdoptedAndOwnRenderersInNameOrder` | Output appears in name order (an integration vector: the dispatcher, not this type, orders the output) |
| claude-status-line-015 | last-error, error-record-meaning | No record, then a record with text, a whitespace-only record and an invalid name `../errors/stenographer`; `testLastErrorReadsTheDispatchersRecord` | nil with no record, the record's trimmed text, nil for the blank record, nil for the invalid name |
| claude-status-line-016 | register-name-precondition | `register(.renderers, name: "../x", command: "c")` | Fails a precondition; nothing is written |
| claude-status-line-017 | entry-content, entry-lookup | Register `c` as a tap, then call `entry(named:)`; also call `entry(named: "../x")` | The file holds `c` plus one newline; the lookup returns `c` trimmed, nil for the invalid name |
| claude-status-line-018 | directory-layout, settings-lock-name | A Claude directory `D` | Entries are under `D/claudehelpers/statusline/renderers` and `.../taps`, errors under `.../errors`, the dispatcher at `.../dispatch.sh`, and the lock name is `.settings.lock` |
| claude-status-line-019 | write-creates-parents | Register into a Claude directory that does not exist | The directories are created with mode `0700` and the entry is written |
| claude-status-line-020 | write-failure-propagates | Make the entry directory unwritable, then call `register` | The call throws |
| claude-status-line-021 | error-descriptions | `dispatcherMissing("/p")` and `dispatcherUnversioned("/p")` | Descriptions are "The status-line dispatcher this build carries is missing at /p." and "The status-line dispatcher this build carries has no version line at /p." |
| claude-status-line-022 | unregister-both | `unregister` on a name with no entry | Returns false |
## Edge Cases

- Null and empty input: an empty or whitespace-only command to `adopt(_:)` returns nil and writes nothing (MUST); an empty `errors/<name>` file reads as nil (MUST); an empty name is invalid for every operation that checks it (MUST).
- Malformed input: a version line with a non-numeric remainder is skipped and the scan continues (MUST); an entry file that is not valid UTF-8 reads as absent (**entry-utf8**).
- Boundary values: `adopted-10` and `adopted-2` are adopted names, `adopted-` and `adopted-x` are not (MUST); a command of just `sh  # claudehelpers-statusline` has no path and is not the dispatcher's (MUST).
- Concurrent access: this type takes no lock itself; callers hold the shared `.settings.lock` across any sequence that reads the slot and writes entries (**settings-lock-held**).
- Error states: a failed file operation throws; `lastError(of:)`, `entries()` and `entry(named:)` swallow read failures and return nil or an empty list (MUST).
- Offline or disconnected state: not applicable; the type touches only local files.
- Name collision across kinds: `register` removes a same-named entry of the other kind, so one name is never both renderer and tap (MUST).
- A tool never edits another's entry: `register` and `unregister` are called only with the calling tool's own name, except adoption's removal of earlier `adopted*` renderers (**own-name-only**).

## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `claudeDirectory` | `URL` | required | The directory holding `settings.json` (`~/.claude`) |
| `bundledDispatcher` | `URL` | required | The dispatcher this build carries (`Contents/Resources/dispatch.sh`) |

Contract constants, fixed byte for byte by **dispatcher-command**, **settings-lock-name** and **owner-only-tree** and not configurable:

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `marker` | `String` | `# claudehelpers-statusline` | Ends the dispatcher's `statusLine.command` |
| `settingsLockName` | `String` | `.settings.lock` | Shared lock file name beside `settings.json` |
| `adoptedName` | `String` | `adopted` | Base name for an adopted foreign command |
| directory modes | `mode_t` | `0700` | Every directory in the tree |
| entry modes | `mode_t` | `0600` | Every entry; the dispatcher is written `0755` |
## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: the only user-facing strings are the two `Failure` descriptions, hardcoded English in source with no localization table; callers show them.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: None of its own; an adopted entry holds a command copied from `settings.json`, which may carry a token.
- **Storage**: Owner-only, directories `0700` and entries `0600`, created at final mode before they are visible.
- **Transmission**: None; the type makes no network calls. The registered commands run later under the dispatcher.
- **Retention**: Entries stay until `unregister` or a later `adopt` replaces them; failure records stay until the entry next succeeds or is unregistered.

## Logging

Not applicable: this type uses no OSLog; failures are thrown to `ClaudeHookInstaller`, which logs them.

## Platform Notes

- **SwiftUI**: Not used; the type has no view layer, though a settings screen can show `lastError(of:)` beside the display toggle.
- **Compose**: Port with `java.nio.file` (`Files.createDirectories` with `PosixFilePermissions`, temp file then `Files.move` with `ATOMIC_MOVE`) and a plain data class for `Entry`.
- **React/Web**: Node `fs` with `mode` options and write-file-atomic; browsers cannot reach this directory.
- **AppKit / UIKit**: `Core/ClaudeHooks/ClaudeStatusLine.swift`, an internal (not `public`) struct that `ClaudeHookInstaller` holds, using `FileManager`, `CharacterSet` for name validation and `AtomicFile.write` for mode-at-creation writes; the command is quoted by `Core/Process/ShellQuoting.swift`. No UI framework is involved, so the same code serves both.
- **WinUI 3**: Use `System.IO` (`Directory.CreateDirectory`, `File.ReadAllTextAsync`, `File.Replace` over a temp file) and `Windows.Storage` for the Claude directory. POSIX modes do not exist, so `0700` and `0600` map to owner-only ACLs through `FileSecurity`; the `0755` dispatcher becomes an ordinary file. Quote commands with Windows argument rules, not POSIX single quotes, and note the dispatcher is a `sh` script, so the Windows Claude Code location may need a `.cmd` or PowerShell dispatcher instead. Methods return `Task` when called from a service and use `Task.Run` off the UI thread; `Entry` is a `record`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/ClaudeStatusLine.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One dispatcher owns the slot and each tool owns one file beside it.
**Rationale**: The slot holds a single command; per-tool files let a failing tool drop out of the line instead of blanking it and let no tool refuse or wrap another's command.
**Approved**: pending

**Decision**: The installed dispatcher is replaced only by a strictly higher version, and an unversioned copy counts as none.
**Rationale**: A newer copy came from a newer tool that relies on it; ordering needs a number, so an unversioned file can never be ordered and is overwritten.
**Approved**: pending

**Decision**: A bundle with a missing or unversioned dispatcher still works when a versioned one is installed.
**Rationale**: The installed copy is enough to run; failing would cost a user the status line over a packaging detail.
**Approved**: pending

**Decision**: A command found in the slot is adopted as a renderer, and earlier adopted renderers are removed.
**Rationale**: The slot holds one command, so the one found there replaced the previous; resurrecting the old would bring back a line the person replaced.
**Approved**: pending

**Decision**: The dispatcher command string is identical to the one claudehelpers' Python writes.
**Rationale**: Two writers of different strings would rewrite the slot back and forth.
**Approved**: pending

**Decision**: This type edits no `settings.json`.
**Rationale**: The lock and the merge with hooks belong to the installer; keeping the file side separate leaves the dependency pointing downward.
**Approved**: pending

**Decision**: The tree is owner-only and each file is created at its final mode.
**Rationale**: An adopted command may carry a token, so no window may exist where it is readable by others.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |

separation-of-concerns passes: the type is only the file side of the contract and leaves `settings.json`, locking and the register-or-tap decision to the installer. unit-test-coverage passes: `ClaudeStatusLineTests` covers installation, versioning, registration, adoption, the failure record, conformance with the Python implementation and a run of the real dispatcher. secure-storage passes: an adopted command may carry a token, so the tree is owner-only (`0700` directories, `0600` entries) and `testAnAdoptedEntryIsOwnerOnly` checks it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added depends-on, related and reference links, named the Python peer with a literal dispatcher command, split sendable-value, moved fixed constants out of Configuration, turned Edge Case rules into named requirements, added seven test vectors and a secure-storage check, and gave the shared conformance fixture path. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
