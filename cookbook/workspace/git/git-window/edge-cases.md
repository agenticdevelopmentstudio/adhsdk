
- **Symlinked spelling**: `/tmp/r` and `/private/tmp/r` resolve to one key and one window.
- **Linked worktree**: its own top level, so its own window; the watcher watches its git directory and the common directory.
- **Submodule row**: opens the submodule's own window, keyed by its own top level.
- **Remembered root gone**: dropped at restore.
- **Remembered root no longer a repository**: dropped at restore, since it no longer resolves.
- **Detached HEAD**: subtitle `detached HEAD`.
- **Fast typing in search**: the history view serialises queries; the window only forwards text.
- **Quick selection changes**: generations drop stale stash and subtitle loads; the views drop their own.
- **Offline / disconnected state**: Not applicable: no network.
