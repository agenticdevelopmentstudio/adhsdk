
### Fields and defaults

- **required-fields**: The initializer MUST require `name`, `marker`, `hookBinaryPath` and `dropDirectory`, and MUST store each exactly as given.
- **default-hook-arguments**: `hookArguments` MUST default to `["hook", "--event"]`, to which the installer appends the event name.
- **default-status-line-arguments**: `statusLineArguments` MUST default to `["statusline"]`, to which the installer appends `--capture-only` when the display is off.
- **default-tap-only**: `statusLineTapOnly` MUST default to `false`; when `true` the owner always registers with the status-line dispatcher as a tap with `--capture-only`, never as a renderer.
- **default-settings-url**: `settingsURL` MUST default to `defaultSettingsURL`, the file `.claude/settings.json` under the current user's home directory.
- **default-own-lock-name**: When the `ownLockName` argument is nil the initializer MUST set it to a dot, the `name`, then `-hooks.lock`; the installer takes this lock after the shared `.settings.lock`.
- **explicit-own-lock-name**: A non-nil `ownLockName` argument MUST be stored unchanged. The stored property is a non-optional `String`; only the initializer parameter is optional.
- **default-status-line-entry-name**: When the `statusLineEntryName` argument is nil the initializer MUST set it to `name`; it is the owner's file name under the dispatcher's `renderers` or `taps` directory.
- **explicit-status-line-entry-name**: A non-nil `statusLineEntryName` argument MUST be stored unchanged. The stored property is a non-optional `String`.
- **default-bundled-dispatcher**: `bundledDispatcher` MUST default to nil, which `resolvedBundledDispatcher` reads as "derive it from the helper path".
- **default-hooked-events**: `hookedEvents` MUST default to `defaultHookedEvents`.
- **default-legacy**: `legacy` MUST default to `LegacyHookForms.none`.
- **no-input-validation**: The initializer MUST NOT validate or normalise any argument: an empty `name`, an empty `marker` or a relative `hookBinaryPath` is stored as given. The values it derives from `name` (lock file name, marker file names, drop-directory variable) are formed by plain concatenation. Callers SHOULD pass a short `name` of letters, digits and hyphens; nothing enforces it.
- **mutable-fields**: Every stored property MUST be a `var`, so a caller MAY change a field after construction; the value is copied on assignment.
- **derived-fields-not-recomputed**: Changing `name` after construction MUST NOT change `ownLockName` or `statusLineEntryName`, which are fixed at initialization; a caller that renames a configuration SHOULD set both again.

### Derived values

- **default-hooked-events-list**: `defaultHookedEvents` MUST be every `HookEventType` case except those whose raw value is in `ClaudeHookInstaller.excludedEventTypes` (`WorktreeCreate`, `WorktreeRemove` and `StatusLine`), in `allCases` order.
- **explicit-hooked-events-kept**: A `hookedEvents` list the caller passes MUST be stored as given, including any excluded type; the installer filters excluded types again when it registers (`ClaudeHookInstaller.hookedEventTypes`), so this type does not.
- **default-settings-url-resolution**: `defaultSettingsURL` MUST be computed on each read from `FileManager.default.homeDirectoryForCurrentUser`, not cached.
- **bundled-helper-from-macos-directory**: `bundledHelperPath(named:executable:)` MUST return `Contents/Helpers/<helperName>` of the bundle when the executable's directory is not named `Helpers` (a daemon or app under `Contents/MacOS`).
- **bundled-helper-from-helpers-directory**: `bundledHelperPath(named:executable:)` MUST return `<helperName>` inside the executable's own directory when that directory is named `Helpers` (the helper itself).
- **bundled-helper-resolves-symlinks**: `bundledHelperPath(named:executable:)` MUST resolve symlinks on the executable before inspecting its directory, so a link into a bundle names the bundle's real helper.
- **bundled-helper-default-executable**: `bundledHelperPath(named:executable:)` MUST default `executable` to `Bundle.main.executableURL`, force-unwrapped, so a process with no main executable URL traps; callers that cannot guarantee one MUST pass `executable`.
- **bundled-helper-no-parent-bundle**: `bundledHelperPath(named:executable:)` MUST NOT check that the executable sits in a bundle: for an executable whose directory is not named `Helpers` it MUST return `<executable directory>/../Helpers/<helperName>` as a path, so `/usr/local/bin/tool` yields `/usr/local/Helpers/<helperName>`, and it MUST NOT check that the result exists.
- **bundled-helper-absolute-path**: The returned path MUST be absolute (hooks run the helper by this path, so they follow the bundle wherever it lives).
- **resolved-dispatcher-explicit**: `resolvedBundledDispatcher` MUST return `bundledDispatcher` when it is non-nil.
- **resolved-dispatcher-derived**: When `bundledDispatcher` is nil, `resolvedBundledDispatcher` MUST return `Resources/dispatch.sh` in the directory two levels above `hookBinaryPath` (beside the helper's `Contents/Helpers`), as a file URL.

### Legacy forms

- **legacy-defaults**: `LegacyHookForms.init` MUST default `httpHookURLBase` and `captureScriptName` to nil, and `captureScriptSecondLinePrefixes`, `statusLineCommands` and `statusLineCommandSuffixes` to empty.
- **legacy-none**: `LegacyHookForms.none` MUST equal `LegacyHookForms()`, a value that recognises no retired form.
- **legacy-field-meaning**: `LegacyHookForms` MUST store its fields without interpreting them, and the installer MUST read them with these meanings: `httpHookURLBase` is the base of a retired `http` hook url (`http://127.0.0.1:<port>/hook`); `captureScriptName` is a retired capture script beside `settings.json`, deleted on install when it is the owner's; `captureScriptSecondLinePrefixes` are the exact starts of line 2 of each shipped capture script; `statusLineCommands` are earlier `statusLine` commands upgraded on install; `statusLineCommandSuffixes` are endings of an earlier renderer's command that count as the owner's own, matched with `hasSuffix` and never `contains`.

### Marker contract

- **marker-contract**: The `marker` MUST be the string the installer stamps as the first line of every `command` hook this configuration registers (`# {{app_name_lower}}-hook`), and SHOULD be a prefix of every earlier marker version so one `contains` finds every registration of the owner; this type does not check either property, the installer relies on it.
- **name-derived-files**: `name` MUST be the short owner identifier (for example `{{app_name_lower}}`) and the installer MUST name the marker files `.<name>-tracking-disabled` and `.<name>-status-line-off` beside `settings.json` and the status-line feed lock files from it. `HookDropWriter` MUST also derive the environment variable that overrides the drop directory from `name`, upper-cased with every character that is not an ASCII letter or digit replaced by `_`, followed by `_DROP_DIR`.

### Concurrency and side effects

- **value-semantics**: Both structs MUST be `Sendable` value types, so copies are independent and nothing in them is shared or mutated by this code.
- **no-side-effects**: Construction and the derived properties MUST NOT write a file, run a process or post a notification; `defaultSettingsURL` reads the home directory and `bundledHelperPath(named:executable:)` reads the file system to resolve symlinks.
- **equality**: `==` on `ClaudeHookConfiguration` and `LegacyHookForms` MUST compare every stored property, so two configurations differing only in `settingsURL` are not equal.

