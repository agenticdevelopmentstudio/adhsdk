---
id: 9eb46f78-0ceb-455f-9584-b6b43ddf0871
title: "Claude Hook Configuration"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Value type holding everything that makes one daemon's Claude Code hook registration its own: marker, helper, drop directory, lock, status-line entry and legacy forms."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - configuration
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Claude Hook Configuration

## Overview

`ClaudeHookConfiguration` is a `Sendable`, `Equatable` struct of plain values that describes one daemon's registration in Claude Code's `settings.json`: its short `name`, the `marker` stamped on its hook commands, the helper executable (`hookBinaryPath`) and the arguments hooks and the status-line command pass it, the `dropDirectory` the helper writes envelopes into, the `settingsURL` to edit, a second lock name, its file name under the status-line dispatcher, the dispatcher a bundle carries, the `hookedEvents` to register and the `legacy` forms it still recognises.

Claude Code runs every matching hook entry, so two daemons install their own configuration into the same `settings.json` and coexist: each recognises, updates and removes only the entries carrying its own marker. This type only carries the values and derives a few defaults and paths from them; `ClaudeHookInstaller` is the code that reads settings and acts on them. `LegacyHookForms`, declared in the same file, lists the retired registration forms an owner still replaces on install and removes on uninstall.

## Behavioral Requirements

### Fields and defaults

- **required-fields**: The initializer MUST require `name`, `marker`, `hookBinaryPath` and `dropDirectory`, and MUST store each exactly as given.
- **default-hook-arguments**: `hookArguments` MUST default to `["hook", "--event"]`, to which the installer appends the event name.
- **default-status-line-arguments**: `statusLineArguments` MUST default to `["statusline"]`, to which the installer appends `--capture-only` when the display is off.
- **default-tap-only**: `statusLineTapOnly` MUST default to `false`; when `true` the owner always registers with the status-line dispatcher as a tap with `--capture-only`, never as a renderer.
- **default-settings-url**: `settingsURL` MUST default to `defaultSettingsURL`, the file `.claude/settings.json` under the current user's home directory.
- **default-own-lock-name**: When `ownLockName` is nil the initializer MUST set it to a dot, the `name`, then `-hooks.lock`; the installer takes this lock after the shared `.settings.lock`.
- **explicit-own-lock-name**: A non-nil `ownLockName` MUST be stored unchanged.
- **default-status-line-entry-name**: When `statusLineEntryName` is nil the initializer MUST set it to `name`; it is the owner's file name under the dispatcher's `renderers` or `taps` directory.
- **explicit-status-line-entry-name**: A non-nil `statusLineEntryName` MUST be stored unchanged.
- **default-bundled-dispatcher**: `bundledDispatcher` MUST default to nil, which `resolvedBundledDispatcher` reads as "derive it from the helper path".
- **default-hooked-events**: `hookedEvents` MUST default to `defaultHookedEvents`.
- **default-legacy**: `legacy` MUST default to `LegacyHookForms.none`.
- **no-input-validation**: The initializer MUST NOT validate or normalise any argument: an empty `name`, an empty `marker` or a relative `hookBinaryPath` is stored as given. The values it derives from `name` (lock file name, marker file names, drop-directory variable) are formed by plain concatenation.
- **mutable-fields**: Every stored property is a `var`, so a caller MAY change a field after construction; the value is copied on assignment.

### Derived values

- **default-hooked-events-list**: `defaultHookedEvents` MUST be every `HookEventType` case except those whose raw value is in `ClaudeHookInstaller.excludedEventTypes` (`WorktreeCreate`, `WorktreeRemove` and `StatusLine`), in `allCases` order.
- **explicit-hooked-events-kept**: A `hookedEvents` list the caller passes MUST be stored as given, including any excluded type; the installer filters excluded types again when it registers (`ClaudeHookInstaller.hookedEventTypes`), so this type does not.
- **default-settings-url-resolution**: `defaultSettingsURL` MUST be computed on each read from `FileManager.default.homeDirectoryForCurrentUser`, not cached.
- **bundled-helper-from-macos-directory**: `bundledHelperPath(named:executable:)` MUST return `Contents/Helpers/<helperName>` of the bundle when the executable's directory is not named `Helpers` (a daemon or app under `Contents/MacOS`).
- **bundled-helper-from-helpers-directory**: `bundledHelperPath(named:executable:)` MUST return `<helperName>` inside the executable's own directory when that directory is named `Helpers` (the helper itself).
- **bundled-helper-resolves-symlinks**: `bundledHelperPath(named:executable:)` MUST resolve symlinks on the executable before inspecting its directory, so a link into a bundle names the bundle's real helper.
- **bundled-helper-default-executable**: `bundledHelperPath(named:executable:)` MUST default `executable` to `Bundle.main.executableURL`, force-unwrapped, so a process with no main executable URL traps; callers that cannot guarantee one pass `executable`.
- **bundled-helper-absolute-path**: The returned path MUST be absolute (hooks run the helper by this path, so they follow the bundle wherever it lives).
- **resolved-dispatcher-explicit**: `resolvedBundledDispatcher` MUST return `bundledDispatcher` when it is non-nil.
- **resolved-dispatcher-derived**: When `bundledDispatcher` is nil, `resolvedBundledDispatcher` MUST return `Resources/dispatch.sh` in the directory two levels above `hookBinaryPath` (beside the helper's `Contents/Helpers`), as a file URL.

### Legacy forms

- **legacy-defaults**: `LegacyHookForms.init` MUST default `httpHookURLBase` and `captureScriptName` to nil, and `captureScriptSecondLinePrefixes`, `statusLineCommands` and `statusLineCommandSuffixes` to empty.
- **legacy-none**: `LegacyHookForms.none` MUST equal `LegacyHookForms()`, a value that recognises no retired form.
- **legacy-field-meaning**: `httpHookURLBase` is the base of a retired `http` hook url (`http://127.0.0.1:<port>/hook`); `captureScriptName` is a retired capture script beside `settings.json`, deleted on install when it is the owner's; `captureScriptSecondLinePrefixes` are the exact starts of line 2 of each shipped capture script; `statusLineCommands` are earlier `statusLine` commands upgraded on install; `statusLineCommandSuffixes` are endings of an earlier renderer's command that count as the owner's own, matched with `hasSuffix` and never `contains`. This type stores these values and does not interpret them.

### Marker contract

- **marker-contract**: The `marker` MUST be the string the installer stamps as the first line of every `command` hook this configuration registers (`# stenographer-hook`), and SHOULD be a prefix of every earlier marker version so one `contains` finds every registration of the owner; this type does not check either property, the installer relies on it.
- **name-derived-files**: `name` is the short owner identifier (`stenographer`, `adkd`) and names the marker files `.<name>-tracking-disabled` and `.<name>-status-line-off` beside `settings.json` and the status-line feed lock files; the installer builds those names from it. `HookDropWriter` also derives the environment variable that overrides the drop directory from `name`, upper-cased with every character that is not an ASCII letter or digit replaced by `_`, followed by `_DROP_DIR`.

### Concurrency and side effects

- **value-semantics**: Both structs are `Sendable` value types; copies are independent and nothing in them is shared or mutated by this code.
- **no-side-effects**: Construction and the derived properties MUST NOT write a file, run a process or post a notification; `defaultSettingsURL` reads the home directory and `bundledHelperPath(named:executable:)` reads the file system to resolve symlinks.
- **equality**: `==` on `ClaudeHookConfiguration` and `LegacyHookForms` MUST compare every stored property, so two configurations differing only in `settingsURL` are not equal.

## Appearance

Not applicable — this is a configuration value type, not a visual component.

## States

Not applicable — this is a configuration value type, not a visual component.

## Accessibility

Not applicable — this is a configuration value type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-hook-configuration-001 | default-hook-arguments, default-status-line-arguments, default-tap-only, default-bundled-dispatcher, default-legacy | `ClaudeHookConfiguration(name: "stenographer", marker: "# stenographer-hook", hookBinaryPath: "/h/steno", dropDirectory: "~/.claude/stenographer-events")` | `hookArguments == ["hook","--event"]`, `statusLineArguments == ["statusline"]`, `statusLineTapOnly == false`, `bundledDispatcher == nil`, `legacy == LegacyHookForms.none` |
| claude-hook-configuration-002 | default-own-lock-name, default-status-line-entry-name | the same call as 001 | `ownLockName == ".stenographer-hooks.lock"`, `statusLineEntryName == "stenographer"` |
| claude-hook-configuration-003 | explicit-own-lock-name, explicit-status-line-entry-name, name-derived-files | `name: "adkd"`, `ownLockName: ".adkd-hooks.lock"`, `statusLineEntryName: "adkd"` (the `adkdFixture` in `StatusLineTestSupport`) | stored unchanged; the installer's marker files are `.adkd-tracking-disabled` and `.adkd-status-line-off` and the lock is `.adkd-hooks.lock` (test `testTheMarkerFilesAreNamedAfterTheConfiguration`) |
| claude-hook-configuration-004 | bundled-helper-from-macos-directory, bundled-helper-absolute-path | `bundledHelperPath(named: "steno", executable: /Applications/Stenographer.app/Contents/MacOS/stenographerd)` | `/Applications/Stenographer.app/Contents/Helpers/steno` (test `testBundledStenoPathFromDaemonExecutable`) |
| claude-hook-configuration-005 | bundled-helper-from-helpers-directory | `bundledHelperPath(named: "steno", executable: /Applications/Stenographer.app/Contents/Helpers/steno)` | `/Applications/Stenographer.app/Contents/Helpers/steno` (test `testBundledStenoPathFromTheCLIItself`) |
| claude-hook-configuration-006 | bundled-helper-resolves-symlinks | a symlink `stenographerd` to `real/Stenographer.app/Contents/MacOS/stenographerd` | the path under the real bundle's `Contents/Helpers/steno` (test `testASymlinkedExecutableResolvesToTheRealBundle`) |
| claude-hook-configuration-007 | resolved-dispatcher-derived | `hookBinaryPath: "/Applications/Stenographer.app/Contents/Helpers/steno"`, `bundledDispatcher: nil` | `resolvedBundledDispatcher` is the file URL `/Applications/Stenographer.app/Contents/Resources/dispatch.sh` |
| claude-hook-configuration-008 | resolved-dispatcher-explicit | `bundledDispatcher: file:///tmp/d.sh` | `resolvedBundledDispatcher == file:///tmp/d.sh` |
| claude-hook-configuration-009 | default-hooked-events-list | `ClaudeHookConfiguration.defaultHookedEvents` | 25 events (`HookEventType.allCases` is 28, test `caseCountIsPinned`), none of `.worktreeCreate`, `.worktreeRemove`, `.statusLine`; contains `.preToolUse` |
| claude-hook-configuration-010 | explicit-hooked-events-kept | `hookedEvents: [.stop, .statusLine]` | `hookedEvents == [.stop, .statusLine]`; the excluded type is removed later by the installer, not here |
| claude-hook-configuration-011 | legacy-defaults, legacy-none | `LegacyHookForms()` | all optionals nil, all collections empty, and `== LegacyHookForms.none` |
| claude-hook-configuration-012 | equality | two configurations built from the same arguments except `settingsURL` | `!=` |
| claude-hook-configuration-013 | no-input-validation | `name: ""` | accepted; `ownLockName == ".-hooks.lock"` |
| claude-hook-configuration-014 | default-settings-url | `defaultSettingsURL` | the file URL of `.claude/settings.json` under the home directory |
| claude-hook-configuration-015 | marker-contract | the Stenographer fixture (`marker: "# stenographer-hook"`) installed by the installer | the registered command's first line is `# stenographer-hook` (test `HookInstallerBundleCommandTests`, command `# stenographer-hook\n<helper> hook --event SessionStart\nexit 0`) |

## Edge Cases

- **Empty or odd name** (MUST): `name` is not validated, so an empty or space-containing `name` yields file and lock names built from it verbatim; callers MUST pass a short identifier of letters, digits and hyphens as the shipped owners do.
- **Executable with no parent bundle** (MUST): `bundledHelperPath(named:executable:)` for an executable such as `/usr/local/bin/tool` returns `/usr/local/Helpers/<helperName>`, because it only compares the directory name to `Helpers`; it does not check that the result exists.
- **Executable that is a missing path** (SHOULD): symlink resolution leaves a path that does not exist unchanged, so the result is computed from the path as written.
- **No main executable** (MUST): the default `executable` argument force-unwraps `Bundle.main.executableURL`; a process without one traps rather than returning an error.
- **Helper path with fewer than two parent directories** (SHOULD): `resolvedBundledDispatcher` strips two path components, so `/steno` yields `/Resources/dispatch.sh`; no error is raised.
- **Excluded type in `hookedEvents`** (MUST): kept as given; the installer drops it at registration.
- **Empty `hookedEvents`** (MUST): accepted as given; nothing is registered for passive observation.
- **Concurrent access** (MUST): each copy is an independent value and no code here mutates shared state; sharing one copy across threads is safe, and two threads editing one `var` copy is the caller's race.
- **Error states, offline or disconnected** (not applicable): this type does no I/O that can fail except the symlink read, which does not throw, and uses no network.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | `String` | required | Short owner identifier; names marker files, the default lock and entry name, and the drop-directory override variable |
| `marker` | `String` | required | First line of every command hook of this owner |
| `hookBinaryPath` | `String` | required | Absolute path of the helper hooks run |
| `hookArguments` | `[String]` | `["hook", "--event"]` | Arguments after the helper for a hook |
| `statusLineArguments` | `[String]` | `["statusline"]` | Arguments after the helper for the status-line command |
| `statusLineTapOnly` | `Bool` | `false` | Always register as a capture-only tap |
| `dropDirectory` | `String` | required | Drop directory in tilde form, for example `~/.claude/stenographer-events` |
| `settingsURL` | `URL` | `~/.claude/settings.json` | The settings file to edit |
| `ownLockName` | `String?` | `.<name>-hooks.lock` | Lock beside `settings.json`, taken after `.settings.lock` |
| `statusLineEntryName` | `String?` | `name` | File name under the dispatcher's `renderers` or `taps` directory |
| `bundledDispatcher` | `URL?` | nil | Dispatcher a bundle carries; nil derives `Resources/dispatch.sh` from the helper path |
| `hookedEvents` | `[HookEventType]` | `defaultHookedEvents` | Event types registered for passive observation |
| `legacy` | `LegacyHookForms` | `.none` | Earlier forms to recognise and replace |
| `LegacyHookForms.httpHookURLBase` | `String?` | nil | Base of the retired `http` hook url |
| `LegacyHookForms.captureScriptName` | `String?` | nil | Retired capture script name beside `settings.json` |
| `LegacyHookForms.captureScriptSecondLinePrefixes` | `[String]` | `[]` | Exact starts of line 2 of each shipped capture script |
| `LegacyHookForms.statusLineCommands` | `Set<String>` | `[]` | Earlier `statusLine` commands |
| `LegacyHookForms.statusLineCommandSuffixes` | `[String]` | `[]` | Endings that mark an earlier renderer's command as the owner's |

## Deep Linking

Not applicable: this type defines no URL scheme; the retired `http://127.0.0.1:<port>/hook` base it can carry is a form to remove, not one served.

## Localization

Not applicable: this type contains no user-facing string; the values are file names, commands and paths.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag; the status-line display and tracking choices are marker files the installer manages.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: this type holds file paths, a name and command strings, collects and stores nothing, and transmits nothing; `settingsURL` names a file under the user's home directory but no content is read.

## Logging

Not applicable: this code makes no log call; the installer that consumes it does the logging.

## Platform Notes

- **SwiftUI**: Not used; the type has no view layer, though an app's Settings view can read it to show the settings path or the hooked events.
- **Compose**: Port as a Kotlin `data class` with default parameter values for the optional fields and `Set<String>` for `statusLineCommands`; derive the home path from `System.getProperty("user.home")` and resolve links with `java.nio.file.Path.toRealPath()`.
- **React/Web**: Port as a TypeScript interface plus a factory that fills the defaults; use `os.homedir()` and `fs.realpathSync` in Node; a browser cannot edit this file.
- **AppKit / UIKit**: `Core/Sessions/ClaudeHookConfiguration.swift`, using `FileManager.default.homeDirectoryForCurrentUser`, `Bundle.main.executableURL` and `URL.resolvingSymlinksInPath()`; the bundle layout (`Contents/MacOS`, `Contents/Helpers`, `Contents/Resources`) is macOS-specific.
- **WinUI 3**: Use a C# `record` with `init` properties and default values for the optional fields, `Uri` or `string` for paths, and `HashSet<string>` for `statusLineCommands`. A record compares collections by reference, so supply a custom `Equals` or compare with `SequenceEqual` to match the source's value equality. Take the home path from `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)` and resolve links with `FileSystemInfo.ResolveLinkTarget(returnFinalTarget: true)`. There is no `Contents/Helpers` bundle layout: an MSIX or unpackaged app finds its helper beside `Package.Current.InstalledLocation` or `AppContext.BaseDirectory`, so `bundledHelperPath` becomes a lookup relative to the app's install directory, and the `dispatch.sh` dispatcher needs a Windows-runnable equivalent.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/ClaudeHookConfiguration.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One value type carries every per-owner difference, and several owners install into one `settings.json`.
**Rationale**: Claude Code runs every matching hook entry, so owners coexist when each recognises, updates and removes only entries carrying its own marker; a single configuration keeps those differences in one place.
**Approved**: pending

**Decision**: `defaultHookedEvents` excludes the delegation and non-hook types, but a caller-supplied `hookedEvents` is stored as given.
**Rationale**: The installer applies the exclusion again at registration, so the filter at this type is a default and not the only guard; the exclusion rule itself lives in `ClaudeHookInstaller`.
**Approved**: pending

**Decision**: The initializer does no validation and derives file names by concatenation.
**Rationale**: The shipped owners pass fixed literals, so a check would guard no real caller; the cost is that a bad `name` produces odd file names silently.
**Approved**: pending

**Decision**: The drop directory is stored in tilde form and the helper path is absolute.
**Rationale**: Hooks run the helper by absolute path so they follow a bundle wherever it lives; the tilde form is what hook commands carry and the writer expands it.
**Approved**: pending

**Decision**: `bundledHelperPath` force-unwraps `Bundle.main.executableURL` in its default argument.
**Rationale**: A running macOS process always has an executable URL; the force-unwrap makes the impossible case a trap, and tests pass `executable` explicitly.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: this type only carries values and derives paths, while reading and editing `settings.json` is `ClaudeHookInstaller`'s job, status-line files are `ClaudeStatusLine`'s and drop writing is `HookDropWriter`'s. unit-test-coverage is partial: `HookInstallerBundleCommandTests` and `ClaudeHookInstallerCoexistenceTests` cover `bundledHelperPath` (all three branches), `ownLockName` and the marker file names, and the installer tests exercise the fixtures, but no test asserts the initializer defaults, `defaultHookedEvents`, `resolvedBundledDispatcher` or `LegacyHookForms.none` directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
