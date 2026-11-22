
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

