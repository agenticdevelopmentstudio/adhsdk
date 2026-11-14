
### Refs sidebar

- **Unborn repository**: only `Workspace` is listed (no refs yet), plus `Worktrees` when the data source lists one.
- **Selected row removed**: after a reload that no longer contains the selected ref or stash, `Working Copy` is selected and the delegate is told.
- **Repository deleted**: the data source keeps its last values, so the sidebar keeps its last rows.

### History list

- **Unborn repository / empty history**: no rows; nothing throws, and no text stands in for the rows.
- **Paging**: further rows appear as the data source loads them; the selection is kept.
- **Selected commit removed**: after a reload that no longer contains the selected commit, nothing is selected and the delegate is told nil.
- **Repository deleted**: the data source keeps its last values, so the list keeps its last rows.

### Changed-files list

- **Empty**: no rows, and no text stands in for them.
- **Selected file removed**: after `files` no longer lists it, nothing is selected and the delegate is told nil.

### Commit detail

- **Nothing shown**: before the first `show(commit:)` and after `show(commit: nil)`, the header is empty and takes no height, and the list has no rows.
- **Loading**: the header shows the new commit while its list is empty until the diff arrives.
- **Diff failed**: the header stays, the list stays empty, and the error's description is shown over it until the next `show(commit:)`.
- **Repository deleted**: the shown header and list stay until the next `show(commit:)`.

### Working copy

- **Clean**: both lists are empty, headers `Staged (0)` and `Unstaged (0)`.
- **Unborn repository**: staged files are listed as added; nothing throws.
- **Selected file moved or gone**: after a reload that no longer lists it in its list, nothing is selected and the delegate is told nil.

