
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

