---
id: fc622208-1504-421f-8892-c5869820550c
title: "Claude Hook Installer"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Installs and removes one daemon's Claude Code command hooks and status-line registration in settings.json under a shared lock, beside other tools' entries."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - status-line
  - settings
depends-on:
  - 9eb46f78-0ceb-455f-9584-b6b43ddf0871
  - 517adfce-44e7-404e-8a7b-b1e304da32e7
  - 9c81ac1c-ee1e-45b1-824c-deee1850037c
related: []
references: []
approved-by: ""
approved-date: ""
---

# Claude Hook Installer

## Overview

`ClaudeHookInstaller` is a `Sendable` class that edits Claude Code's `settings.json` for one daemon, driven by a `ClaudeHookConfiguration` ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871); name, marker, helper path, drop directory, settings URL, lock name, status-line entry name, hooked events and legacy forms). Each registration is a `command` hook that runs the configuration's helper (`<helper> hook --event <Event>`); the helper writes the payload as a drop file and exits 0, so no socket, port or running daemon is involved and a hook cannot fail because the daemon is down.

Registrations are identified by the configuration's marker, so several daemons coexist in one file and each installs, updates and removes only its own entries. The installer also registers the daemon with the shared status-line dispatcher (`ClaudeStatusLine`, [adhsdk.ingredient.foundation.claude-hooks.claude-status-line](cookbook:517adfce-44e7-404e-8a7b-b1e304da32e7)), keeps two marker files beside `settings.json` (tracking disabled, status-line display off), replaces every earlier form of its own registrations, and exposes a locked read-modify-write for the daemon's other settings keys.

The dispatcher command is the `statusLine.command` that `ClaudeStatusLine` writes: `sh <quoted dispatch.sh path> # claudehelpers-statusline`, where `dispatch.sh` lives at `~/.claude/claudehelpers/statusline/dispatch.sh`. Shell quoting comes from [adhsdk.ingredient.foundation.process.shell-quoting](cookbook:9c81ac1c-ee1e-45b1-824c-deee1850037c). An older Python dispatcher ran as `python3 -m statusline.dispatcher`; the configuration's legacy forms recognise it so install can replace it.
## Behavioral Requirements

### Event types

- **excluded-event-types**: The installer MUST NOT register a hook for any event type in `excludedEventTypes`, the union of `delegationEventTypes` (`WorktreeCreate`, `WorktreeRemove`) and `nonHookEventTypes` (`StatusLine`). The delegation types are excluded because registering any hook under them hands the action to the hook entirely, and a passive hook with no stdout makes the owning tool fail with "no successful output"; those operations stay observable through the `PreToolUse` and `PostToolUse` hooks. `StatusLine` is excluded because Claude Code does not deliver it as a hook and registering it triggers an "Unknown hook event" warning at every session start; the status-line dispatcher synthesizes it.
- **hooked-event-types**: `hookedEventTypes` MUST be the configuration's `hookedEvents` raw values with `excludedEventTypes` removed, in the configuration's order.

### Hook command

- **hook-command-shape**: `makeCommand(eventType:)` MUST render exactly three lines: the configuration's marker, then the shell-quoted helper path followed by the configuration's `hookArguments` and the shell-quoted event type, then `exit 0`.
- **hook-command-exit-zero**: The command MUST end with `exit 0` for every event type, so a helper that fails to start never surfaces as a hook error.
- **hook-command-absolute-helper**: The helper MUST be named by absolute path (shell-quoted only when needed, so a bundle path holding spaces survives) so it runs under the minimal PATH of a GUI-launched session.
- **hook-command-no-pid**: The command MUST NOT forward a parent pid; the helper finds the `claude` pid itself so the one-line command that `isCurrentHook` compares stays stable.
- **hook-registration-shape**: Each registered entry MUST be a matcher group holding one hook of `type` `command` with the rendered command, `async` true so it stays off Claude's critical path, and `timeout` 10.
- **current-hook-definition**: A hook MUST count as current for an event type only when its `type` is `command` and its `command` equals `makeCommand(eventType:)` exactly.

### Install

- **install-result**: `installHooks()` MUST return `installed` if and only if it wrote `settings.json`, `alreadyInstalled` when nothing needed to change, and `failed(message)` on any thrown error, with the error logged.
- **install-locked**: `installHooks()` MUST run its whole read-modify-write under the settings lock.
- **install-requires-helper**: When `helperIsExecutable` reports the helper is not runnable, install MUST return `failed` with a message naming the helper and its path and MUST leave `settings.json` and every registered hook untouched, because every hook would otherwise fail silently behind its `exit 0`.
- **helper-executable-default**: The default `helperIsExecutable` MUST be true only for a path that exists, is not a directory and is executable.
- **install-additive**: Install MUST add a registration for each hooked event type that has no current registration of this owner, and MUST leave an existing current registration unchanged, so a new event type is registered on the next install without a marker bump.
- **install-preserves-foreign**: Install MUST keep every hook, matcher group and top-level settings key that is not this owner's.
- **install-scrubs-excluded**: Install MUST remove this owner's hooks (current marker, legacy form or retired form) from every excluded event type, and MUST keep another tool's hook under those types.
- **install-replaces-legacy**: Install MUST remove each of this owner's hooks that is not the current rendering for its event (an `http` form, an earlier bash form, a retired capture-script form, or a form whose helper path has gone stale after a bundle move) so the additive pass re-registers it in the current form, and MUST keep a foreign hook sharing the matcher group.
- **install-saved-only-on-change**: Install MUST write `settings.json` only when it changed something, and report `installed` rather than `alreadyInstalled` when the only change was the status line or a scrub.
- **install-status-line-isolated**: A failure while registering the status line MUST be logged and MUST NOT stop hook registration or fail the install; it costs only the status line.
- **install-removes-capture-script**: After a successful reconcile, install MUST delete the retired capture script when it is this owner's, and MUST NOT delete it when the save failed.

### Uninstall

- **uninstall-result**: `uninstallHooks()` MUST return true when it removed anything and false when nothing of this owner was present or an error was thrown, with the error logged.
- **uninstall-all-forms**: Uninstall MUST remove this owner's groups in every form (current, `http`, bash, retired) under every event type present in the file, including types not in the current hooked list, and MUST keep foreign groups.
- **uninstall-prunes-empty**: Uninstall MUST drop an event type whose group list becomes empty and the `hooks` key when no event type remains.
- **uninstall-status-line-release**: Uninstall MUST hand the `statusLine` slot back only when this owner's entry was registered: with no other entry left the slot is removed; with one adopted renderer left its command returns to the slot; with any other tool registered the dispatcher keeps the slot; an own earlier form in the slot is removed; a foreign command is left alone.
- **uninstall-entry-order**: Uninstall MUST delete this owner's status-line entries (its own and any adopted entry holding its own command) only after `settings.json` is saved, so a failed save never leaves the slot pointing at deleted entries.
- **uninstall-entry-failure**: A failure deleting a status-line entry MUST be logged and MUST NOT undo the saved hook removal.

### Status line

- **status-line-command**: `statusLineCommand` MUST be the shell-quoted helper path followed by `statusLineArguments`, with ` --capture-only` appended when the display is not wanted.
- **display-wanted**: `isStatusLineDisplayWanted` MUST be false when the configuration is `statusLineTapOnly` or the display-off marker file exists, and true otherwise.
- **registration-kind**: Install MUST register this owner with the dispatcher as a renderer when the display is wanted and as a tap otherwise.
- **slot-takeover**: When the `statusLine` slot does not already hold the dispatcher command, install MUST point it at the dispatcher command with `type` `command`, and MUST return nil from the step (no change) when it already does.
- **slot-adopts-foreign**: A non-empty, non-dispatcher, non-own command found in the slot MUST be adopted as a dispatcher renderer so it keeps showing.
- **slot-replaces-own**: A command that is this owner's own earlier form MUST be replaced outright, and an `adopted` renderer that already holds one of this owner's own commands MUST be removed so the line is never drawn twice.
- **own-command-recognition**: A slot command MUST count as this owner's when it contains the marker, equals the current `statusLineCommand`, is a bundle-shaped command, is one of `legacy.statusLineCommands`, or ends with one of `legacy.statusLineCommandSuffixes`.
- **bundle-command-recognition**: `isBundleStatusLineCommand` MUST accept only a trimmed command that is an absolute, shell-quoting-round-trippable path ending in `/Contents/Helpers/` plus the helper's file name, then the status-line arguments, then optionally ` --capture-only`, and MUST reject a wrapper around such a command.
- **is-displayed**: `isStatusLineDisplayed` MUST be true only when the display is wanted, `settings.json` loads, the slot command equals the dispatcher command, the dispatcher file exists, and this owner is registered as a renderer whose command does not end with ` --capture-only`; any failure to load settings MUST read as false.
- **status-line-error**: `statusLineError` MUST return the dispatcher's recorded last failure for this owner's entry, or nil when none exists.
- **set-display-noop-tap-only**: `setStatusLineDisplay(_:)` MUST return without effect when the configuration is tap-only.
- **set-display-marker**: `setStatusLineDisplay(_:)` MUST create the display-off marker when disabling and remove it when enabling, and MUST do the marker change and the settings reconcile inside one settings lock.
- **set-display-registers**: When the helper is runnable and tracking is not disabled, `setStatusLineDisplay(_:)` MUST re-register the entry and take the slot if it is not the dispatcher's yet.
- **set-display-throws-on-enable**: When enabling and Claude Code still does not draw this owner's line afterward, `setStatusLineDisplay(true)` MUST throw the registration failure if one occurred, else `helperNotExecutable` when the helper is not runnable, else `statusLineNotRegistered` carrying the entry name and whether tracking is disabled.
- **set-display-off-never-throws**: Disabling the display MUST NOT throw `helperNotExecutable`, `statusLineNotRegistered` or a status-line registration failure. It MAY still throw the lock errors (`lockOpenFailed`, `lockAcquireFailed`), a failure writing the marker file and `invalidFormat` from an unreadable `settings.json`.

### Marker files and settings access

- **tracking-marker**: `trackingDisabledMarkerURL` MUST be `.<name>-tracking-disabled` beside `settings.json`; `setTrackingDisabled(_:)` MUST create the parent directory, write an empty marker atomically when disabling and none exists, and remove it when enabling and one exists.
- **status-line-off-marker**: `statusLineDisplayOffMarkerURL` MUST be `.<name>-status-line-off` beside `settings.json`.
- **modify-settings**: `modifySettings(_:)` MUST read `settings.json` (a missing or empty file reads as an empty dictionary), run the body on a copy, and save only when the result differs from what was read, all under the settings lock; a body that throws MUST write nothing and the error MUST propagate.
- **load-settings**: `loadSettings()` MUST create the parent directory, return an empty dictionary for a missing or zero-byte file, and throw `invalidFormat` when the content is not a JSON object.
- **save-settings**: `saveSettings(_:)` MUST encode with pretty printing and sorted keys, write atomically, keep the existing file's permission mode, use `0600` for a new file, and keep a symlinked `settings.json` a symlink.
- **installed-event-types**: `installedEventTypes(in:)` MUST return the event types holding a group of this owner in any form.

### Locking

- **lock-files**: Every locked operation MUST take an exclusive `flock` on the shared `.settings.lock` and then on the configuration's `ownLockName`, in that order, both beside `settings.json`, creating the parent directory and the lock files as needed and opening them read-only.
- **lock-timeout**: Acquisition MUST poll without blocking every 50 ms and throw `lockAcquireFailed` once `lockTimeout` seconds (default 5) pass, with a message naming the held path and the timeout rounded up to whole seconds. The deadline is computed once per operation, so the two locks share one timeout budget.
- **lock-release**: The lock descriptors MUST be closed when the operation ends by return, throw or crash.
- **lock-open-failure**: A lock file that cannot be opened MUST throw `lockOpenFailed` with the system error text, and a non-retryable `flock` error MUST throw `lockAcquireFailed`.

### Retired capture script

- **capture-script-ownership**: `removeLegacyCaptureScript()` MUST delete the file only when it opens without following a symlink, is a regular file, and within its first 4096 bytes either its first line contains the marker or its second line starts with one of `legacy.captureScriptSecondLinePrefixes`.
- **capture-script-safe-open**: The open MUST use no-follow and non-blocking flags and check the file type on the opened descriptor, so a symlink or FIFO is left alone and cannot block.
- **capture-script-failure**: A failure deleting the script MUST be logged and not thrown.

### Errors

- **error-descriptions**: `ClaudeHookInstallerError` MUST describe `invalidFormat` as "settings.json is not a valid JSON object", the lock errors with their system messages, `helperNotExecutable` as naming the helper's file name and path and saying the status line was not registered, and `statusLineNotRegistered` as either "Claude Code tracking is off" with an instruction to turn tracking on, or "No <Entry> status line is registered in ~/.claude/settings.json".

### Concurrency

- **sendable-blocking**: The class MUST be `Sendable` with immutable stored properties; every operation is synchronous and blocks the calling thread while it waits for the lock, so callers MUST NOT invoke it from a context that cannot block for up to `lockTimeout`.

## Appearance

Not applicable — this is a settings-file installer, not a visual component.

## States

Not applicable — this is a settings-file installer, not a visual component.

## Accessibility

Not applicable — this is a settings-file installer, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Test | Expected |
|----|-------------|-------|------|----------|
| claude-hook-installer-001 | install-result, install-additive | Empty settings | `testInstallIntoEmptySettings`, `testInstallIdempotent` | First install returns `installed`; a second returns `alreadyInstalled` |
| claude-hook-installer-002 | hook-command-shape, hook-command-exit-zero, hook-command-absolute-helper | Helper `/Applications/Stenographer.app/Contents/Helpers/steno`, event `Stop` | `testCommandIsThreeLines` | Lines are the marker, `/Applications/Stenographer.app/Contents/Helpers/steno hook --event Stop`, and `exit 0` |
| claude-hook-installer-003 | hook-command-exit-zero | Every `HookEventType` case | `testCommandAlwaysExitsZero` | Each rendered command contains `exit 0` |
| claude-hook-installer-004 | hook-registration-shape | After install | `testAllHooksAreAsyncWithTimeout` | Every hooked event has a `command` hook with `async` true and `timeout` 10 |
| claude-hook-installer-005 | excluded-event-types, install-scrubs-excluded | Settings holding this owner's `WorktreeCreate` hook | `testScrubsStaleDelegationHooksOnInstall`, `testScrubPreservesThirdPartyDelegationHooks` | Own hook removed from the excluded type, a third party's hook kept |
| claude-hook-installer-006 | install-requires-helper | `helperIsExecutable` returns false | `testAMissingStenoLeavesTheHooksAlone` | Result is `failed`, settings unchanged |
| claude-hook-installer-007 | install-replaces-legacy | Settings with an `http` or bash-form hook of this owner | `testLegacyHTTPHookIsReplacedByTheCaptureHook`, `testMovedBundleHookCommandIsRewritten`, `testAForeignHookSharingTheGroupSurvivesABundleMove` | Replaced by the current command; the foreign hook in the same group survives |
| claude-hook-installer-008 | slot-adopts-foreign | Slot holds another tool's command | `testInstallAdoptsAForeignStatusLine` | Command kept as an `adopted` renderer, slot holds the dispatcher command |
| claude-hook-installer-009 | bundle-command-recognition | Slot holds a wrapper around the bundle's command | `testAWrapperAroundOurStatusLineIsForeign` | Treated as foreign and adopted, not replaced |
| claude-hook-installer-010 | uninstall-status-line-release | Only an adopted renderer remains after uninstall | `testUninstallHandsTheAdoptedStatusLineBack` | The adopted command is written back into the slot |
| claude-hook-installer-011 | uninstall-entry-order | Save fails | `testUninstallDeletesNoEntryWhenTheSaveFails` | No status-line entry is deleted |
| claude-hook-installer-012 | lock-timeout | Shared lock held past the timeout | `testASettingsLockHeldPastTheTimeoutFailsInsteadOfHanging` | `lockAcquireFailed` after the timeout |
| claude-hook-installer-013 | lock-files | Lock held then released | `testAHeldSettingsLockDelaysTheInstallUntilItIsReleased`, `testTheSharedLockIsTheOneClaudeHelpersTakes` | Install waits for release then succeeds; the shared lock is `.settings.lock` |
| claude-hook-installer-014 | load-settings | Missing, empty and invalid-JSON files | `testLoadSettingsReturnsEmptyForMissingFile`, `testLoadSettingsReturnsEmptyForEmptyFile`, `testLoadSettingsThrowsForInvalidJSON`, `testInstallReturnsFailedForCorruptSettings` | Empty dictionary, empty dictionary, thrown `invalidFormat`; install returns `failed` |
| claude-hook-installer-015 | save-settings | Existing mode and symlink | `testSettingsFileModeIsPreserved`, `testANewSettingsFileIsOwnerOnly`, `testASymlinkedSettingsFileStaysALink` | Mode kept, new file `0600`, link kept |
| claude-hook-installer-016 | modify-settings | Body changes nothing, and body throws | `testModifySettingsWithoutAChangeWritesNothing`, `testModifySettingsThatThrowsWritesNothing` | Nothing written in either case |
| claude-hook-installer-017 | capture-script-ownership, capture-script-safe-open | Symlink, wrapper mentioning the name on line two, foreign file | `testInstallKeepsASymlinkByThatName`, `testInstallKeepsAWrapperThatOnlyMentionsTheNameOnLineTwo`, `testInstallKeepsAForeignFileByThatName` | Each is left in place |
| claude-hook-installer-018 | set-display-throws-on-enable | Tracking disabled, nothing registered, then enable the display | `testTurningTheDisplayOnWithNothingRegisteredThrows` | Throws `statusLineNotRegistered` whose description contains "tracking is off"; the `statusLine` slot stays unset |
| claude-hook-installer-019 | tracking-marker, status-line-off-marker | Config named `adkd` | `testTheMarkerFilesAreNamedAfterTheConfiguration` | Markers are `.adkd-tracking-disabled` and `.adkd-status-line-off` beside `settings.json` |
| claude-hook-installer-020 | install-preserves-foreign | Two configurations on one file | `testBothMarkerSetsCoexistAndEachUninstallRemovesOnlyItsOwn` | Each uninstall removes only its own entries |
| claude-hook-installer-021 | registration-kind | Tap-only configuration | `testATapOnlyConfigurationRegistersATapAndNeverARenderer` | Registered as a tap with ` --capture-only` |
| claude-hook-installer-022 | uninstall-prunes-empty | Settings whose only hooks are this owner's `Stop` group; run uninstall | | The `Stop` key is gone and so is `hooks` |
| claude-hook-installer-023 | uninstall-all-forms | This owner's current, `http`, bash and retired groups under an event type not in the hooked list, plus a foreign group; run uninstall | | Every group of this owner is removed and the foreign group stays |
| claude-hook-installer-024 | slot-replaces-own | The slot holds this owner's earlier command, and an `adopted` renderer holds one of this owner's own commands; run install | | The slot holds the dispatcher command, the earlier command is replaced without adoption, and the `adopted` renderer is removed |
| claude-hook-installer-025 | slot-takeover | The slot already holds the dispatcher command; run install | | The slot step reports no change and the slot is not rewritten |
| claude-hook-installer-026 | is-displayed | Display wanted, slot equal to the dispatcher command, dispatcher file present, this owner a renderer; then the same with ` --capture-only` on the renderer's command; then an unreadable `settings.json` | | `true`, then `false`, then `false` without throwing |
| claude-hook-installer-027 | hook-command-no-pid | `makeCommand(eventType:)` for every event type | | No rendered command carries a parent pid argument |
| claude-hook-installer-028 | install-status-line-isolated | The bundled dispatcher is missing and none is installed; run install | | Hooks are registered, `statusLine` is as it was, and install does not fail |
| claude-hook-installer-029 | install-removes-capture-script | A capture script that carries this owner's marker on its first line; run install, then repeat with a save that fails | | The script is deleted after the successful run and kept when the save fails |
| claude-hook-installer-030 | install-saved-only-on-change | Run install twice with nothing to change the second time | | The second run returns `alreadyInstalled` and leaves `settings.json` byte for byte unchanged |
| claude-hook-installer-031 | lock-release | Run an operation that returns, one that throws and then another operation at once | | Each locked operation ends with both lock descriptors closed, so the next operation takes the locks without waiting |
| claude-hook-installer-032 | lock-open-failure | The lock file's path is occupied by something that cannot be opened for reading, such as an unreadable file | | `lockOpenFailed` with the system error text |
| claude-hook-installer-033 | error-descriptions | `ClaudeHookInstallerError.invalidFormat` | | Describes "settings.json is not a valid JSON object" |
## Edge Cases

- Null and empty input: a missing or empty `settings.json` reads as an empty dictionary (MUST); an empty `statusLine` slot is replaced with no adoption (MUST); an empty `hooks` map after removal is dropped from the file (MUST).
- Malformed input: a `settings.json` that is not a JSON object makes install return `failed` and uninstall return false, with no write (MUST); a non-array value under an event type is skipped by uninstall and kept by the legacy pass (MUST).
- Boundary values: `lockTimeout` defaults to 5 seconds and the lock is polled every 50 ms; the capture-script check reads at most 4096 bytes (MUST).
- Concurrent access: two processes editing the file are serialised by the two `flock` locks taken in a fixed order, so two holders cannot deadlock; a holder that is stopped in a debugger makes others fail with `lockAcquireFailed` after the timeout instead of hanging (MUST).
- Error states: any thrown error in `installHooks()` or `uninstallHooks()` is logged and converted to `failed` or false, never thrown (MUST); `setStatusLineDisplay(_:)` and `modifySettings(_:)` throw to the caller (MUST).
- Foreign content: a foreign hook sharing a matcher group with a stale hook of this owner survives the rewrite (MUST); a foreign command that merely embeds the marker or the legacy `statusline.dispatcher` name as a substring is adopted, not dropped (MUST).
- Offline or disconnected state: not applicable; the installer touches only local files and makes no network calls.
- Status-line failure on install (no bundled dispatcher, unwritable `claudehelpers` directory, full disk): hooks are still installed and `statusLine` is left as it was (MUST).
- The `statusLineNotRegistered` message capitalizes the entry name, so an entry `adkd` reads "Adkd" (MUST, from `entry.capitalized`).
- `isStatusLineDisplayed` swallows a settings read error and reads false; it never throws (MUST).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` | `ClaudeHookConfiguration` | required | Name, marker, helper path, hook and status-line arguments, drop directory, settings URL, lock name, status-line entry name, bundled dispatcher, hooked events and legacy forms |
| `lockTimeout` | `TimeInterval` | `5` | Seconds `withSettingsLock` waits for a held lock |
| `helperIsExecutable` | `@Sendable (String) -> Bool` | `defaultHelperIsExecutable` | Injected check that the helper can be run; tests pass a closure to avoid a real bundle |
| `configuration.settingsURL` | `URL` | `~/.claude/settings.json` | File edited |
| `configuration.ownLockName` | `String` | `.<name>-hooks.lock` | Second lock beside `settings.json` |
| `configuration.statusLineEntryName` | `String` | the configuration `name` | File name under the dispatcher's `renderers` or `taps` directory |
| `configuration.hookArguments` | `[String]` | `["hook", "--event"]` | Arguments after the helper in a hook command |
| `configuration.statusLineArguments` | `[String]` | `["statusline"]` | Arguments after the helper in the status-line command |
| `configuration.statusLineTapOnly` | `Bool` | `false` | Always register as a capture-only tap |
| `configuration.hookedEvents` | `[HookEventType]` | every case not excluded | Event types registered |
| `configuration.legacy` | `LegacyHookForms` | `.none` | Earlier forms to recognise and replace |

## Deep Linking

Not applicable: this code defines no URL or deep link; the legacy `http` hook base it recognises is a retired form it removes, not one it serves.

## Localization

Not applicable: the only user-facing strings are the `ClaudeHookInstallerError` descriptions, which are hardcoded English in source, and the source has no localization table for them; the callers show them.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag; the user's tracking and display choices are marker files, covered under Behavioral Requirements.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: None of its own; `settings.json` may hold tokens, and an adopted status-line command can embed one.
- **Storage**: `settings.json` keeps its mode (`0600` when new); status-line entries are written owner-only by `ClaudeStatusLine` (directories `0700`, entries `0600`).
- **Transmission**: None; the installer makes no network calls, and the hooks it registers write local drop files.
- **Retention**: Entries and markers stay until uninstall, a switch or a user action removes them.

## Logging

Subsystem: the main bundle identifier | Category: `ClaudeHookInstaller` (`Loggable`)

| Event | Level | Message |
|-------|-------|---------|
| Install failed | error | `Install failed: <error>` |
| Helper not executable | error | `<helper> is not an executable file at <path>; hooks left as they are` |
| Excluded hooks scrubbed | info | `Removed stale hooks for excluded event types` |
| Legacy hooks removed | info | `Removed legacy hooks before upgrade` |
| Status line not registered | error | `Status line not registered, statusLine left as it was: <error>` |
| Slot taken | info | `Pointed statusLine at the shared dispatcher` |
| Hooks registered | info | `Installed hooks for <n> event type(s): <list>` |
| Nothing to do | info | `Hooks already installed` |
| Hooks removed | info | `Hooks removed` |
| Uninstall failed | error | `Uninstall failed: <error>` |
| Display toggled | info | `Status-line display turned on` and `Status-line display turned off; the capture tap stays` |
| Capture script removed or not | info or error | `Removed retired capture script at <path>` and `Could not remove capture script: <error>` |

Error text, paths and commands are logged with public privacy, so a command that embeds a secret would appear in the log; a port MUST log commands and paths with private privacy instead.

## Platform Notes

- **SwiftUI**: Not used; the installer has no view layer, though an app's settings view calls `setStatusLineDisplay(_:)` and `setTrackingDisabled(_:)`.
- **Compose**: Port with `kotlinx.serialization.json` or Jackson for the JSON object, `java.nio.channels.FileChannel.tryLock` for the cross-process lock (it is advisory per process like `flock`), and a temp-file-then-`Files.move` with `ATOMIC_MOVE` for the save.
- **React/Web**: Node `fs` with a lock library such as `proper-lockfile`, `JSON.stringify` with a sorted-key replacer, and write-file-atomic; browsers cannot edit this file.
- **AppKit / UIKit**: `Core/ClaudeHooks/ClaudeHookInstaller.swift`, using `flock(2)` through Darwin, `JSONSerialization` (pretty printed, sorted keys, fragments allowed), `FileManager` and `AtomicFile`; configuration lives in `Core/Sessions/ClaudeHookConfiguration.swift`, quoting in `Core/Process/ShellQuoting.swift`, and logging uses OSLog through `Loggable`. Dictionary comparison uses `NSDictionary.isEqual`, so numeric types compare by value.
- **WinUI 3**: Use `System.Text.Json` (`JsonNode` or `JsonObject`) with `JsonSerializerOptions` for indentation, and sort keys explicitly because it does not sort them. `flock` has no equivalent; use a named `Mutex` or `FileStream` opened with `FileShare.None` retried every 50 ms until a `CancellationToken` or `Stopwatch` deadline, in the same two-lock order. Save with `File.Replace` over a temp file; there is no POSIX mode, so the `0600` requirement maps to an owner-only ACL on the new file. Resolve the helper with `Windows.ApplicationModel.Package` paths, quote with an argument-escaping helper (cmd or PowerShell rules differ from POSIX single quotes), and replace the `exit 0` trailer with the shell's own always-zero line: `exit 0` for PowerShell and `exit /b 0` for cmd. Hook registration targets Claude Code's Windows settings file, `%USERPROFILE%\.claude\settings.json`, not `~/.claude/settings.json`. Run the blocking calls on a `Task.Run` thread, never the UI thread.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/ClaudeHookInstaller.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Hooks are `command` entries that run a helper which writes a drop file and always exits 0, rather than `http` hooks.
**Rationale**: An `http` hook that cannot connect is an error in every Claude session and a lost event; a drop file needs no running daemon and a stopped daemon ingests it on its next start.
**Approved**: pending

**Decision**: Delegation and non-hook event types are excluded and scrubbed on every install.
**Rationale**: Hooks under delegation types make owning tools fail, and hooks under `StatusLine` raise an unknown-event warning; earlier versions registered them, so installs actively remove them.
**Approved**: pending

**Decision**: Registrations are identified by a marker and compared against the exact current rendering, and anything else of this owner's is rewritten.
**Rationale**: Several daemons share one file, so each touches only its own entries; comparing the whole command also detects a moved bundle without a version bump, and additive registration needs no marker change for a new event type.
**Approved**: pending

**Decision**: The helper must be runnable before any hook is written, otherwise install leaves the file alone.
**Rationale**: A hook pointing at a missing helper fails silently behind `exit 0` and capture stops with no error anywhere.
**Approved**: pending

**Decision**: Two locks are taken in a fixed order, the shared `.settings.lock` first, and acquisition times out.
**Rationale**: The shared lock is the contract other tools follow, the own lock keeps older builds out, a fixed order prevents deadlock, and a bounded wait stops the daemon hanging on a stopped holder.
**Approved**: pending

**Decision**: Another tool's `statusLine` command is adopted as a renderer instead of replaced, and uninstall hands the slot back by rule.
**Rationale**: The slot holds one command; the dispatcher lets several tools share it, so no tool refuses or wraps another's command and a leaving tool never strands the slot.
**Approved**: pending

**Decision**: A status-line failure never fails the install, and the status line step runs after the legacy scrub and before hook registration.
**Rationale**: Losing the line is cheaper than losing event capture; turning the display on reports the reason by throwing.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | failed | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

separation-of-concerns is partial: one type also owns hook registration, status-line slot arbitration, two marker files, the cross-process settings lock with `modifySettings`, and deleting the retired capture script, so the lock layer and the slot logic could each become their own ingredient. File-side status-line handling lives in `ClaudeStatusLine`, quoting in `ShellQuoting`, atomic writes in `AtomicFile`, and this type decides what is registered and edits `settings.json`. unit-test-coverage passes: `HookInstallerTests`, `HookInstallerBundleCommandTests` and `ClaudeHookInstallerCoexistenceTests` cover install, uninstall, legacy forms, the lock, the status-line slot and the capture script. explicit-error-handling passes: install and uninstall log and convert errors to a result, the others throw typed `ClaudeHookInstallerError` values. secure-storage passes: a new `settings.json` is created at `0600`, an existing mode is kept and the file is written atomically. secure-log-output fails: the status-line command and the capture-script path are logged with `privacy: .public`, and an adopted command can embed a token. no-hardcoded-strings fails: the error descriptions are English literals with no localization table.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added depends-on links and a status-line tag, merged the two rationale requirements into excluded-event-types, marked separation-of-concerns partial and secure-log-output failed, defined the dispatcher command, clarified install-result and disabling errors, split test names into their own vector column, added twelve vectors, dropped the test-fixture decision and gave concrete WinUI 3 paths. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
