
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `commandRegistry` | `CommandRegistry` | none | Where the two commands register. |
| `resources` | `TextMateResources?` | none | The bundled TextMate directory (`Contents/Resources/TextMate`); nil shows code uncoloured. |
| `userGrammarsDirectory` | `URL` | none | User grammars, ahead of every other source (`~/.agenticdeveloperkitchen/Grammars` in the Kitchen). |
| `extensionGrammars` | `() -> GrammarSource?` | none | The extensions' grammars, read when the highlighter is built. |
| `fileTypeOverride` | `@Sendable (URL) -> String?` | none | The app's File Types mapping: the language name the user chose for the file's extension, mapped to a language id through the grammar registry. |
| `client` | `GitClient` | `.shared` | Every git call. |
| `openRoots` | `UserSetting<[String]>` | `UserSettings.openGitWindowRoots` (`open_git_window_roots`) | Where the open windows are remembered. |
