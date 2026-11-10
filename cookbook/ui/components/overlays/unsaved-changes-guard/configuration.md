
| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `when` | boolean | yes | — | Activates the guard; when true, navigation is blocked until approved or discarded |
| `onNavigate` | `(href: string) => void` | no | `window.location.assign` | Custom handler for confirmed anchor navigations; if not provided, uses full-page load |

