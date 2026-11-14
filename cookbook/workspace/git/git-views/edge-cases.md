
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

- **Files, awkward paths**: spaces, unicode and tabs are shown as they are; a path holding a newline stays on one row (single-line label, one line at most) and its tooltip holds the whole path.
- **Files, a path with no extension** (`Makefile`) or a dot file (`.gitignore`, whose extension is empty): the `doc` icon.
- **Files, the same path twice**: the id is the path, so the selection kept across a `files` change is the first row with that path.
- **Commit detail, a merge**: one parent link per parent; the list is the diff against the first parent.
- **Commit detail, a root commit**: no parents row; the list is the diff against the empty tree.
- **Commit detail, a stash**: a stash is a commit and shows as one, its list the diff against its first parent.
- **Commit detail, quick selection changes**: each `show(commit:)` bumps the detail's own counter before awaiting; a diff that returns for an older call is dropped, so arrow-keying down the history never leaves an earlier commit's files under a later header.
- **Commit detail, a binary file**: one row like any other; the diff view decides how to show it.
- **Commit detail, non-UTF-8 message**: shown as the model decoded it (lossily).
- **Working copy, unborn HEAD**: staged files list as added; selecting one reports `.staged`, which the client diffs against the empty tree.
- **Working copy, a conflicted file**: listed unstaged with `U` in purple; selecting it reports `.unstaged`.
- **Working copy, a file both staged and modified**: listed in both lists; each selection reports its own target.

- **Diff, a whitespace-only change with Ignore Whitespace on**: the diff lists no file; the viewer is empty, with no error.
- **Diff, a pure rename or mode change**: no hunks, so no rows.
- **Diff, huge or minified files**: over 1 MB, or a line over 10,000 UTF-16 units, the side is uncoloured; the viewer draws only visible rows.
- **Diff, non-UTF-8 content**: decoded as ISO Latin-1, so it is coloured rather than dropped; the diff's own lines are decoded by the model.
- **Diff, a lone `\r` line ending**: the highlighter splits on it but git does not, so colours after it can land a line off; text is never lost.
- **Diff, awkward paths**: the language comes from the path's file name and extension; spaces, unicode and newlines are passed through to the content source as they are.
- **Blame, uncommitted lines**: the all-zero id shows as `00000000` with the `Not Committed Yet` author; clicking it selects nothing.
- **File history, renames**: the history follows renames, but each commit's diff is asked for the current path, so a commit from before a rename shows no rows.

