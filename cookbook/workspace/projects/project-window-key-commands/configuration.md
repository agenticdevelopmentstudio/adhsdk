
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `toggleBrowserID` | `String` | `projects.toggleBrowser` | Id of the browser command |
| `toggleActiveProjectsID` | `String` | `projects.toggleActiveProjects` | Id of the active-projects command |
| `sectionTitle` | `String` | `Project Window` | Title of the section |
| Browser shortcut | Shortcut | Command-0 | Default, user-rebindable |
| Active projects shortcut | Shortcut | Command-1 | Default, user-rebindable |
| Command window | injected via `KeyCommandRegistry.shared.commandWindow` | the window the keystroke was sent to, otherwise the key window, resolved to its owner window | The window whose controller is tested |

