
`LoadError` descriptions are English strings built in the source, `could not read <path>: <reason>` and `could not write <path>: <reason>`, with the underlying error's localized description as the reason. The test comment says the feature turns a thrown error into a status line, so the text can reach a user. The source passes them through no localization table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `could not read <path>: <reason>` | `LoadError.unreadable` description |
| (none; literal) | `could not write <path>: <reason>` | `LoadError.unwritable` description |

