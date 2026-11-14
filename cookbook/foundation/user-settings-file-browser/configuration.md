
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `file_browser.excluded_patterns` | list of strings | `[]` | `.gitignore`-style patterns, one per entry, matched against paths relative to each browser root. |
| `isSecure` | boolean | `false` | Not passed by the declaration; the generic setting type's default routes the key to the plain store. |
| `UserSettings.shared` | settings store | process-wide instance | The store the setting reads from and writes through; the injection point for tests and for a different backend. |
| `exclusions` (consumer parameter) | `UserSetting` of a list of strings | `UserSettings.fileBrowserExcludedPatterns` | A file browser view controller accepts any setting of this type, defaulting to this one. |

