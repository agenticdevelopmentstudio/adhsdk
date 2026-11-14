
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| id | String | `UUID().uuidString` | Built-ins use fixed UUID strings; imported and custom themes get a fresh one |
| name | String | required | Display name |
| appearance | ThemeAppearance | required | `dark`, `light` or `auto` |
| isBuiltIn | Bool | `false` | Read-only and never deletable |
| isImported | Bool | `false` | Read-only but deletable |
| attribution | String? | `nil` | Free-form credit, preserved on export |
| foreground, background, cursor, selection | RGBAColor | required | Terminal palette |
| ansi | [RGBAColor] | required | 16 colors expected (`ansiColorCount`) |
| roleOverrides | [String: RGBAColor] | empty | Keyed by `ThemeRole.rawValue` |
| typography | ThemeTypography | `.system` | Fonts per `TextRole` plus a size scale |
| terminal | ThemeTerminalOptions? | `nil` | Terminal padding, font and caret overrides |
| project | ThemeProjectOptions? | `nil` | Project-window chrome overrides |

