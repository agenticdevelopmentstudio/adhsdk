
- **Null / empty input**: An unborn repository lists only the working copy (and its worktree).
- **Boundary values**: A branch with no upstream has ahead and behind 0 and so no badge.
- **Duplicate titles**: A local `main` and `origin/main` are both titled `main` in different sections; their row ids differ (the full ref name), so selection is unambiguous.
- **Awkward paths**: Submodule paths and worktree directories with spaces or unicode are shown as they are and joined to the root as path components, never as strings.
- **Concurrent access**: UI thread only.
- **Error states**: The sidebar shows whatever the data source last loaded; it has no error state of its own.
- **Offline / disconnected state**: Not applicable: no network.

- **History, empty**: an unborn repository has no commits; the list has no rows and asks for one page at most.
- **History, end reached**: a `loadMore` that adds nothing is not repeated until the count or the query changes.
- **History, ambiguous sha prefix**: the first (newest) loaded match is selected.
- **History, search text with regex characters**: plain text is passed to git as `--grep` (a regular expression, case-insensitive); `-S` is a literal string.
- **History, text starting with `-S`**: any text that starts with `-S` (case-sensitive) is a pickaxe search for the rest, as git's own `-S<x>`: `-Something` searches for `omething`; `-s x` is a message search.
- **History, typing while a search is in flight**: `fix` then `fix ` (or `sha:a` then `sha:ab` while a filter clears) parse to the query already in flight; the later call waits for it, then reloads and selects.
- **History, non-UTF-8 messages**: shown as the model decoded them (lossily), never dropped.

