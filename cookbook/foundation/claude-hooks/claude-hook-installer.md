---
id: fc622208-1504-421f-8892-c5869820550c
title: "Claude Hook Installer"
type: ingredient
version: 2.1.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-26
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Installs and removes one daemon's Claude Code hooks, status-line registration and router pointer in settings.json under a shared lock, beside other tools."
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
  - b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43
related: []
references: []
approved-by: ""
approved-date: ""
---

# Claude Hook Installer

## Overview

`ClaudeHookInstaller` is a `Sendable` class that edits Claude Code's `settings.json` for one daemon, driven by a `ClaudeHookConfiguration` ([adhsdk.ingredient.foundation.sessions.claude-hook-configuration](cookbook:9eb46f78-0ceb-455f-9584-b6b43ddf0871); name, marker, helper path, drop directory, settings URL, lock name, status-line entry name, hooked events and legacy forms). Each registration is a `command` hook that runs the configuration's helper (`<helper> hook --event <Event>`); the helper writes the payload as a drop file and exits 0, so no socket, port or running daemon is involved and a hook cannot fail because the daemon is down.

Registrations are identified by the configuration's marker, so several daemons coexist in one file and each installs, updates and removes only its own entries. The installer also registers the daemon with the shared status-line dispatcher (`ClaudeStatusLine`, [adhsdk.ingredient.foundation.claude-hooks.claude-status-line](cookbook:517adfce-44e7-404e-8a7b-b1e304da32e7)), keeps two marker files beside `settings.json` (tracking disabled, status-line display off), replaces every earlier form of its own registrations, and exposes a locked read-modify-write for the daemon's other settings keys.

The dispatcher command is the `statusLine.command` that `ClaudeStatusLine` writes: `python3 <quoted dispatch.py path> # claudehelpers-statusline`, where `dispatch.py` lives at `~/.claude/claudehelpers/statusline/dispatch.py`; an older install ran `sh <dispatch.sh path>`, which still counts as the dispatcher's. Shell quoting comes from [adhsdk.ingredient.foundation.process.shell-quoting](cookbook:9c81ac1c-ee1e-45b1-824c-deee1850037c). An older Python dispatcher ran as `python3 -m statusline.dispatcher`; the configuration's legacy forms recognise it so install can replace it.

An extension (`ClaudeHookInstaller+RouterPointer.swift`) manages the **router pointer**: `env.ANTHROPIC_BASE_URL` in `settings.json`, which sends Claude Code's API traffic through an account router. The router's base URL is an argument, `routerBaseURL`, defaulting to `StenographerIdentifiers.routerBaseURL` (`http://127.0.0.1:22848`, [adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43)), so whichever daemon hosts the router points Claude Code at its own port. The extension reads the pointer, turns it on or off, suspends it while the router's daemon is down and resumes it on the next start, and removes it on a full uninstall. Every write goes through `modifySettings(_:)`, so it shares the settings lock with hook installs and other tools, and a value that is not this router's is never overwritten or removed.

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
- **install-removes-legacy-dispatcher**: After a reconcile, install MUST delete the shell `dispatch.sh` an older install left only when the saved slot equals `dispatcherCommand` (it runs `dispatch.py`), and MUST leave it when the save failed or the slot is not the dispatcher's.
- **install-removes-capture-script**: After a successful reconcile, install MUST delete the retired capture script when it is this owner's, and MUST NOT delete it when the save failed.
- **install-keeps-router-pointer**: Install MUST NOT add, change or remove `env.ANTHROPIC_BASE_URL`; only the router-pointer operations touch it.

### Uninstall

- **uninstall-result**: `uninstallHooks()` MUST return true when it removed anything and false when nothing of this owner was present or an error was thrown, with the error logged.
- **uninstall-all-forms**: Uninstall MUST remove this owner's groups in every form (current, `http`, bash, retired) under every event type present in the file, including types not in the current hooked list, and MUST keep foreign groups.
- **uninstall-prunes-empty**: Uninstall MUST drop an event type whose group list becomes empty and the `hooks` key when no event type remains.
- **uninstall-status-line-release**: Uninstall MUST hand the `statusLine` slot back only when this owner's entry was registered: with no other entry left the slot is removed; with one adopted renderer left its command returns to the slot; with any other tool registered the dispatcher keeps the slot; an own earlier form in the slot is removed; a foreign command is left alone.
- **uninstall-entry-order**: Uninstall MUST delete this owner's status-line entries (its own and any adopted entry holding its own command) only after `settings.json` is saved, so a failed save never leaves the slot pointing at deleted entries.
- **uninstall-entry-failure**: A failure deleting a status-line entry MUST be logged and MUST NOT undo the saved hook removal.
- **uninstall-keeps-router-pointer**: `uninstallHooks()` (and `uninstallHooks(removingRouterPointer: false)`) MUST leave `env.ANTHROPIC_BASE_URL` and the suspension marker in place, because turning tracking off does not stop the router and Claude Code would otherwise silently stop going through it.

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
- **set-display-off-never-throws**: Disabling the display MUST NOT throw `helperNotExecutable`, `statusLineNotRegistered` or a status-line registration failure. It MAY still throw the lock errors (`lockOpenFailed`, `lockAcquireFailed`), a failure writing the marker file, and a read or JSON parse error or `invalidFormat` from `settings.json`.

### Router pointer

- **router-env-key**: `routerBaseURLEnvKey` MUST be `ANTHROPIC_BASE_URL`, read and written under the top-level `env` object of `settings.json`.
- **router-base-url-default**: Every router-pointer operation MUST take the router's base URL as `routerBaseURL`, defaulting to `StenographerIdentifiers.routerBaseURL` (`http://127.0.0.1:22848`).
- **router-pointer-states**: `RouterPointer` MUST have exactly three cases: `absent` (no `env.ANTHROPIC_BASE_URL`), `ours` (exactly `routerBaseURL`) and `other(String)` carrying a display form; it MUST be `Equatable` and `Sendable`.
- **router-classify-no-env**: `routerPointer(in:routerBaseURL:)` MUST return `absent` when `settings` has no `env` key.
- **router-classify-env-not-object**: `routerPointer(in:routerBaseURL:)` MUST return `other("env is not an object")` when `env` is present but is not a JSON object.
- **router-classify-no-key**: `routerPointer(in:routerBaseURL:)` MUST return `absent` when `env` is an object without `ANTHROPIC_BASE_URL`.
- **router-classify-ours**: `routerPointer(in:routerBaseURL:)` MUST return `ours` only when the value is a string equal to `routerBaseURL` character for character, with no trimming or URL normalisation.
- **router-classify-other**: Any other value, including a non-string value, MUST classify as `other` carrying `routerPointerDisplay(value)`.
- **router-display-shape**: `routerPointerDisplay(_:)` MUST return `<scheme>://<host>` followed by `:<port>` when the value has a port, with the scheme lowercased, after trimming leading and trailing whitespace and newlines.
- **router-display-drops-detail**: `routerPointerDisplay(_:)` MUST NOT include the value's path, query, fragment or userinfo, because a URL can carry credentials.
- **router-display-ipv6**: `routerPointerDisplay(_:)` MUST wrap a host containing `:` in square brackets when it does not already start with `[`.
- **router-display-custom**: `routerPointerDisplay(_:)` MUST return `custom value` for a non-string value, an unparseable string, or a string with an empty or missing scheme or host.
- **router-read-unlocked**: `routerPointer(routerBaseURL:)` MUST read `settings.json` without taking the settings lock and MUST return `absent` when the file is missing, empty, unreadable, not JSON or not a JSON object; it never throws.
- **router-suspended-marker**: `routerPointerSuspendedMarkerURL` MUST be `.<name>-router-pointer-suspended` beside `settings.json`, named after the configuration so two installers never share a suspension.
- **router-set-locked**: `setRouterPointer(_:routerBaseURL:)` MUST do its read, decision and write inside one `modifySettings(_:)` call, so it is serialised with hook installs and other tools holding the settings lock.
- **router-set-clears-suspension**: `setRouterPointer(_:routerBaseURL:)` MUST delete the suspension marker inside its `modifySettings(_:)` body on every call that acquires the lock and reads `settings.json`, whatever the decision, so the user's own choice replaces a suspension and nothing is put back later; this deletion happens before a conflict is thrown, so a refused enable also forgets the suspension.
- **router-set-marker-failure**: Deleting the suspension marker MUST treat a marker that does not exist as already deleted. When an existing marker cannot be deleted, `setRouterPointer(_:routerBaseURL:)` MUST throw that error out of its `modifySettings(_:)` body before deciding, so `settings.json` is not written and the pointer keeps its state, and a later `resumeRouterPointer` cannot put back a pointer the user just turned off without the user having been told. `uninstallHooks(removingRouterPointer: true, routerBaseURL:)` MUST NOT throw on it: it MUST log "Could not forget the router pointer suspension: <error>" at error level and still remove a pointer that is `ours`.
- **router-set-enable-absent**: Enabling when the pointer is `absent` MUST set `env.ANTHROPIC_BASE_URL` to `routerBaseURL`, creating `env` when missing, keep every other `env` key and top-level key, save, and return `ours`.
- **router-set-enable-ours**: Enabling when the pointer is already `ours` MUST write nothing and return `ours`.
- **router-set-enable-conflict**: Enabling when the pointer is `other(display)` MUST throw `RouterPointerError.routerPointerConflict(display)` and MUST leave `settings.json` unchanged; an `env` that is not an object counts as such a value.
- **router-set-disable-ours**: Disabling when the pointer is `ours` MUST remove `ANTHROPIC_BASE_URL` from `env`, remove `env` itself when that empties it, save, and return `absent`.
- **router-set-disable-noop**: Disabling when the pointer is `absent` or `other` MUST write nothing and return that state unchanged.
- **router-set-errors**: `setRouterPointer(_:routerBaseURL:)` MUST propagate the errors of `modifySettings(_:)` (`lockOpenFailed`, `lockAcquireFailed`, a read or JSON parse error, `invalidFormat`, and a save failure) to the caller; when the lock or the read fails, the body never runs and the suspension marker is not deleted.
- **router-set-logs**: `setRouterPointer(_:routerBaseURL:)` MUST log at info level only when it changed the file: "Pointed Claude Code at the account router" on enable, "Claude Code no longer points at the account router" on disable.
- **router-suspend-only-ours**: `suspendRouterPointer(routerBaseURL:)` MUST change nothing and return false unless the pointer is `ours`.
- **router-suspend-marker-first**: When the pointer is `ours`, suspend MUST write the empty suspension marker atomically before removing the pointer, then remove `ANTHROPIC_BASE_URL` (and an emptied `env`), log "Router pointer suspended while the daemon is down" at info level, and return true; a failed marker write MUST leave `settings.json` unchanged.
- **router-suspend-errors**: Suspend MUST NOT throw; any error MUST be logged at error level as "Could not suspend the router pointer: <error>" and MUST return false.
- **router-resume-no-marker**: `resumeRouterPointer(routerBaseURL:)` MUST return false without reading or writing `settings.json` or taking the lock when the suspension marker does not exist.
- **router-resume-restores**: With the marker present, resume MUST re-check the marker under the lock and restore `env.ANTHROPIC_BASE_URL` to `routerBaseURL` only when the pointer is `absent`, then log "Router pointer restored" at info level and return true.
- **router-resume-respects-other**: Resume MUST NOT restore when the pointer is `ours` or `other` (it was set to something else meanwhile) and MUST return false in that case.
- **router-resume-drops-marker**: After a successful `modifySettings(_:)` call, resume MUST delete the suspension marker whether or not it restored the pointer.
- **router-resume-errors**: Resume MUST NOT throw; on any error it MUST log "Could not restore the router pointer: <error>" at error level, keep the marker for the next start, and return false.
- **uninstall-removing-router-pointer**: `uninstallHooks(removingRouterPointer: true, routerBaseURL:)` MUST run `uninstallHooks()`, then delete the suspension marker, then remove `env.ANTHROPIC_BASE_URL` under the lock only when it is `ours`, keeping any other value.
- **uninstall-removing-router-pointer-result**: `uninstallHooks(removingRouterPointer: true, routerBaseURL:)` MUST return true when either the hooks removal or the pointer removal removed anything; when the pointer step throws it MUST log "Router pointer removal failed: <error>" and return the hooks result alone.
- **uninstall-removing-router-pointer-two-locks**: The hooks removal and the pointer removal MUST be two separate lock acquisitions, so another holder MAY write `settings.json` between them.

### Marker files and settings access

- **tracking-marker**: `trackingDisabledMarkerURL` MUST be `.<name>-tracking-disabled` beside `settings.json`; `setTrackingDisabled(_:)` MUST create the parent directory, write an empty marker atomically when disabling and none exists, and remove it when enabling and one exists.
- **status-line-off-marker**: `statusLineDisplayOffMarkerURL` MUST be `.<name>-status-line-off` beside `settings.json`.
- **modify-settings**: `modifySettings(_:)` MUST read `settings.json` (a missing or empty file reads as an empty dictionary), run the body on a copy, and save only when the result differs from what was read, all under the settings lock; a body that throws MUST write nothing and the error MUST propagate.
- **load-settings**: `loadSettings()` MUST create the parent directory, return an empty dictionary for a missing or zero-byte file, propagate `JSONSerialization`'s error when the content is not valid JSON, and throw `invalidFormat` when it is valid JSON but not a JSON object.
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
- **router-error-description**: `RouterPointerError.routerPointerConflict(display)` MUST describe itself as "ANTHROPIC_BASE_URL in ~/.claude/settings.json is already set (<display>), so it was left alone." The path in the message is fixed text, not the configuration's `settingsURL`.
- **router-error-equatable**: `RouterPointerError` MUST be `Equatable`, comparing the display payload.

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
| claude-hook-installer-014 | load-settings | Missing, empty and invalid-JSON files | `testLoadSettingsReturnsEmptyForMissingFile`, `testLoadSettingsReturnsEmptyForEmptyFile`, `testLoadSettingsThrowsForInvalidJSON`, `testInstallReturnsFailedForCorruptSettings` | Empty dictionary, empty dictionary, a thrown error (`JSONSerialization`'s, since the content is not valid JSON); install returns `failed` |
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
| claude-hook-installer-034 | router-env-key, router-classify-no-env, router-classify-no-key | `routerPointer(in:)` with `{}`, then with `{"env": {"FOO": "1"}}` | | `absent` both times; `routerBaseURLEnvKey` is `ANTHROPIC_BASE_URL` |
| claude-hook-installer-035 | router-classify-ours, router-base-url-default | `{"env": {"ANTHROPIC_BASE_URL": "http://127.0.0.1:22848"}}` with the default `routerBaseURL`; then `"http://127.0.0.1:22848/"` | | `ours`; then `other("http://127.0.0.1:22848")` because the trailing slash is not an exact match |
| claude-hook-installer-036 | router-classify-env-not-object | `{"env": "x"}` | | `other("env is not an object")` |
| claude-hook-installer-037 | router-display-shape, router-display-drops-detail | `routerPointerDisplay("  HTTPS://user:secret@proxy.example.com:8443/v1?k=t#f ")` | | `https://proxy.example.com:8443` |
| claude-hook-installer-038 | router-display-custom, router-classify-other | `routerPointerDisplay(42)`, `routerPointerDisplay("not a url")`, `routerPointerDisplay("")` | | `custom value` each time |
| claude-hook-installer-039 | router-display-ipv6 | A string whose parsed host is `::1`, scheme `http`, port 9000 | | `http://[::1]:9000` |
| claude-hook-installer-040 | router-read-unlocked | `settings.json` missing, then holding `[1,2]`, then holding `not json` | | `routerPointer()` returns `absent` each time and never throws |
| claude-hook-installer-041 | router-set-enable-absent, router-set-locked, router-set-logs | `{"env": {"FOO": "1"}, "model": "x"}`; `setRouterPointer(true)` | | Returns `ours`; file holds `env.FOO` `1`, `env.ANTHROPIC_BASE_URL` `http://127.0.0.1:22848` and `model` `x`; one info line "Pointed Claude Code at the account router" |
| claude-hook-installer-042 | router-set-enable-ours, router-set-disable-noop | Pointer already `ours`, `setRouterPointer(true)`; pointer `absent`, `setRouterPointer(false)` | | Returns `ours`, then `absent`; the file is not rewritten either time and nothing is logged |
| claude-hook-installer-043 | router-set-enable-conflict, router-error-description | `env.ANTHROPIC_BASE_URL` is `https://gateway.example.com/x`; `setRouterPointer(true)` | | Throws `routerPointerConflict("https://gateway.example.com")` described as "ANTHROPIC_BASE_URL in ~/.claude/settings.json is already set (https://gateway.example.com), so it was left alone."; file unchanged |
| claude-hook-installer-044 | router-set-disable-ours | `{"env": {"ANTHROPIC_BASE_URL": "http://127.0.0.1:22848"}}`; `setRouterPointer(false)` | | Returns `absent`; the file has no `env` key |
| claude-hook-installer-045 | router-set-clears-suspension | Suspension marker present, pointer `other`; `setRouterPointer(true)` | | Throws `routerPointerConflict`; the suspension marker no longer exists |
| claude-hook-installer-046 | router-suspend-only-ours, router-suspend-marker-first | Pointer `ours`; `suspendRouterPointer()`; then again | | First call returns true, the marker `.<name>-router-pointer-suspended` exists and `ANTHROPIC_BASE_URL` is gone; second call returns false and writes nothing |
| claude-hook-installer-047 | router-resume-no-marker | No suspension marker; `resumeRouterPointer()` | | Returns false; no lock file is opened and `settings.json` is not read |
| claude-hook-installer-048 | router-resume-restores, router-resume-drops-marker | Marker present, pointer `absent`; `resumeRouterPointer()` | | Returns true; `env.ANTHROPIC_BASE_URL` is `http://127.0.0.1:22848`; marker deleted |
| claude-hook-installer-049 | router-resume-respects-other, router-resume-drops-marker | Marker present, `env.ANTHROPIC_BASE_URL` set to `https://gateway.example.com`; `resumeRouterPointer()` | | Returns false; the value is unchanged; marker deleted |
| claude-hook-installer-050 | router-suspend-errors, router-resume-errors | Shared lock held past `lockTimeout`; call suspend, then resume with a marker present | | Each returns false without throwing and logs its error line; the resume marker stays |
| claude-hook-installer-051 | uninstall-removing-router-pointer, uninstall-removing-router-pointer-result | Hooks of this owner, pointer `ours`, marker present; `uninstallHooks(removingRouterPointer: true)` | | Returns true; hooks, pointer and marker are gone |
| claude-hook-installer-052 | uninstall-keeps-router-pointer, install-keeps-router-pointer | Pointer `ours` and marker present; run `installHooks()`, then `uninstallHooks(removingRouterPointer: false)` | | `env.ANTHROPIC_BASE_URL` and the marker are untouched by both |
| claude-hook-installer-053 | uninstall-removing-router-pointer | No hooks of this owner, `env.ANTHROPIC_BASE_URL` is another value; `uninstallHooks(removingRouterPointer: true)` | | Returns false; the other value stays |
| claude-hook-installer-054 | router-set-errors | `settings.json` holds `[1]`; `setRouterPointer(true)` | | Throws `invalidFormat`; file unchanged |
| claude-hook-installer-055 | router-set-marker-failure | Suspension marker that cannot be deleted, pointer `absent`; `setRouterPointer(true)` | `testEnableThrowsAndSavesNothingWhenTheMarkerCannotBeDeleted` | Throws; `settings.json` is unchanged and the marker still exists |
| claude-hook-installer-056 | router-set-marker-failure | Suspension marker that cannot be deleted, pointer `ours`; `setRouterPointer(false)` | `testDisableThrowsAndKeepsThePointerWhenTheMarkerCannotBeDeleted` | Throws; `env.ANTHROPIC_BASE_URL` is still the router's |
| claude-hook-installer-057 | router-set-marker-failure | No suspension marker, pointer `absent`; `setRouterPointer(true)` | `testAMissingMarkerIsNotAnError` | Returns `ours` without throwing |
| claude-hook-installer-058 | router-set-marker-failure, uninstall-removing-router-pointer | Suspension marker that cannot be deleted, pointer `ours`; `uninstallHooks(removingRouterPointer: true)` | `testUninstallStillRemovesThePointerWhenTheMarkerCannotBeDeleted` | Does not throw; logs "Could not forget the router pointer suspension"; `env.ANTHROPIC_BASE_URL` is removed |
| claude-hook-installer-059 | install-removes-legacy-dispatcher | A legacy `dispatch.sh` and a `sh <legacy> # claudehelpers-statusline` slot | `testInstallRemovesTheShellDispatcherOnceTheSlotRunsThePythonOne`, `testTheShellDispatcherStaysWhileTheSlotIsNotOurs` |

Vectors 034 to 054 are derived from `ClaudeHookInstaller+RouterPointer.swift`; no test in `Tests/AgenticDeveloperHubSDKCoreTests` exercises them, so they name no test. Vectors 055 to 058 are `RouterPointerMarkerFailureTests` (`Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/RouterPointerMarkerFailureTests.swift`), which makes the marker undeletable by giving it a read-only child directory.
## Edge Cases

- Null and empty input: a missing or empty `settings.json` reads as an empty dictionary (MUST); an empty `statusLine` slot is replaced with no adoption (MUST); an empty `hooks` map after removal is dropped from the file (MUST); an `env` emptied by removing the router pointer is dropped from the file (MUST).
- Malformed input: a `settings.json` that is not valid JSON or not a JSON object makes install return `failed` and uninstall return false, with no write (MUST); a non-array value under an event type is skipped by uninstall and kept by the legacy pass (MUST); the unlocked `routerPointer()` read reports such a file as `absent` while `setRouterPointer` throws for it (`invalidFormat` for valid JSON that is not an object, the parse error otherwise) (MUST).
- Router pointer values: an `env` that is not an object is `other("env is not an object")` and is never replaced (MUST); a non-string `ANTHROPIC_BASE_URL` is `other("custom value")` (MUST); a value differing from `routerBaseURL` only by a trailing slash or letter case is `other`, not `ours` (MUST).
- Boundary values: `lockTimeout` defaults to 5 seconds and the lock is polled every 50 ms; the capture-script check reads at most 4096 bytes (MUST).
- Concurrent access: two processes editing the file are serialised by the two `flock` locks taken in a fixed order, so two holders cannot deadlock; a holder that is stopped in a debugger makes others fail with `lockAcquireFailed` after the timeout instead of hanging (MUST). `resumeRouterPointer` checks the marker once outside the lock and again inside it, so a concurrent `setRouterPointer` that deleted the marker wins (MUST). `uninstallHooks(removingRouterPointer: true)` takes the lock twice, so another writer can run between the hooks removal and the pointer removal (MUST).
- Suspension across failures: a suspend whose save fails leaves the marker and the pointer, and the next resume finds the pointer `ours`, restores nothing and drops the marker (MUST); a resume whose lock or save fails keeps the marker for the next start (MUST).
- Error states: any thrown error in `installHooks()`, `uninstallHooks()`, `suspendRouterPointer` or `resumeRouterPointer` is logged and converted to `failed` or false, never thrown (MUST); `setStatusLineDisplay(_:)`, `setRouterPointer(_:routerBaseURL:)` and `modifySettings(_:)` throw to the caller (MUST). A suspension marker that exists but cannot be deleted makes `setRouterPointer(_:routerBaseURL:)` throw with `settings.json` unchanged, and makes `uninstallHooks(removingRouterPointer: true, routerBaseURL:)` log and carry on (MUST, `router-set-marker-failure`).
- Foreign content: a foreign hook sharing a matcher group with a stale hook of this owner survives the rewrite (MUST); a foreign command that merely embeds the marker or the legacy `statusline.dispatcher` name as a substring is adopted, not dropped (MUST); another tool's `ANTHROPIC_BASE_URL` survives every router-pointer operation (MUST).
- Offline or disconnected state: not applicable; the installer touches only local files and makes no network calls. Suspending the router pointer is how the caller keeps Claude Code working while the router's daemon is down, but the installer itself does not probe the port.
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
| `configuration.name` | `String` | required | Names the three marker files: `.<name>-tracking-disabled`, `.<name>-status-line-off`, `.<name>-router-pointer-suspended` |
| `configuration.ownLockName` | `String` | `.<name>-hooks.lock` | Second lock beside `settings.json` |
| `configuration.statusLineEntryName` | `String` | the configuration `name` | File name under the dispatcher's `renderers` or `taps` directory |
| `configuration.hookArguments` | `[String]` | `["hook", "--event"]` | Arguments after the helper in a hook command |
| `configuration.statusLineArguments` | `[String]` | `["statusline"]` | Arguments after the helper in the status-line command |
| `configuration.statusLineTapOnly` | `Bool` | `false` | Always register as a capture-only tap |
| `configuration.hookedEvents` | `[HookEventType]` | every case not excluded | Event types registered |
| `configuration.legacy` | `LegacyHookForms` | `.none` | Earlier forms to recognise and replace |
| `routerBaseURL` (per call) | `String` | `StenographerIdentifiers.routerBaseURL` (`http://127.0.0.1:22848`) | The router base URL the router-pointer operations write and compare against |
| `removingRouterPointer` (per call) | `Bool` | required on that overload | Whether `uninstallHooks(removingRouterPointer:)` also removes the router pointer and forgets a suspension |

## Deep Linking

Not applicable: this code defines no URL or deep link; the legacy `http` hook base it recognises is a retired form it removes, and the router base URL it writes is a setting for Claude Code, not a route it serves.

## Localization

Not applicable: the only user-facing strings are the `ClaudeHookInstallerError` and `RouterPointerError` descriptions and the literal `custom value` display form, all hardcoded English in source with no localization table; the callers show them.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag; the user's tracking, display and router choices are marker files and the `env` value, covered under Behavioral Requirements.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: None of its own; `settings.json` may hold tokens, an adopted status-line command can embed one, and a foreign `ANTHROPIC_BASE_URL` can carry credentials in its userinfo.
- **Storage**: `settings.json` keeps its mode (`0600` when new); status-line entries are written owner-only by `ClaudeStatusLine` (directories `0700`, entries `0600`); the marker files are empty.
- **Transmission**: None; the installer makes no network calls, and the hooks it registers write local drop files. The router pointer it writes makes Claude Code send its API traffic to `routerBaseURL`, a loopback address by default.
- **Retention**: Entries, markers and the router pointer stay until uninstall, a switch or a user action removes them.
- **Display redaction**: A router value that is not ours is only ever exposed as `scheme://host[:port]` or `custom value`, never with its path, query, fragment or userinfo, so a conflict message or `other` state cannot leak a credential.

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
| Router pointer set | info | `Pointed Claude Code at the account router` |
| Router pointer removed | info | `Claude Code no longer points at the account router` |
| Router pointer suspended | info | `Router pointer suspended while the daemon is down` |
| Suspend failed | error | `Could not suspend the router pointer: <error>` |
| Router pointer restored | info | `Router pointer restored` |
| Resume failed | error | `Could not restore the router pointer: <error>` |
| Router pointer removal failed | error | `Router pointer removal failed: <error>` |

Error text, paths and commands are logged with public privacy, so a command that embeds a secret would appear in the log; a port MUST log commands and paths with private privacy instead. The router-pointer lines log no URL value.

## Platform Notes

- **SwiftUI**: Not used; the installer has no view layer, though an app's settings view calls `setStatusLineDisplay(_:)`, `setTrackingDisabled(_:)` and `setRouterPointer(_:routerBaseURL:)`, and binds a toggle to `routerPointer()`.
- **Compose**: Port with `kotlinx.serialization.json` or Jackson for the JSON object, `java.nio.channels.FileChannel.tryLock` for the cross-process lock (it is advisory per process like `flock`), and a temp-file-then-`Files.move` with `ATOMIC_MOVE` for the save. Model `RouterPointer` as a sealed class with `Absent`, `Ours` and `Other(display)`, and build the display form with `java.net.URI` (`scheme`, `host`, `port`), dropping `userInfo`.
- **React/Web**: Node `fs` with a lock library such as `proper-lockfile`, `JSON.stringify` with a sorted-key replacer, and write-file-atomic; browsers cannot edit this file. `new URL(value)` gives `protocol`, `hostname` and `port` for the display form; it already brackets IPv6 hosts in `host`, so bracket only when using `hostname`. Model `RouterPointer` as a discriminated union.
- **AppKit / UIKit**: `Core/ClaudeHooks/ClaudeHookInstaller.swift` holds the hooks, status line, markers, lock and settings I/O, using `flock(2)` through Darwin, `JSONSerialization` (pretty printed, sorted keys, fragments allowed), `FileManager` and `AtomicFile`; `Core/ClaudeHooks/ClaudeHookInstaller+RouterPointer.swift` is an extension holding `RouterPointer`, `RouterPointerError` and the router-pointer operations, built on `modifySettings(_:)` and `URLComponents`. Configuration lives in `Core/Sessions/ClaudeHookConfiguration.swift`, the default router URL in `Core/Stenographer/StenographerIdentifiers.swift`, quoting in `Core/Process/ShellQuoting.swift`, and logging uses OSLog through `Loggable`. Dictionary comparison uses `NSDictionary.isEqual`, so numeric types compare by value.
- **WinUI 3**: Use `System.Text.Json` (`JsonNode` or `JsonObject`) with `JsonSerializerOptions` for indentation, and sort keys explicitly because it does not sort them. `flock` has no equivalent; use a named `Mutex` or `FileStream` opened with `FileShare.None` retried every 50 ms until a `CancellationToken` or `Stopwatch` deadline, in the same two-lock order. Save with `File.Replace` over a temp file; there is no POSIX mode, so the `0600` requirement maps to an owner-only ACL on the new file. Resolve the helper with `Windows.ApplicationModel.Package` paths, quote with an argument-escaping helper (cmd or PowerShell rules differ from POSIX single quotes), and replace the `exit 0` trailer with the shell's own always-zero line: `exit 0` for PowerShell and `exit /b 0` for cmd. Hook registration targets Claude Code's Windows settings file, `%USERPROFILE%\.claude\settings.json`, not `~/.claude/settings.json`. For the router pointer, read and write `env` as a `JsonObject`, model `RouterPointer` as an abstract record with `Absent`, `Ours` and `Other(string Display)` subtypes, build the display form with `Uri.TryCreate(value, UriKind.Absolute, out var uri)` and `uri.Scheme`, `uri.Host` and `uri.IsDefaultPort`/`uri.Port` (never `uri.UserInfo` or `uri.PathAndQuery`), and throw a custom `InvalidOperationException` subclass for the conflict. Run the blocking calls on a `Task.Run` thread, never the UI thread.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/ClaudeHookInstaller.swift` | confirmed (2.1.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/ClaudeHookInstaller+RouterPointer.swift` | confirmed (2.1.0) |

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

**Decision**: The router pointer is compared by exact string equality with `routerBaseURL`, and any other value, including a non-object `env`, is never overwritten or removed; enabling over it throws a conflict carrying only a redacted display form.
**Rationale**: `ANTHROPIC_BASE_URL` may belong to the user or another proxy, so only a value this router wrote is treated as its own; the display form drops userinfo and path because the value can carry credentials.
**Approved**: pending

**Decision**: Suspension is a marker file beside `settings.json`, written before the pointer is removed and deleted only after a resume's save, and any explicit `setRouterPointer` call forgets it.
**Rationale**: While the router's daemon is down Claude Code must reach Anthropic directly rather than fail every request; the write order means a failed save never loses the record of a suspension, and the user's own choice must not be undone by a later resume.
**Approved**: pending

**Decision**: Turning tracking off (`uninstallHooks()`) keeps the router pointer; only `uninstallHooks(removingRouterPointer: true)`, used when removing the router's owner, takes it out.
**Rationale**: The router does not depend on tracking, and removing the pointer with the hooks would make Claude Code silently stop going through the router.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | failed | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

separation-of-concerns is partial: one type also owns hook registration, status-line slot arbitration, three marker files, the cross-process settings lock with `modifySettings`, the router pointer and deleting the retired capture script, so the lock layer, the slot logic and the router pointer could each become their own ingredient; the router pointer is at least split into its own extension file and touches the file only through `modifySettings`. File-side status-line handling lives in `ClaudeStatusLine`, quoting in `ShellQuoting`, atomic writes in `AtomicFile`. unit-test-coverage is partial: `HookInstallerTests`, `HookInstallerBundleCommandTests` and `ClaudeHookInstallerCoexistenceTests` cover install, uninstall, legacy forms, the lock, the status-line slot and the capture script, but no test exercises the router-pointer extension. explicit-error-handling is partial: install, uninstall, suspend and resume log and convert errors to a result, and the others throw typed `ClaudeHookInstallerError` or `RouterPointerError` values, but a failed deletion of the suspension marker is discarded with no signal. idempotent-operations passes: a repeated install returns `alreadyInstalled` without writing, a repeated `setRouterPointer` with the same value writes nothing, and a second suspend or resume returns false. secure-storage passes: a new `settings.json` is created at `0600`, an existing mode is kept and the file is written atomically. secure-log-output fails: the status-line command and the capture-script path are logged with `privacy: .public`, and an adopted command can embed a token; the router-pointer lines log no URL. no-hardcoded-strings fails: the error descriptions and the `custom value` display form are English literals with no localization table.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.1.0 | 2026-11-26 | Mike Fullerton | Install removes the legacy shell dispatch.sh once the saved slot runs dispatch.py; the dispatcher command is python3 dispatch.py |
| 2.0.0 | 2026-11-21 | Mike Fullerton | Specified the router-pointer extension (RouterPointer states, display redaction, set/suspend/resume, uninstall removing the pointer, RouterPointerError), added the stenographer-identifiers dependency, twenty-one router vectors, a routerBaseURL option, three design decisions and an idempotent-operations check, marked unit-test-coverage partial, and dropped the Reference Implementations section. Resolved router-set-marker-failure: an undeletable suspension marker makes setRouterPointer throw with settings.json unchanged, and uninstall logs it and still removes the pointer; added vectors 055 to 058 from RouterPointerMarkerFailureTests. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added depends-on links and a status-line tag, merged the two rationale requirements into excluded-event-types, marked separation-of-concerns partial and secure-log-output failed, defined the dispatcher command, clarified install-result and disabling errors, split test names into their own vector column, added twelve vectors, dropped the test-fixture decision and gave concrete WinUI 3 paths. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
