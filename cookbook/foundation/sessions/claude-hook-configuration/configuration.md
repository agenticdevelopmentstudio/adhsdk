
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
| `ownLockName` | `String` (initializer argument `String?`) | `.<name>-hooks.lock` | Lock beside `settings.json`, taken after `.settings.lock` |
| `statusLineEntryName` | `String` (initializer argument `String?`) | `name` | File name under the dispatcher's `renderers` or `taps` directory |
| `bundledDispatcher` | `URL?` | nil | Dispatcher a bundle carries; nil derives `Resources/dispatch.sh` from the helper path |
| `hookedEvents` | `[HookEventType]` | `defaultHookedEvents` | Event types registered for passive observation |
| `legacy` | `LegacyHookForms` | `.none` | Earlier forms to recognise and replace |
| `LegacyHookForms.httpHookURLBase` | `String?` | nil | Base of the retired `http` hook url |
| `LegacyHookForms.captureScriptName` | `String?` | nil | Retired capture script name beside `settings.json` |
| `LegacyHookForms.captureScriptSecondLinePrefixes` | `[String]` | `[]` | Exact starts of line 2 of each shipped capture script |
| `LegacyHookForms.statusLineCommands` | `Set<String>` | `[]` | Earlier `statusLine` commands |
| `LegacyHookForms.statusLineCommandSuffixes` | `[String]` | `[]` | Endings that mark an earlier renderer's command as the owner's |

