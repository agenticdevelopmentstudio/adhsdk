
- **Empty or missing input**: an empty `TERM_PROGRAM`, as in a headless session with no terminal, MUST return nil.
- **Unknown terminal**: a `TERM_PROGRAM` no entry lists, such as Ghostty, MUST return nil; callers fall back, for example the conversation summary shows the raw value as the terminal's name.
- **Case and whitespace**: matching is exact, so `Iterm.app` or `iTerm.app ` returns nil; the caller passes the environment value as read.
- **Duplicate values across entries**: the first entry in catalog order wins; the default catalog has no duplicates.
- **Empty custom catalog**: `match` MUST return nil.
- **Terminal not running**: the lookup does not check for a running app; a caller that finds no running instance for the `bundleID` treats the terminal as not running (`BringTerminalToFrontStrategy` returns false).
- **Terminal embedded in another app**: VS Code's integrated terminal reports `vscode`, so a session there matches the VS Code entry and activation brings the editor forward, not a window or tab.
- **Concurrent access**: the catalog is an immutable `static let` of `Sendable` values, so concurrent reads are safe.
- **Error and offline states**: this code makes no I/O call and has no error path.

