
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

