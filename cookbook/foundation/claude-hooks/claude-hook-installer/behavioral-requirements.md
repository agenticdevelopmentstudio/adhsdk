
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

