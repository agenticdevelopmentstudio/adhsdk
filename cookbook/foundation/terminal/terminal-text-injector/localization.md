
The component has user-facing strings, all hardcoded English with no localization lookup. They are the `errorDescription` texts under the `error-descriptions` requirement and the `permissionDenied` message under `permission-payload`; the `scriptFailed` message embeds the text AppleScript supplies.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (unsupportedTerminal) | `Injecting text isn't supported for <name> yet — only iTerm2 and Terminal.app.` | Error description. |
| none (paneUnresolvable) | `Couldn't identify the session's terminal pane.` | Error description. |
| none (paneNotFound) | `The session's terminal pane wasn't found — it may have been closed.` | Error description. |
| none (permissionDenied) | `Automation permission is required to control <app name>. Grant it in System Settings ▸ Privacy & Security ▸ Automation.` | Carried message. |
| none (scriptFailed) | `Terminal automation failed: <message>` | Error description. |
| none (compile failure) | `could not compile the AppleScript` | `scriptFailed` message. |

