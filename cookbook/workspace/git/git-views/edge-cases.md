
- **Null / empty input**: An unborn repository lists only the working copy (and its worktree).
- **Boundary values**: A branch with no upstream has ahead and behind 0 and so no badge.
- **Duplicate titles**: A local `main` and `origin/main` are both titled `main` in different sections; their row ids differ (the full ref name), so selection is unambiguous.
- **Awkward paths**: Submodule paths and worktree directories with spaces or unicode are shown as they are and joined to the root as path components, never as strings.
- **Concurrent access**: UI thread only.
- **Error states**: The sidebar shows whatever the data source last loaded; it has no error state of its own.
- **Offline / disconnected state**: Not applicable: no network.

